package aoc

import (
    "strings"
    "strconv"
    "fmt"
)

func First(s string) int {
    lines := strings.Split(s, "\n")
    sum := 0
    for _, s := range lines {
        head, tail := 0, 0 
        for _, c := range s {
            n, err := strconv.Atoi(string(c))
            if err != nil {
                continue
            }
            if head == 0 {
                head = n
            }
            tail = n
        }
        inc, err := strconv.Atoi(fmt.Sprintf("%d%d", head, tail))
        if err != nil {
            fmt.Printf("strconv.Atoi err: %s\n", err)
            return 0
        }
        sum += inc
    }

    return sum
}
