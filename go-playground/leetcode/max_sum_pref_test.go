package leetcode_test

import (
	"fmt"
	"testing"
)

// maxPrefixSum find prefix of in with max sum
func maxPrefixSum(in []int) int {
	psum := make([]int, len(in)+1)
	psum[0] = 0 // empty prefix

	sum := 0
	for i := 0; i < len(in); i++ {
		psum[i+1] = psum[i] + in[i]
		if psum[i+1] > sum {
			sum = psum[i+1]
		}
	}

	return sum
}

func TestMaxPrefixSum(t *testing.T) {
	tcs := []struct {
		in       []int
		expected int
	}{
		{
			[]int{2, 1, 2, 3},
			8,
		},
		{
			[]int{2, 1, -3, 2},
			3,
		},
		{
			[]int{-1, -5, -3},
			0,
		},
		{
			[]int{-3, 1, 1},
			0,
		},
		{
			[]int{},
			0,
		},
		{
			[]int{0},
			0,
		},
		{
			[]int{-2, 2},
			0,
		},
		{
			[]int{0, 2, -2},
			2,
		},
		{
			[]int{-3, 2},
			0,
		},
	}

	for i, tc := range tcs {
		tcName := fmt.Sprintf("TC#%d", i)
		t.Run(tcName, func(t *testing.T) {
			actual := maxPrefixSum(tc.in)
			if actual != tc.expected {
				t.Errorf("wrong output: expected %d, actual %d", tc.expected, actual)
			}
		})
	}
}
