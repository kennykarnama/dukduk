package main

/*
#include <stdint.h>

typedef struct duckdb_extension_descriptor duckdb_extension_descriptor;
typedef int32_t (*duckdb_extension_describe_t)(duckdb_extension_descriptor *descriptor);

int32_t duckdb_extension_loadable_extensions_describe(duckdb_extension_descriptor *descriptor);
int32_t duckdb_register_static_extension(duckdb_extension_describe_t describe);

static void init_duckdb_static_extensions(void) {
	duckdb_register_static_extension(duckdb_extension_loadable_extensions_describe);
}
*/
import "C"

func init() {
	C.init_duckdb_static_extensions()
}
