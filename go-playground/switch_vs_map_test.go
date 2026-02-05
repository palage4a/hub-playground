package main_test

import (
	_ "github.com/stretchr/testify/assert"
	"math/rand"
	"testing"
)

func err(i int) string {
	switch i {
	case 1:
		return "First"
	case 2:
		return "Second"
	case 3:
		return "Third"
	default:
		return "Fourth"
	}
	return ""
}

func BenchmarkSwitch(b *testing.B) {
	for range b.N {
		i := rand.Intn(3)
		_ = err(i)
	}
}

var m = map[int]string{
	1: "First",
	2: "Second",
	3: "Third",
}

func BenchmarkMap(b *testing.B) {
	for range b.N {
		i := rand.Intn(3)
		_ = m[i]
	}
}
