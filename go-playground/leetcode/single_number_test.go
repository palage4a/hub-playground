// https://leetcode.com/problems/single-number/description/
package leetcode_test

import "testing"

func SingleNumber(in []int) int {
	out := 0
	for _, v := range in {
		out ^= v
	}
	return out
}

func TestSingleNumber(t *testing.T) {
	var tcs = []struct {
		name     string
		input    []int
		expected int
	}{
		{
			"initial",
			[]int{-10, 2, 1, 0, 2, 4, 1, 4, -10},
			0,
		},
		{
			"one",
			[]int{-10},
			-10,
		},
	}
	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			actual := SingleNumber(tc.input)
			if actual != tc.expected {
				t.Errorf("wrong: actual %d, expected %d", actual, tc.expected)
			}
		})
	}
}
