package main

import (
	"fmt"
	"maps"
	"testing"
)

func TestNilMap(t *testing.T) {
	var nilMap map[string]int

	if nilMap != nil {
		t.Errorf("map must be nil, actual %v", nilMap)
	}
}

func TestLiteralMap(t *testing.T) {
	m := map[string]int{}

	if m == nil {
		t.Errorf("map must not be nil, actual %v", m)
	}

	v, ok := m["key"]
	if ok {
		t.Errorf("getting not existing key (ok) must be false, actual: %v", ok)
	}

	if v != 0 {
		t.Errorf("getting empty value of int must be 0, actual: %v", v)
	}
}

func TestMapWithLen(t *testing.T) {
	m := make(map[string]int, 10)

	if len(m) != 0 {
		t.Errorf("map made with length of 10 must have zero len, actual %v", len(m))
	}

	m["key"] = 0
	if len(m) != 1 {
		t.Errorf("map with one element must have len == 1, actual %v", len(m))
	}

	v, ok := m["key"]
	if ok == false {
		t.Errorf("existing but niled value must presenced (ok == true, actual %v)", v)
	}
}

func BenchmarkMapsCopy(b *testing.B) {
	src := make(map[string]int, 1000)
	for i := 0; i < 1000; i++ {
		src[fmt.Sprintf("key%d", i)] = i
	}

	dst := make(map[string]int, 1000)

	for _, tt := range []struct {
		name string
		f    func(map[string]int, map[string]int) map[string]int
	}{
		{"maps.Copy", func(dst, src map[string]int) map[string]int {
			maps.Copy(dst, src)
			return dst
		}},
		{"manual copy", func(dst, src map[string]int) map[string]int {
			for k, v := range src {
				dst[k] = v
			}
			return dst
		}},
	} {
		b.Run(tt.name, func(b *testing.B) {
			for range b.N {
				tt.f(dst, src)
			}
		})
	}
}
