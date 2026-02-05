package main

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestAssertTwoSlices(t *testing.T) {
    a := []int{1,2,3}
    b := []int{1,2,3}

    assert.Equal(t, a, b)
}
