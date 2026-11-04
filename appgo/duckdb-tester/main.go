package main

import (
	"database/sql"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	_ "github.com/duckdb/duckdb-go/v2"
)

func findExtension(name string) string {
	candidates := []string{
		fmt.Sprintf("%s/extension/%s/%s.duckdb_extension", os.Getenv("DUCKDB_LIB_DIR"), name, name),
		fmt.Sprintf("../duckdblib/extension/%s/%s.duckdb_extension", name, name),
		fmt.Sprintf("./duckdblib/extension/%s/%s.duckdb_extension", name, name),
		fmt.Sprintf("/duckdblib/extension/%s/%s.duckdb_extension", name, name),
		fmt.Sprintf(".duckdblib_build/extension/%s/%s.duckdb_extension", name, name),
		fmt.Sprintf("../artifacts/duckdb-static-libs-macos-arm64/duckdblib/extension/%s/%s.duckdb_extension", name, name),
	}
	for _, c := range candidates {
		if c != "" && !strings.HasPrefix(c, "/extension/") {
			if _, err := os.Stat(c); err == nil {
				return c
			}
		}
	}
	return fmt.Sprintf("../duckdblib/extension/%s/%s.duckdb_extension", name, name)
}

func main() {
	extNames := []string{
		"postgres_scanner",
		"ducklake",
		"excel",
		"nanoarrow",
		"httpfs",
		"sshfs",
		"quack",
	}

	db, err := sql.Open("duckdb", ":memory:?allow_unsigned_extensions=true")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	for _, name := range extNames {
		extPath := findExtension(name)
		if _, err := os.Stat(extPath); os.IsNotExist(err) {
			fmt.Printf("Notice: extension %s not found at %s (skipping)\n", name, extPath)
			continue
		}
		if _, err := db.Exec(fmt.Sprintf(`LOAD '%s';`, extPath)); err != nil {
			panic(fmt.Errorf("failed to load extension %s (%s): %w", name, extPath, err))
		}
		fmt.Printf("success init ext: %s (%s)\n", name, extPath)
	}

	// Verify loaded extensions from DuckDB catalog
	rows, err := db.Query("SELECT extension_name, loaded FROM duckdb_extensions() WHERE loaded = true;")
	if err == nil {
		defer rows.Close()
		fmt.Println("\n--- Loaded Extensions in DuckDB ---")
		for rows.Next() {
			var name string
			var loaded bool
			if err := rows.Scan(&name, &loaded); err == nil {
				fmt.Printf("• %s (loaded: %v)\n", name, loaded)
			}
		}
	}

	// Quack Protocol Server Verification & Lifecycle
	bindAddr := os.Getenv("QUACK_BIND_ADDR")
	if bindAddr == "" {
		bindAddr = "127.0.0.1:9494"
	}
	token := os.Getenv("QUACK_TOKEN")
	if token == "" {
		token = "duckduck-quack-secret"
	}

	quackTarget := fmt.Sprintf("quack:%s", bindAddr)
	fmt.Printf("\n[Quack Server] Starting server on %s ...\n", quackTarget)
	serveQuery := fmt.Sprintf("CALL quack_serve('%s', token = '%s', allow_other_hostname = true);", quackTarget, token)
	if _, err := db.Exec(serveQuery); err != nil {
		fmt.Printf("[Quack Server] Notice: quack_serve returned: %v\n", err)
	} else {
		fmt.Printf("[Quack Server] Successfully started serving on %s\n", quackTarget)

		// List servers
		serverRows, err := db.Query("SELECT * FROM quack_server_list();")
		if err == nil {
			defer serverRows.Close()
			fmt.Println("[Quack Server] Active servers:")
			cols, _ := serverRows.Columns()
			for serverRows.Next() {
				vals := make([]interface{}, len(cols))
				valPtrs := make([]interface{}, len(cols))
				for i := range vals {
					valPtrs[i] = &vals[i]
				}
				if err := serverRows.Scan(valPtrs...); err == nil {
					fmt.Printf("  -> %v\n", vals)
				}
			}
		}

		// Local table verification
		if _, err := db.Exec("CREATE TABLE quack_test AS SELECT 'quack-protocol-ok' AS status;"); err == nil {
			var status string
			if err := db.QueryRow("SELECT status FROM quack_test;").Scan(&status); err == nil {
				fmt.Printf("[Quack Server] Local table verification: %s\n", status)
			}
		}

		if os.Getenv("QUACK_SERVE_FOREVER") == "true" {
			fmt.Println("[Quack Server] Running in persistent server mode. Press Ctrl+C or send SIGTERM to stop.")
			sigCh := make(chan os.Signal, 1)
			signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)
			<-sigCh
			fmt.Println("\n[Quack Server] Received termination signal. Stopping server...")
			_, _ = db.Exec(fmt.Sprintf("CALL quack_stop('%s');", quackTarget))
			time.Sleep(500 * time.Millisecond)
			fmt.Println("[Quack Server] Server stopped.")
		} else {
			// For self-testing / CI, shut down cleanly after test
			fmt.Println("[Quack Server] Self-test complete. Stopping test server...")
			if _, err := db.Exec(fmt.Sprintf("CALL quack_stop('%s');", quackTarget)); err != nil {
				fmt.Printf("[Quack Server] quack_stop: %v\n", err)
			}
			fmt.Println("[Quack Server] Test server stopped successfully.")
		}
	}
}
