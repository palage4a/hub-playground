package main

import (
	"fmt"
	"net/url"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestUrlParseTcp(t *testing.T) {
	u := "https://debug.test.asga.privet:5000/asdfas/fadsfas?asdfas=asfddas&asdf=fdasf"

	v, err := url.Parse(u)
	if err != nil {
		t.Errorf("failed to parse uri")
	}
	assert.Equal(t, "debug.test.asga.privet:5000", v.Host)
}

func TestUrlParseUnix(t *testing.T) {
	for _, tc := range []struct {
		input string
	}{
		{"unix:///tmp/test.sock"},
		{"unix://tmp/test.sock"},
		{"unix://./tmp/test.sock"},
		{"unix://../tmp/test.sock"},
		{"unix:./tmp/test.sock"},
		{"unix:/tmp/test.sock"},
	} {
		t.Run(fmt.Sprintf("%s", tc.input), func(t *testing.T) {
			v, err := url.Parse(tc.input)
			if err != nil {
				t.Errorf("failed to parse uri")
			}

			path := strings.Split(tc.input, "://")

			assert.Equal(t, 2, len(path))
			assert.Equal(t, "asdf;lkasjfl", v)
		})
	}

}
