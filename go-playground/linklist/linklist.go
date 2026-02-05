package linklist

import "fmt"

type ListNode struct {
	Val  int
	Next *ListNode
}

func (n *ListNode) String() string {
	plain := make([]int, 0)
	i := 0
	for n != nil {
		plain = append(plain, n.Val)
		n = n.Next
		i++
	}

	str := fmt.Sprintf("%d", plain[0])
	for _, v := range plain[1:] {
		str = fmt.Sprintf("%s -> %d", str, v)
	}

	return str
}

func Merge(b *ListNode) *ListNode {
	return nil
}

func Eq(a, b *ListNode) bool {
	for a != nil {
		for b != nil {
			if a.Val != b.Val {
				return false
			}

			a = a.Next
			b = b.Next
		}
	}
}
