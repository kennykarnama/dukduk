duckdb_extension_load(httpfs
    LOAD_TESTS
    GIT_URL https://github.com/duckdb/duckdb-httpfs
    GIT_TAG 354d3f436a33f80f03a74419e76eb59459e19168
    INCLUDE_DIR extension/httpfs/include
)

duckdb_extension_load(postgres_scanner
            DONT_LINK
            GIT_URL https://github.com/duckdb/duckdb-postgres
            GIT_TAG 6dabd956065e59b24d615fe03bab84d677fca6df
)

duckdb_extension_load(excel
    LOAD_TESTS
    GIT_URL https://github.com/duckdb/duckdb-excel
    GIT_TAG 27ebb61fefda2e29bf649f4348dff233880cf582
    INCLUDE_DIR src/excel/include
)

duckdb_extension_load(mssql
    LOAD_TESTS
    GIT_URL https://github.com/hugr-lab/mssql-extension
    GIT_TAG 310219b6c38f85ee24b5edd3a03589362233f428
    INCLUDE_DIR src/include
)

duckdb_extension_load(sshfs
    LOAD_TESTS
    GIT_URL https://github.com/midwork-finds-jobs/duckdb-sshfs
    GIT_TAG 5f2e422f964010d11a0bea040ab421c4d7f7fa41
    SUBMODULES extension-ci-tools
    INCLUDE_DIR src/include
)


duckdb_extension_load(nanoarrow
    LOAD_TESTS
    LINKED_LIBS "../../_deps/nanoarrow-build/lib*.a"
    GIT_URL https://github.com/paleolimbot/duckdb-nanoarrow
    GIT_TAG 0201908c2163218aba0b8eb95fca753ab3ee3868
    INCLUDE_DIR src/include
)

duckdb_extension_load(json)

duckdb_extension_load(json_schema
    LOAD_TESTS
    GIT_URL https://github.com/Query-farm/json_schema
    GIT_TAG 69664ce2fb234a071c4e01690584d2c402e96705
    SUBMODULES extension-ci-tools
    INCLUDE_DIR src/include
)
