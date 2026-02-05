package main

import (
	"fmt"
	"testing"
	"time"
)

func TestUnixNano(t *testing.T) {
	ts := time.Now().UnixNano()
	fmt.Printf("%d", ts)
}
