package decorator_test

import (
	"testing"

	"github.com/palage4a/go-playground/patterns/decorator"
	"github.com/stretchr/testify/assert"
)

func TestDecorator(t *testing.T) {
	l := new(decorator.Log)

	dl := decorator.NewDebugLog(l)
	il := decorator.NewInfoLog(l)

	var expected string

	expected = "log"
	assert.Equal(t, expected, l.Log("log"))
	expected = "DEBUG: log"
	assert.Equal(t, expected, dl.Log("log"))
	expected = "INFO: log"
	assert.Equal(t, expected, il.Log("log"))
}
