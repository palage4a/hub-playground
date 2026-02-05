package main

// import "fmt"

// func generic[T n](x, y T) T {
// 	return x + y
// }

// type n interface {
// 	int | float64
// }

// type N[T any] interface {
// 	Ret() T
// }

// type intN struct {
// 	a int
// }

// func (s intN) Ret() int {
// 	return s.a
// }

// func debugInt(a N[int]) int {
// 	return a.Ret()
// }

// type stringN struct {
// 	a string
// }

// func (s stringN) Ret() string {
// 	return s.a
// }

// func debugString(a N[string]) string {
// 	return a.Ret()
// }

// func main() {
// 	// gInt := generic[int]
// 	// resInt := gInt(1, 2)
// 	// fmt.Println(resInt)

// 	// gFloat := generic[float64]
// 	// resFloat := gFloat(2, 1)
// 	// fmt.Println(resFloat)

// 	// resOnlyInt := generic(1, 3)
// 	// fmt.Println(resOnlyInt)

// 	// resOnlyFloat := generic(1.1, 2.2)
// 	// fmt.Println(resOnlyFloat)

// 	sInst := intN{2}
// 	resInt := debugInt(sInst)
// 	fmt.Println(resInt)

// 	sString := stringN{"debug"}
// 	resString := debugString(sString)
// 	fmt.Println(resString)
// }
