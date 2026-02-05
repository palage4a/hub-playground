package main

import (
	"fmt"
	"net/http"
	"net/http/pprof"
	"testing"
)

var routes = map[string]http.HandlerFunc{
	"/debug/pprof/":        pprof.Index,
	"/debug/pprof/cmdline": pprof.Cmdline,
	// "/debug/pprof/profile": pprof.Profile,
	"/debug/pprof/symbol": pprof.Symbol,
	"/debug/pprof/trace":  pprof.Trace,
}

var httpReady chan struct{}

func runPprofServer(t *testing.T) {
	t.Helper()
	r := http.NewServeMux()

	for path, handler := range routes {
		r.HandleFunc(path, handler)
	}

	http.ListenAndServe(":8080", r)
}

func TestPprofHTTPHandlers(t *testing.T) {
	go runPprofServer(t)

	for path := range routes {
		tcName := fmt.Sprintf("CheckPath:%s", path)
		t.Run(tcName, func(t *testing.T) {
			res, err := http.Get(fmt.Sprintf("http://localhost:8080%s", path))
			if err != nil {
				t.Errorf("%s", err)
			}
			if res.StatusCode != 200 {
				t.Errorf("status.code: actual %d, expected %d", res.StatusCode, 200)
			}
		})
	}
}
