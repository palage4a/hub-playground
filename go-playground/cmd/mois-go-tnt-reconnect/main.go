package main

import (
	"context"
	"log"
	"os/exec"
	"time"

	"github.com/tarantool/go-tarantool/v2"
)

func main() {
	// Prepare tarantool command
	cmd := exec.Command("tarantool", "cmd/mois-go-tnt-reconnect/init.lua")

	// Start tarantool.
	err := cmd.Start()
	if err != nil {
		log.Panic("Failed to start: ", err)
	}
	defer cmd.Process.Kill()

	// Uncomment to wait explicitly.
	// time.Sleep(200 * time.Millisecond)

	// Try to connect and ping tarantool.
	var opts = tarantool.Opts{
		Timeout:       10 * time.Second,
		MaxReconnects: 5,
		Reconnect:     200 * time.Millisecond,
		SkipSchema:    true,
	}

	dialer := tarantool.NetDialer{
		Address:  "127.0.0.1:3301",
		User:     "guest",
		Password: "",
	}

	ctx := context.Background()

	conn, cerr := tarantool.Connect(ctx, dialer, opts)
	if cerr != nil {
		log.Panic("Failed to connect: ", cerr)
	}
	if conn == nil {
		log.Panic("Conn is nil after connect")
	}
	defer conn.Close()

	resp, rerr := conn.Ping()
	if rerr != nil {
		log.Panic("Failed to ping: ", rerr)
	}
	if resp == nil {
		log.Panic("Response is nil after ping")
	}
}
