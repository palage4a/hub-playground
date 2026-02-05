package main

import "fmt"

func f(left, right chan int) {
	v := 1 + <-right
	fmt.Printf("v: %d\n", v)
	left <- v
}

func main() {
	const n = 100
	leftmost := make(chan int)
	right := leftmost
	left := leftmost
	for range n {
		right = make(chan int)
		go f(left, right)
		left = right
	}
	go func(c chan int) { c <- 1 }(right)
	fmt.Println(<-leftmost)
}
