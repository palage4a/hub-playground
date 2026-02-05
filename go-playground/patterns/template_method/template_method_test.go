package templatemethod_test

import (
	"testing"

	templatemethod "github.com/palage4a/go-playground/patterns/template_method"
	"github.com/stretchr/testify/assert"
)

func TestTemplateMethod(t *testing.T) {
	for _, tc := range []struct {
		name     string
		func1    func() int
		func2    func() int
		expected int
	}{
		{"general", func() int { return -1 }, func() int { return 2 }, 1},
	} {
		t.Run(tc.name, func(t *testing.T) {
			summer := templatemethod.NewSummer(
				tc.func1,
				tc.func2,
			)
			assert.Equal(t, tc.expected, summer.Sum())
		})
	}
}
