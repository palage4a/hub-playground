package cor

import "fmt"

// Core
type A interface {
	SetNext(A)
	Execute(int) string
}

type BaseA struct {
	next A
}

func (b *BaseA) SetNext(a A) {
	b.next = a
}

func (b *BaseA) Execute(i int) string {
	if b.next != nil {
		return b.next.Execute(i)
	}

	return fmt.Sprintf("BaseA %d", i)
}

type A1 struct {
	BaseA
}

func (a *A1) Execute(i int) string {
	if i == 1 {
		return fmt.Sprintf("A1 %d", i)
	}

	return a.BaseA.Execute(i)
}

type A2 struct {
	BaseA
}

func (a *A2) Execute(i int) string {
	if i == 2 {
		return fmt.Sprintf("A2 %d", i)
	}

	return a.BaseA.Execute(i)
}

type A3 struct {
	BaseA
}

func (a *A3) Execute(i int) string {
	if i == 3 {
		return fmt.Sprintf("A3 %d", i)
	}

	return a.BaseA.Execute(i)
}
