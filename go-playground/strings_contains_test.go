package main

import (
    "testing"
    "strings"
    "errors"
)


func TestStringsContains(t *testing.T) {
    str := "tarantool: tarantool error when sfdlkjadslfkjaslfkjalkfjlk jdflkjsaflkjas"
    substr := "tarantool error"
    
    res := strings.Contains(str, substr)
    if res != true {
        t.Errorf("must return true, actual %v", res)
    }
}

func TestStringsContainsInErrors(t *testing.T) {
    err := errors.New("tarantool: tarantool error when sfdlkjadslfkjaslfkjalkfjlk jdflkjsaflkjas")
    suberr := errors.New("tarantool error")
    
    res := strings.Contains(err.Error(), suberr.Error())
    if res != true {
        t.Errorf("must return true, actual %v", res)
    }
}


