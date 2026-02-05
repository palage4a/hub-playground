package linklist_test

import (
	"testing"

	"github.com/palage4a/go-playground/linklist"
)

var tcs = []struct {
	name   string
	input  []*linklist.ListNode
	output *linklist.ListNode
}{
	{
		name: "two",
		input: []*linklist.ListNode{
			{1,
				&linklist.ListNode{2,
					&linklist.ListNode{2, nil},
				},
			},
			{1,
				&linklist.ListNode{2,
					&linklist.ListNode{3,
						&linklist.ListNode{3, nil},
					},
				},
			},
		},
		output: &linklist.ListNode{1,
			&linklist.ListNode{1,
				&linklist.ListNode{2,
					&linklist.ListNode{2,
						&linklist.ListNode{2,
							&linklist.ListNode{3,
								&linklist.ListNode{3, nil},
							},
						},
					},
				},
			},
		},
	},
	{
		name: "initial",
		input: []*linklist.ListNode{
			{1,
				&linklist.ListNode{2,
					&linklist.ListNode{2, nil},
				},
			},
			{1,
				&linklist.ListNode{2,
					&linklist.ListNode{3,
						&linklist.ListNode{3, nil},
					},
				},
			},
			{2, nil},
		},
		output: &linklist.ListNode{1,
			&linklist.ListNode{1,
				&linklist.ListNode{2,
					&linklist.ListNode{2,
						&linklist.ListNode{2,
							&linklist.ListNode{2,
								&linklist.ListNode{3,
									&linklist.ListNode{3, nil},
								},
							},
						},
					},
				},
			},
		},
	},
}

func TestMerge(t *testing.T) {
	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			actual := linklist.Merge(tc.input)
			if !eq(actual, tc.output) {
				t.Errorf("lists are not equal: expected %s, actual %s", tc.output, actual)
			}
		})
	}
}
