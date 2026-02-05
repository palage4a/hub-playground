package main

import "fmt"

type CallResp interface {
	int32 | []int32 | string
}

type TntCaller[T CallResp] interface {
	Call(userMode string, name string, args ...any) (*T, error)
	// CallRW(name string, args ...any) (*T, error)
	// CallRO(name string, args ...any) (*T, error)
}

type TntPool[T CallResp] struct {
}

func (t *TntPool[int32]) Call(userMode string, name string, args ...any) (int32, error) {
	return 1, nil
}

func (t *TntPool[string]) Call(userMode string, name string, args ...any) (string, error) {
	return "sdfasf", nil
}

func DebugGeneric() {
	a := TntPool[int32]{}
	fmt.Println(a.Call("asdfaf", "adfaf", "dafdasfd"))
}
