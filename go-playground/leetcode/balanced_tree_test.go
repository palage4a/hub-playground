package leetcode_test

import (
	"fmt"
	"testing"
)

func isBalanced(n *TreeNode) bool {
	if n == nil {
		return true
	}

	if n.Left == nil && n.Right == nil {
		return true
	}

	return isBalanced(n.Left) && isBalanced(n.Right)
}

func TestIsBalanced(t *testing.T) {
	tcs := []struct {
		a   []any
		out bool
	}{
		{
			[]any{3, 9, 20, nil, nil, 15, 7},
			true,
		},
		{
			[]any{1, 2, 2, 3, 3, nil, nil, 4, 4},
			false,
		},
		{
			[]any{},
			false,
		},
	}

	for i, tc := range tcs {
		tcName := fmt.Sprintf("%d", i)
		t.Run(tcName, func(t *testing.T) {
			actual := isBalanced(newTreeUnsafe(tc.a))
			if actual != tc.out {
				t.Errorf("wrong: expected %v, actual %v", tc.out, actual)
			}
		})
	}
}

func newTreeUnsafe(vals []any) *TreeNode {
	if len(vals) == 0 {
		return nil
	}

	root := &TreeNode{
		Val:   vals[0].(int),
		Left:  nil,
		Right: nil,
	}

	i := 1
	q := []*TreeNode{root}
	for i < len(vals) {
		cur := q[len(q)-1]
		q = q[1:]
		if i < len(vals) {
			if v, ok := vals[i].(int); ok {
				if cur != nil {
					cur.Left = &TreeNode{
						Val: v,
					}
					q = append(q, cur.Left)
				} else {
					q = append(q, nil)
				}
			}
			i++

		}
		if i < len(vals) {
			if v, ok := vals[i].(int); ok {
				if cur != nil {
					cur.Right = &TreeNode{
						Val: v,
					}
					q = append(q, cur.Right)
				} else {
					q = append(q, nil)
				}
			}
			i++
		}
	}

	return root
}
