package aoc_test

import (
	"io"
	"os"
	"testing"

	"github.com/palage4a/go-playground/aoc"
)

func TestCaclSum(t *testing.T) {
	testData := `1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet
`
	if res := aoc.First(testData); res != 142 {
		t.Errorf("wrong result: expected 142, actual %d", res)
	}

	fd, err := os.Open("testdata/first.txt")
	if err != nil {
		t.Fatalf("%s", err)
	}
	defer fd.Close()

	td, err := io.ReadAll(fd)
	if err != nil {
		t.Fatalf("%s", err)
	}

	if res := aoc.First(string(td)); res != 55607 {
		t.Errorf("wrong result: expected 55607, actual %d", res)
	}
}
