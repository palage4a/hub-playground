// package main

// import (
// 	"fmt"

// 	"github.com/tarantool/go-tarantool/v2"
// )

// func main() {
// 	connect, err := tarantool.Connect("127.0.0.1:3301", tarantool.Opts{
// 		User: "user",
// 		Pass: "pass",
// 	})
// 	if err != nil {
// 		panic(err)
// 	}

// 	resp, err := connect.Call("queue.subscribe", []any{1000, "queue", nil, 0})
// 	if err != nil {
// 		panic(err)
// 	}

// 	fmt.Println("debug")
// 	fmt.Println("debug")
// 	fmt.Printf("%v\n", resp)
// 	fmt.Println("debug")
// 	fmt.Println("debug")
// }
