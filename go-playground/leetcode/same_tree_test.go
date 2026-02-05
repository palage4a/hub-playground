package leetcode_test

import (
	"fmt"
	"testing"
)

func newTree(vals []int) *TreeNode {
	if len(vals) == 0 {
		return nil
	}

	root := &TreeNode{
		Val:   vals[0],
		Left:  nil,
		Right: nil,
	}

	i := 1
	q := []*TreeNode{root}
	for i < len(vals) {
		cur := q[len(q)-1]
		q = q[1:]
		if i < len(vals) {
			cur.Left = &TreeNode{
				Val: vals[i],
			}
			i++
			q = append(q, cur.Left)
		}
		if i < len(vals) {
			cur.Right = &TreeNode{
				Val: vals[i],
			}
			i++
			q = append(q, cur.Right)
		}
	}

	return root
}

type TreeNode struct {
	Val   int
	Left  *TreeNode
	Right *TreeNode
}

func isSameTree(p *TreeNode, q *TreeNode) bool {
	if p == nil && q == nil {
		return true
	}

	if p != nil && q == nil {
		return false
	}

	if p == nil && q != nil {
		return false
	}

	if p.Val != q.Val {
		return false
	}

	if p.Left == nil && q.Left != nil {
		return false
	}

	if p.Right == nil && q.Right != nil {
		return false
	}

	return isSameTree(p.Left, q.Left) && isSameTree(p.Right, q.Right)
}

func TestIsSameTreee(t *testing.T) {
	tcs := []struct {
		a   []int
		b   []int
		out bool
	}{
		{
			[]int{1, -2, 3},
			[]int{1, -2, 3},
			true,
		},
		{
			[]int{1, 2, 3},
			[]int{1, 2, 3},
			true,
		},
		{
			[]int{},
			[]int{0},
			false,
		},
	}

	for i, tc := range tcs {
		tcName := fmt.Sprintf("%d", i)
		t.Run(tcName, func(t *testing.T) {
			actual := isSameTree(newTree(tc.a), newTree(tc.b))
			if actual != tc.out {
				t.Errorf("wrong: expected %v, actual %v", tc.out, actual)
			}
		})
	}
}
