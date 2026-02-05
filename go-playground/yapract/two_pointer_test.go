package yapract_test

import (
	"fmt"
	"testing"

	"github.com/google/go-cmp/cmp"
)

func contSum(a []int, t int) [2]int {
	res := [2]int{}
	cur_idx := 0
	max := 0
	for cur_idx < len(a) {
		next_idx := cur_idx
		for next_idx < len(a) {
			if 
		}
	}

	return res
}

func TestSlidingSum(t *testing.T) {
	for i, tc := range []struct {
		a        []int
		t        int
		expected [2]int
	}{
		{
			[]int{-1, 2, -2, 0, 5},
			5,
			[2]int{3, 4},
		},
	} {
		t.Run(fmt.Sprintf("%d", i), func(t *testing.T) {
			actual := contSum(tc.a, tc.t)
			if diff := cmp.Diff(tc.expected, actual); diff != "" {
				t.Errorf("%s", diff)
			}
		})
	}
}
