package main_test

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestAllocString(t *testing.T) {}

func d(s *string) string {
	if s == nil {
		return ""
	}

	return *s
}

func p(s string) *string {
	return &s
}

type S struct {
	s *string
}

func BenchmarkAllocString(b *testing.B) {
	s := S{
		s: p("string"),
	}

	for range b.N {
		res := d(s.s)
		assert.NotNil(b, res)
	}
}
