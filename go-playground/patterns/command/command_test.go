package command_test

import (
	"testing"

	"github.com/palage4a/go-playground/patterns/command"
	"github.com/stretchr/testify/assert"
)

// NOTE: It seems to me, the most common use of Command pattern is history of actions (commands).
func TestCommand(t *testing.T) {

	tcs := []struct {
		name     string
		inc      int32
		expected int32
	}{
		{"zero", 0, 1},
		{"two", 2, 3},
		{"minus 3", -3, -2},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			inc := command.NewIncrement(tc.inc)
			cmd := command.NewIncrementCommand(inc)
			cmd.Execute()
			assert.Equal(t, int32(tc.expected), inc.Value())
		})
	}

}
