package main

import (
	"fmt"
	"testing"
)

type GrpcListen struct {
	Uri string
}

type Config struct {
	GrpcListen []GrpcListen
	GrpcHost   string
	GrpcPort   string
}

var testcases = []struct {
	Name     string
	Config   Config
	Expected string
}{
	{
		"L/H/P",
		Config{
			[]GrpcListen{{"unix:///tmp/a.sock"}},
			"localhost",
			"3301",
		},
		"unix:///tmp/a.sock",
	},
	{
		"-/H/P",
		Config{
			[]GrpcListen{{""}},
			"localhost",
			"3301",
		},
		"localhost:3301",
	},
	{
		"L/-/-",
		Config{
			[]GrpcListen{{"unix:///tmp/a.sock"}},
			"",
			"",
		},
		"unix:///tmp/a.sock",
	},
	{
		"LL/-/-",
		Config{
			[]GrpcListen{{"unix:///tmp/a.sock"}, {"unix:///tmp/b.sock"}},
			"",
			"",
		},
		"",
	},
	{
		"-/-/-",
		Config{
			[]GrpcListen{},
			"",
			"",
		},
		"",
	},
}

func getListenPath(config Config) (string, error) {
	var path string
	if config.GrpcHost != "" && config.GrpcPort != "" {
		fmt.Printf("grpc_host and grpc_port has deprecated, please use grpc_listen instead\n")
		path = fmt.Sprintf("%s:%s", config.GrpcHost, config.GrpcPort)
	}

	if len(config.GrpcListen) > 1 {
		return "", fmt.Errorf("multiple listeners not supported yet")
	}

	if len(config.GrpcListen) != 0 && config.GrpcListen[0].Uri != "" {
		path = config.GrpcListen[0].Uri
	}

	return path, nil
}

func TestConfig(t *testing.T) {
	for _, tc := range testcases {
		t.Run(tc.Name, func(t *testing.T) {
			config := tc.Config

			path, err := getListenPath(config)
			if err != nil {
				t.Logf("getListenPath err: %s", err)
			}

			if path != tc.Expected {
				t.Errorf("expected %s actual %s", tc.Expected, path)
			}
		})
	}
}
