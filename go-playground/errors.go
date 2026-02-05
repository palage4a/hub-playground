package main

import (
	"errors"
	"fmt"
)

func Close() error {
	r := map[string]map[string][]error{
		"queue": {
			"a": []error{errors.New("1"), errors.New("2")},
		},
		"archive": {
			"a": []error{errors.New("1"), errors.New("2")},
			"b": []error{},
			"c": []error{errors.New("3"), errors.New("4")},
		},
		"debug":   nil,
		"another": nil,
	}

	gerrs := make([]error, 0)

	for queue, qp := range r {
		for shard, errs := range qp {
			var err error
			if len(errs) != 0 {
				joinedErrs := errors.Join(errs...)
				err = fmt.Errorf("%s<%s>:\n%w", queue, shard, joinedErrs)
				gerrs = append(gerrs, err)
			}
		}
	}

	return errors.Join(gerrs...)
}

func ErrorsDebug() {
	//err := errors.New("queue error:")
	// var err error

	// errs := []error{errors.New("a"), errors.New("b")}
	// var errs []error
	// errs := []error{}

	/*
	   var newerr error
	   if len(errs) > 0 {
	       newerr = fmt.Errorf("%w\n%w", err, errors.Join(errs...))
	   } else {
	       newerr = fmt.Errorf("%w", err)
	   }
	*/

	err := Close()

	fmt.Printf("db close connections:\n%s", err)
}
