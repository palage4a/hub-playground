package main_test

// import (
// 	"fmt"
// 	"testing"
// )

// type Broker interface {
// 	Publish(string, string) (string, error)
// }

// type Pool struct{}

// func (p *Pool) Publish(a, b string) (string, error) {
// 	return fmt.Sprintf("%s - %s", a, b), nil
// }

// func newPool() map[string]*Pool {
// 	a := map[string]*Pool{
// 		"key": &Pool{},
// 	}
// 	return a
// }

// func new(b map[string]Broker) error {
// 	return nil
// }

// func TestInterfaceCasting(t *testing.T) {
// 	a := newPool()
// 	// new(a)
// }
