package command

import (
	"sync/atomic"
)

type Command interface {
	Execute()
}

type Increment struct {
	i int32
}

func NewIncrement(i int32) *Increment {
	return &Increment{i}
}

func (i *Increment) Inc() {
	atomic.AddInt32(&i.i, 1)
}

func (i *Increment) Value() int32 {
	return atomic.LoadInt32(&i.i)
}

type IncrementCommand struct {
	i *Increment
}

func NewIncrementCommand(i *Increment) *IncrementCommand {
	return &IncrementCommand{i}
}

func (i *IncrementCommand) Execute() {
	i.i.Inc()
}
