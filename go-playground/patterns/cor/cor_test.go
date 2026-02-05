package cor_test

import (
	"testing"

	"github.com/palage4a/go-playground/patterns/cor"
	"github.com/stretchr/testify/assert"
)

// Example of chain of responsibility usage: middlewares/interceptors
func TestCor(t *testing.T) {
	first := &cor.A1{}
	second := &cor.A2{}
	third := &cor.A3{}

	third.SetNext(second)
	second.SetNext(first)

	assert.Equal(t, "A1 1", third.Execute(1))
	assert.Equal(t, "A2 2", third.Execute(2))
	assert.Equal(t, "A3 3", third.Execute(3))
	assert.Equal(t, "BaseA 4", third.Execute(4))
	assert.Equal(t, "BaseA 0", third.Execute(0))
}
