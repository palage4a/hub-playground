package levenshtein_test

import (
	"testing"
	"github.com/stretchr/testify/assert"

	"github.com/palage4a/go-playground/levenshtein"
)

func TestDistance(t *testing.T) {
	str1 := "фыва"
	str2 := "йыва"

	distance := levenshtein.Distance(str1, str2)
	assert.Equal(t, 1,  distance)
}