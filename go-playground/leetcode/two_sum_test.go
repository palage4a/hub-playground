package leetcode_test

import (
	"fmt"
	"testing"

	"github.com/google/go-cmp/cmp"
)

func twoSum(nums []int, target int) []int {
	m := make(map[int]int, len(nums))
	for i, v := range nums {
		rest := target - v
		if _, ok := m[rest]; ok {
			return []int{m[rest], i}
		}
		m[v] = i
	}
	return []int{}
}

func TestTwoSum(t *testing.T) {
	var tcs = []struct {
		nums   []int
		target int
		out    []int
	}{{
		[]int{2, 7, 2, 3},
		9,
		[]int{0, 1},
	}}

	for i, tc := range tcs {
		tcName := fmt.Sprintf("%d", i)
		t.Run(tcName, func(t *testing.T) {
			actual := twoSum(tc.nums, tc.target)
			if diff := cmp.Diff(tc.out, actual); diff != "" {
				t.Errorf("%s", diff)
			}
		})
	}
}
