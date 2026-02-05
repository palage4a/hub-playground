package main

import (
	"flag"
	"fmt"
)

var (
	c  = flag.Int("c", 15, "count of messages")
	b = flag.Int("b", 5, "batch size")
)


func main() {
	flag.Parse()

	var	(
		in = make(chan int, *b)
		buff = make(chan []int)
		done = make(chan struct{})
	)

	go func() {
		for {
			select {
			case b, ok := <- buff:
				fmt.Printf("Got batch: %v\n", b)
				if !ok {
					fmt.Printf("Finishing! \n")
					done <- struct{}{}
					return
				}
			}
		}

	}()

	go func() {
		// ticker := time.NewTicker(100 * time.Millisecond)
		for i := 0; i < *c; i++ {
			select {
			case in <- i:
				fmt.Printf("Putted %d\n", i)
			// case <- ticker.C:
			default:
				fmt.Printf("Flushing...\n")
				batch := make([]int, 0, *b)
				for j := 0; j < *b; j++  {
					batch = append(batch, <-in)
				}
				buff <- batch
			}

		}
		close(in)
		close(buff)
	}()

	<- done

	return
}
