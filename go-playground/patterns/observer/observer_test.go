package observer_test

import (
	"testing"

	"github.com/palage4a/go-playground/patterns/observer"
	"github.com/stretchr/testify/assert"
)

func TestObserver(t *testing.T) {
	clicker := new(observer.SimpleClicker)
	il := new(observer.InfoLogger)
	dl := new(observer.DebugLogger)

	il.SetClicker(clicker)
	dl.SetClicker(clicker)

	clicker.Observe(il, dl)

	assert.Equal(t, 0, il.Counter())
	assert.Equal(t, 0, dl.Counter())

	clicker.Click(1)

	assert.Equal(t, 1, il.Counter())
	assert.Equal(t, 1, dl.Counter())

	clicker.Silence()
	clicker.Click(2)

	assert.Equal(t, 1, il.Counter())
	assert.Equal(t, 1, dl.Counter())

	clicker.Observe(il)
	clicker.Click(3)

	assert.Equal(t, 4, il.Counter())
	assert.Equal(t, 1, dl.Counter())

	clicker.Silence()
	clicker.Observe(dl)
	clicker.Click(1)

	assert.Equal(t, 4, il.Counter())
	assert.Equal(t, 2, dl.Counter())
}
