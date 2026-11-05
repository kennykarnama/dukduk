FROM registry.suse.com/bci/gcc:14 AS duckdb-downloader

WORKDIR /src/

RUN curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors https://github.com/duckdb/duckdb/archive/refs/tags/v2.0.0.tar.gz | tar -xz

FROM registry.suse.com/bci/gcc:14 AS duckdb-builder

RUN zypper install -y libopenssl-3-devel libssh2-devel git python311 python311-devel bison flex perl ninja zip unzip kernel-devel \
    && ln -sf /usr/bin/python3.11 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.11 /usr/bin/python \
    && sed -i 's/#.*error "Unsupported combination of types for <tgmath.h>."/\/* tgmath bypass *\/ /' /usr/include/tgmath.h 2>/dev/null || true

# Install prebuilt modern CMake (takes 2 seconds instead of compiling from source for 25+ minutes)
RUN ARCH=$(uname -m) \
    && curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors "https://github.com/Kitware/CMake/releases/download/v3.30.5/cmake-3.30.5-linux-${ARCH}.tar.gz" | tar -xz --strip-components=1 -C /usr/local

WORKDIR /src/

RUN rm -rf /src/vcpkg \
    && git clone https://github.com/Microsoft/vcpkg.git /src/vcpkg \
    && git -C /src/vcpkg checkout 2026.06.24 \
    && if [ "$(git -C /src/vcpkg rev-parse --is-shallow-repository 2>/dev/null || echo false)" = "true" ]; then git -C /src/vcpkg fetch --unshallow || git -C /src/vcpkg fetch --all --tags --prune; fi \
    && sed -i 's/0cc8434dbdfb2e32dd98277ca37c221c1e720dfc2922d49c749e0c70ec0a5e23bf4e15378814e2f17b1dc65ec6ec93d23df5ec31b2f7ed995a4ae36f4522c24a/ecd69b6734be14c467f7db67dd88c0e57ebfad83ce3ddada131ff3e43ac964523e1083d7c7f3803033a9a76adbc32ad26dd2e3aca69884269000ca64130bde07/g' /src/vcpkg/ports/vcpkg-tool-meson/vcpkg-port-config.cmake 2>/dev/null || true \
    && /src/vcpkg/bootstrap-vcpkg.sh

ENV VCPKG_ROOT=/src/vcpkg

COPY --from=duckdb-downloader /src/duckdb-2.0.0/ /src/duckdb/

COPY ./extension_config_local.cmake duckdb/extension/extension_config_local.cmake

RUN cd duckdb \
    && if [ -d ../vcpkg/.git ] && [ "$(git -C ../vcpkg rev-parse --is-shallow-repository 2>/dev/null || echo false)" = "true" ]; then git -C ../vcpkg fetch --unshallow || git -C ../vcpkg fetch --all --tags --prune; fi \
    && CMAKE_POLICY_VERSION_MINIMUM=3.5 make extension_configuration \
    && CMAKE_POLICY_VERSION_MINIMUM=3.5 USE_MERGED_VCPKG_MANIFEST=1 VCPKG_TOOLCHAIN_PATH=../vcpkg/scripts/buildsystems/vcpkg.cmake EXTENSION_STATIC_BUILD=1 CMAKE_VARS="-DBUILD_UNITTESTS=OFF" make -j"$(nproc)" release \
    && mkdir -p /duckdblib \
    && find /src/duckdb/build/release -name "*.a" -exec cp {} /duckdblib/ \; \
    && cp -R /src/duckdb/build/release/extension /duckdblib/ \
    && ( \
         BUNDLE_TMP=/tmp/bundle_tmp; \
         mkdir -p "$BUNDLE_TMP"; \
         find /src/duckdb/build/release -name "*.a" ! -name "libduckdb_bundle.a" -exec cp {} "$BUNDLE_TMP/" \; 2>/dev/null || true; \
         cd "$BUNDLE_TMP" && for lib in *.a; do [ -f "$lib" ] || continue; obj_dir="${lib}.objs"; mkdir -p "$obj_dir"; (cd "$obj_dir" && ar -x "../$lib" 2>/dev/null || true); done; \
         find . -name "*.o" | xargs ar cr /duckdblib/libduckdb_bundle.a 2>/dev/null || true; \
         ranlib /duckdblib/libduckdb_bundle.a 2>/dev/null || true; \
         rm -rf "$BUNDLE_TMP"; \
       )

FROM registry.suse.com/bci/gcc:14 AS appbuilder

ARG TARGETARCH

RUN zypper install -y libopenssl-3-devel libssh2-devel curl libcurl-devel libexpat-devel zlib-devel git

RUN set -eux; \
		case "${TARGETARCH}" in \
			amd64|arm64) GO_ARCH="${TARGETARCH}" ;; \
			*) echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
		esac; \
		curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors "https://go.dev/dl/go1.24.5.linux-${GO_ARCH}.tar.gz" -o go.tar.gz; \
		tar -C /usr/local -xzf go.tar.gz; \
		rm go.tar.gz
ENV PATH="$PATH:/usr/local/go/bin"

WORKDIR /app/

COPY --from=duckdb-builder /duckdblib/ /app/duckdblib/

COPY ./appgo/ .

RUN cp /app/duckdblib/libnanoarrow_static.a /app/duckdblib/libnanoarrow.a 2>/dev/null || true; \
    cp /app/duckdblib/libnanoarrow_ipc_static.a /app/duckdblib/libnanoarrow_ipc.a 2>/dev/null || true; \
    CGO_ENABLED=1 CPPFLAGS="-DDUCKDB_STATIC_BUILD" CGO_LDFLAGS="-L./duckdblib -Wl,--start-group -lduckdb_bundle -lduckdb_static -lduckdb_loadable_extensions -lnanoarrow -lnanoarrow_ipc -lflatccrt -lminizip-ng -Wl,--end-group -lexpat -lcurl -lssh2 -lz -lssl -lcrypto -lstdc++ -lm -ldl -lpthread" go build -tags=duckdb_use_static_lib -o main ./duckdb-tester/

FROM registry.suse.com/bci/bci-base:15.7

COPY --from=appbuilder /app/main main-app
COPY --from=appbuilder /app/duckdblib/ /duckdblib/
