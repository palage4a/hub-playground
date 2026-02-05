package main_test

import (
	"testing"
)

func TestAppend(t *testing.T) {
	t.Skip()
	a := make([]string, 0, 10)
	a = append(a, "a")

	if len(a) != 0 {
		t.Errorf("wrong")
	}
}
