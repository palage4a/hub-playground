package main

import (
	"context"
	"fmt"
	"time"

	"github.com/tarantool/go-tarantool/v2"
	"github.com/tarantool/go-tarantool/v2/pool"
)

func main() {
	dialers := []pool.Instance{{
		Name: "tnt",
		Dialer: tarantool.NetDialer{
			User:     "user",
			Password: "pass",
			Address:  "127.0.0.1:3308",
		},
		Opts: tarantool.Opts{
			Timeout:   time.Second,
			Reconnect: time.Second * 1,
		},
	}}
	ctx := context.Background()
	_, err := pool.Connect(ctx, dialers)
	if err != nil {
		panic(err)
	}
	fmt.Println("connected")

	for {
		time.Sleep(time.Second)
	}
}
