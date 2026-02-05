package main_test

import (
	"testing"

	"github.com/vmihailenco/msgpack/v5"
)

func TestUnmarshalingWithRedundantField(t *testing.T) {
	type Item struct {
		Foo string
		Bar string
	}

	type Item2 struct {
		Foo string
	}

	b, err := msgpack.Marshal(&Item{Foo: "foo", Bar: "bar"})
	if err != nil {
        t.Fatalf("marshaling error: %s", err)
	}

	var item Item2
	err = msgpack.Unmarshal(b, &item)
	if err != nil {
        t.Fatalf("unmarshaling error: %s", err)
	}
    if item.Foo != "foo" {
        t.Errorf("incorrect Foo field: %s", item.Foo)
    }
}
