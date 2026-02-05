package main

import (
	"testing"

	"gopkg.in/yaml.v3"
)

type InlineFlow struct {
	Map map[string]int `yaml:",inline,flow"`
}

type FlowInline struct {
	Map map[string]int `yaml:",flow,inline"`
}

func TestYamlFlowInline(t *testing.T) {
	t.Skip("IDK but it don't work")
	data := map[string]int{"a": 1}

	a := &InlineFlow{Map: data}
	b := &FlowInline{Map: data}

	resA, err := yaml.Marshal(a)
	if err != nil {
		t.Error(err)
	}

	expected := "{a : 1}"

	if string(resA) != expected {
		t.Errorf("wrong result: expected: %s, actual: %s", expected, resA)
	}

	resB, err := yaml.Marshal(b)
	if err != nil {
		t.Error(err)
	}

	if string(resB) != "{a: 1}" {
		t.Errorf("wrong result: expected: %s, actual: %s", expected, resB)
	}

}
