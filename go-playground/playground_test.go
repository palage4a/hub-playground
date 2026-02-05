package main_test

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"testing"
)

// This does not work
// type Option[T any] struct {
// 	Value T
// }

// func Unwrap[T any](o Option[T]) T {
// 	fmt.Printf("%T", o.Value)

// 	switch o.Value.(type) {
// 	case "string":
// 		return "its a value: " + o.Value
// 	default:
// 		return o.Value
// 	}
// }

// func TestA(t *testing.T) {
// 	o := Option[string]{Value: "string"}
// 	assert.Equal(t, "string", Unwrap(o))
// }

type Option[T any] struct {
	v T
	e bool
}

func NewOption[T any](v T, e bool) Option[T] {
	return Option[T]{v: v, e: e}
}

func (o Option[T]) Map(f func(a T) (T, bool)) Option[T] {
	b, e := f(o.v)
	return Option[T]{b, e}
}

func TestOption(t *testing.T) {
	a := NewOption(3, true)

	_ = a.Map(func(a int) (string, bool) {
		return fmt.Sprintf("%d", a), true
	})
	assert.Equal(t, true, false)
}
