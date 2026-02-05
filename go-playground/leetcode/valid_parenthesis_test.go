package leetcode_test

import (
	"fmt"
	"testing"
)

func isValid(s string) bool {
	op := map[rune]rune{
		'(': ')',
		'[': ']',
		'{': '}',
	}

	cl := map[rune]rune{
		')': '(',
		']': '[',
		'}': '{',
	}

	stack := make([]rune, 0)
	for _, c := range s {
		if _, ok := op[c]; ok {
			stack = append(stack, c)
		}

		if op, ok := cl[c]; ok {
			if len(stack) == 0 {
				return false
			}

			if stack[len(stack)-1] == op {
				stack = stack[:len(stack)-1]
			} else {
				return false
			}
		}
	}

	return len(stack) == 0
}

func TestIsValid(t *testing.T) {
	tcs := []struct {
		in  string
		out bool
	}{
		{"()", true},
		{"()[]{}", true},
		{"(]", false},
		{"([])", true},
		{"[", false},
		{"]", false},
	}

	for i, tc := range tcs {
		tcName := fmt.Sprintf("%d", i)
		t.Run(tcName, func(t *testing.T) {
			actual := isValid(tc.in)
			if actual != tc.out {
				t.Errorf("wrong: expected %v, actual %v", tc.out, actual)
			}
		})
	}
}
