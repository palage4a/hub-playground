package main

import (
	"fmt"
	"strconv"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestStrconvFmt(t *testing.T) {
	now := time.Now().UnixNano()

	a := strconv.FormatInt(now, 10)
	b := fmt.Sprintf("%d", now)

	assert.Equal(t, a, b)
}
