package leetcode_test

import (
	"fmt"
	"testing"
)

// https://leetcode.com/problems/valid-anagram/description/
func isAnagram(s string, t string) bool {
	if len(s) != len(t) {
		return false
	}

	tmap := make(map[rune]int, len(s))
	for _, c := range s {
		tmap[c] += 1
	}

	for _, c := range t {
		tmap[c] -= 1
	}

	for _, v := range tmap {
		if v != 0 {
			return false
		}
	}

	return true
}

func TestIsAnagram(t *testing.T) {
	var tcs = []struct {
		a   string
		b   string
		out bool
	}{
		{"a", "abb", false},
		{"aa", "bb", false},
	}

	for i, tc := range tcs {
		tcname := fmt.Sprintf("%d", i)
		t.Run(tcname, func(t *testing.T) {
			actual := isAnagram(tc.a, tc.b)
			if actual != tc.out {
				t.Errorf("expected %v, actual %v", tc.out, actual)
			}

		})
	}
}
