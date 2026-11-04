## dukduk

Duckdb things

Contain two things:

- Atmr OLAP experimentation
- appgo --> a testing application where we connect to postgres via duckdb
- Base dockerfile for binding between duckdb, GO and extensions (postgres and excel)

## Docker image why?

In BSIM, the external access was blocked. 
Our application (fincen-api) installs extension during pod startup. 

The resolution for this is to link all duckdb libraries need and the extensions to the go binary.

```
CGO_ENABLED=1 CPPFLAGS="-DDUCKDB_STATIC_BUILD" CGO_LDFLAGS="-L../ -lnanoarrow_extension -lflatccrt -lnanoarrow -lnanoarrow_ipc -lduckdb_fastpforlib -lduckdb_fmt -lduckdb_fsst -lduckdb_hyperloglog -lduckdb_mbedtls -lduckdb_miniz -lduckdb_pg_query -lduckdb_re2 -lduckdb_skiplistlib -lduckdb_utf8proc -lduckdb_yyjson -limdb -lduckdb_static -lduckdb_zstd -ljemalloc_extension -lparquet_extension -lstdc++ -lm -ldl -lcore_functions_extension" go build -tags=duckdb_use_static_lib ./duckdb-tester/main.go
```

The multi-platform build also emits static library bundles:

```bash
./scripts/build_multi_platform.sh
unzip artifacts/duckdb-static-libs-macos-arm64.zip
```

On Linux, the script emits both the existing SUSE-based `linux-amd64` artifacts and Ubuntu 22.04-compatible `ubuntu-22.04-amd64` artifacts:

```text
artifacts/fincent-api-ubuntu-22.04-amd64
artifacts/duckdb-static-libs-ubuntu-22.04-amd64.zip
```

The zip extracts to `duckdblib/*.a`, `duckdblib/extension/*/*.duckdb_extension`, and `build-info.txt`, so the extracted `duckdblib` directory can be passed directly with `-L./duckdblib` and used by runtime `LOAD '../duckdblib/extension/.../*.duckdb_extension'` calls.

## Quack Protocol (Client-Server DuckDB)

With DuckDB v2.0.0 and the bundled `quack` extension, DuckDB can run as a multi-user, client-server service over HTTP without single-writer file locks.

### 1. Server Mode
Load the extension and start the server:
```sql
LOAD '../duckdblib/extension/quack/quack.duckdb_extension';
CALL quack_serve('quack:0.0.0.0:9494', token = 'my_secret_token', allow_other_hostname = true);
```

Or configure via environment variables with `appgo/duckdb-tester`:
```bash
QUACK_BIND_ADDR="0.0.0.0:9494" QUACK_TOKEN="my_secret_token" QUACK_SERVE_FOREVER="true" ./main
```

### 2. Client Connection
From any DuckDB client instance:
```sql
CREATE SECRET (TYPE quack, TOKEN 'my_secret_token');
ATTACH 'quack:host:9494' AS remote;

-- Read & write directly to remote server database
SELECT * FROM remote.my_table;
```

## Native DuckDB build (macOS/Linux)

To avoid linker mismatch (for example Linux `.a` files on macOS), build DuckDB artifacts natively on each runner/host:

```bash
chmod +x scripts/build_duckdb_native.sh
./scripts/build_duckdb_native.sh
```

The script outputs host-specific artifacts to `duckdblib/` and writes metadata in `duckdblib/build-info.txt`.

Use `build_duckdb_native_linux` and `build_duckdb_native_macos` jobs in `.gitlab-ci.yml` as a starting point for a build matrix.
