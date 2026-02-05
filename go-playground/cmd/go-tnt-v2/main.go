package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/tarantool/go-tarantool/v2"
)

func main() {
	opts := tarantool.Opts{
		Timeout:       time.Second * 5,
		MaxReconnects: 100,
		Reconnect:     5 * time.Second,
		SkipSchema:    true,
	}

	dialer := tarantool.NetDialer{
		Address:  "127.0.0.1:3301",
		User:     "admin",
		Password: "secret-cluster-cookie",
	}

	ctx := context.Background()

	_, err := tarantool.Connect(ctx, dialer, opts)
	if err != nil {
		fmt.Println("Connection refused:", err)
		os.Exit(1)
	}

	fmt.Println("connected")

	// resp, err := conn.Insert(999, []interface{}{99999, "BB"})
	// if err != nil {
	// 	fmt.Println("Error", err)
	// 	fmt.Println("Code", resp.Code)
	// }

}
