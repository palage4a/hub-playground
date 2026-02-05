package main

import (
	"fmt"
	"os"
)

func readRandom(c int) ([]byte, error) {
	file, err := os.Open("/dev/urandom")
	if err != nil {
		return nil, err
	}

	buf := make([]byte, c)
	_, err = file.Read(buf)
	if err != nil {
		return nil, err
	}

	return buf, nil
}

func ReadFromRandom() {
	b, err := readRandom(1000)
	if err != nil {
		fmt.Printf("%s", err)
	}

	fmt.Printf("Read %d bytes:\n", len(b))
	fmt.Printf("%s\n", b)

	addr := "debug"
	socketAddr := fmt.Sprintf("@%v", addr)

	fmt.Printf("%s\n", socketAddr)

	return
}
