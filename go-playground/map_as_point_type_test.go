package main_test

import (
    "testing"
)

type A struct {
    m map[string]string
}

type B struct {
    i int
}

func setValueToKey(m map[string]string, k, v string) {
    m[k] = v
}

func updateInt(b B, v int) {
    b.i = v
}

func TestMapIsPointDataType(t *testing.T) {
    a := make(map[string]string)
    setValueToKey(a, "a", "a")
    if a["a"] != "a" {
        t.Errorf("map value must be modified")
    }

    astruct := A{
        m: make(map[string]string),
    }
    setValueToKey(astruct.m, "a", "a")
    if astruct.m["a"] != "a" {
        t.Errorf("map value must be modified")
    }

    b := B{1}
    updateInt(b, 2)

    if b.i != 1 {
        t.Errorf("b.i should not be modified")
    }
}
