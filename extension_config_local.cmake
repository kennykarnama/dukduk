duckdb_extension_load(httpfs
    LOAD_TESTS
    GIT_URL https://github.com/duckdb/duckdb-httpfs
    GIT_TAG 3b48554efa84bdf4397f4758f9701646c65d06c1
    INCLUDE_DIR extension/httpfs/include
)

duckdb_extension_load(postgres_scanner
    GIT_URL https://github.com/duckdb/duckdb-postgres
    GIT_TAG 2a1871dfe28dcde47c083860fb5ddc2a5c56dc69
    SUBMODULES database-connector
)

duckdb_extension_load(ducklake
    GIT_URL https://github.com/duckdb/ducklake
    GIT_TAG 57cd8de938780ba05149308662a1eeb5701a7c5d
)

duckdb_extension_load(excel
    LOAD_TESTS
    GIT_URL https://github.com/duckdb/duckdb-excel
    GIT_TAG 81bb84b115b97cc4edec4827714cac80da0127e1
    INCLUDE_DIR src/excel/include
)

duckdb_extension_load(mssql
    LOAD_TESTS
    GIT_URL https://github.com/hugr-lab/mssql-extension
    GIT_TAG 4c65cfb841577f8e56e7e43a5f83c459780d842a
    INCLUDE_DIR src/include
)

duckdb_extension_load(sshfs
    LOAD_TESTS
    GIT_URL https://github.com/midwork-finds-jobs/duckdb-sshfs
    GIT_TAG 5556aa00c5f199dc9d7f26b55a14fbf12a151339
    SUBMODULES extension-ci-tools
    INCLUDE_DIR src/include
)

duckdb_extension_load(nanoarrow
    LOAD_TESTS
    LINKED_LIBS "../../_deps/nanoarrow-build/lib*.a"
    GIT_URL https://github.com/paleolimbot/duckdb-nanoarrow
    GIT_TAG e390b9b4f8a41e64e41488888defb27d8f1e1421
    INCLUDE_DIR src/include
)

duckdb_extension_load(quack
    GIT_URL https://github.com/duckdb/duckdb-quack
    GIT_TAG 726531a7166ae020944d174d54faa0c9c9bd6b75
)

duckdb_extension_load(json_schema
    LOAD_TESTS
    GIT_URL https://github.com/Query-farm/json_schema
    GIT_TAG ed6cbd4f15140fb19296c605b384aeef5591e606
    SUBMODULES extension-ci-tools
    INCLUDE_DIR src/include
)
