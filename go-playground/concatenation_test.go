package main_test

import (
	"fmt"
	"strconv"
	"strings"
	"testing"
)

var tcs = []struct {
	a string
	b string
}{
	{"log", "debug"},
}

func BenchmarkSprintf(b *testing.B) {
	for i, tc := range tcs {
		b.Run(strconv.FormatInt(int64(i), 10), func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				_ = fmt.Sprintf("%s+%s", tc.a, tc.b)
			}
		})
	}
}

func BenchmarkStringsConcat(b *testing.B) {
	for i, tc := range tcs {
		b.Run(strconv.FormatInt(int64(i), 10), func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				_ = strings.Join([]string{tc.a, tc.b}, "+")
			}
		})
	}
}

var errTcs = []struct {
	fmtString string
	args      []string
}{
	{"error", nil},
	{"error %s", []string{"a"}},
	{"error %s %s", []string{"a", "b"}},
	{"error %s %s %s %s", []string{"a", "b", "c", "d"}},
}

func BenchmarkFmtErrorf(b *testing.B) {
	for i, tc := range errTcs {
		b.Run(strconv.FormatInt(int64(i), 10), func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				_ = fmt.Errorf(tc.fmtString, tc.args)
			}
		})
	}
}

type DebugError struct {
	msg string
}

func (d *DebugError) Error() string {
	return d.msg
}

func BenchmarkErrorsNew(b *testing.B) {
	var err error
	err = &DebugError{"msg"}
	for i := 0; i < b.N; i++ {
		_ = err.Error()
	}
}

func BenchmarkErrorSprintf(b *testing.B) {
	var err error
	err = &DebugError{"msg"}

	for i := 0; i < b.N; i++ {
		_ = fmt.Sprintf("%s", err)
	}
}
