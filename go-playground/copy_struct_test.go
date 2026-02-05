package main

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

type A struct {
    a int
}

func debug(a *A) A{
    return *a
}

func TestCopyStruct(t *testing.T) {
    a := &A{1}
    copy := debug(a)
    assert.Equal(t, 1, a.a)
    assert.Equal(t, 1, copy.a)

    a.a = 2
    assert.Equal(t, 2, a.a)
    assert.Equal(t, 1, copy.a)

    copy.a = 3
    assert.Equal(t, 2, a.a)
    assert.Equal(t, 3, copy.a)
}
