package main

import (
	"context"
	"fmt"
	"testing"
	"time"
)

type Message struct {
	key   string
	value string
}

func poll(ctx context.Context, c int, ch chan<- []Message) error {
	defer close(ch)

	start := time.Now().UnixMilli()

	for i := 0; i < c; i++ {
		select {
		case <-ctx.Done():
			fmt.Printf("time passed %d ms\n", time.Now().UnixMilli()-start)
			return nil
		default:
			time.Sleep(time.Millisecond * 200)
		}

		ch <- []Message{
			{
				key:   "key",
				value: "value",
			},
			{
				key:   "key",
				value: "value",
			},
		}
	}

	return nil
}

func TestGoroutines(t *testing.T) {
	ch := make(chan []Message)

	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second+time.Millisecond*1234)
	defer cancel()

	go poll(ctx, 500, ch)

	for range ch {
		select {
		case <-ctx.Done():
			fmt.Printf("context closed\n")
			cancel()
			return
		default:
		}
	}

}
