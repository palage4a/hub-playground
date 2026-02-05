package main_test

import (
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
	"github.com/stretchr/testify/assert"
	"github.com/tarantool/go-tarantool/v2"
)

func compareRequests(t *testing.T, f, s any) {
	t.Helper()

	/*
	   switch ty := first.(type) {
	   case *tarantool.SelectRequest:
	       first = first.(*tarantool.SelectRequest)
	       second = second.(*tarantool.SelectRequest)
	   case *tarantool.CallRequest:
	       first = first.(*tarantool.CallRequest)
	       second = second.(*tarantool.CallRequest)
	   default:
	       t.Errorf("%v", ty)
	   }
	*/

	first := f.(*tarantool.CallRequest)
	second := s.(*tarantool.CallRequest)

	if diff := cmp.Diff(first, second, cmp.AllowUnexported(*first), cmpopts.IgnoreFields(*first, "baseRequest")); diff != "" {
		t.Error(diff)
	}
}

func TestGoCmp(t *testing.T) {
	req1 := tarantool.NewCallRequest("debug").Args([]any{2, 3, "debug"})
	req2 := tarantool.NewCallRequest("adfafaf").Args([]any{2, 3, "debug"})

	assert.NotEqual(t, req1, req2)

	// compareRequests(t, req1, req2)
}
