package main

import (
	"fmt"
	"log"
	"net/http"
	_ "net/http/pprof"
	"testing"
)

/*
Start bench:
go test -v -bench . -benchtime 12s pprof_test.go
Get profile:
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=10
*/
func BenchmarkTestPprof(b *testing.B) {
	go func() {
		log.Println(http.ListenAndServe("localhost:6060", nil))
	}()

	a := make(map[string]int, b.N)
	for i := 0; i < b.N; i++ {
		k := fmt.Sprintf("%d", i)
		v := i
		a[k] = v
	}
}
