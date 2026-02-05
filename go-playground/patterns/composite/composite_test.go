package composite_test

import (
	"testing"

	"github.com/palage4a/go-playground/patterns/composite"
	"github.com/stretchr/testify/assert"
)

func TestComposite(t *testing.T) {
	for _, tc := range []struct {
		name     string
		scorers  []composite.Scorer
		expected int
	}{
		{"general", []composite.Scorer{
			composite.NewUser(1),
			composite.NewCaptain(composite.NewUser(2), 3),
			composite.NewCaptain(composite.NewUser(-1), -2),
		}, 9},
		{"empty group", []composite.Scorer{composite.NewGroup(nil)}, 0},
		{"sub group", []composite.Scorer{composite.NewGroup([]composite.Scorer{composite.NewUser(1), composite.NewUser(2)})}, 3},
		{"user", []composite.Scorer{composite.NewUser(2)}, 2},
		{"captain", []composite.Scorer{composite.NewCaptain(composite.NewUser(2), 3)}, 6},
		{"bad captain", []composite.Scorer{composite.NewCaptain(composite.NewUser(-1), -2)}, 2},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := composite.NewGroup(tc.scorers)
			actual := g.Score()
			assert.Equal(t, tc.expected, actual)
		})
	}

}
