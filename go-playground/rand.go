package main

import (
	"crypto/rand"
	"flag"
	"fmt"
	"log"
	"time"
)

func ByteCountIEC(b int64) string {
	const unit = 1024
	if b < unit {
		return fmt.Sprintf("%d B", b)
	}
	div, exp := int64(unit), 0
	for n := b / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %ciB",
		float64(b)/float64(div), "KMGTPE"[exp])
}

var dFlag = flag.Duration("d", time.Second*1, "test case duration")

func main() {
	flag.Parse()
	for i := 0; i < 31; i++ {
		fmt.Println("test case: ", ByteCountIEC(1<<i))
		start := time.Now()
		read := int64(0)
		timer := time.NewTimer(*dFlag)
		latencySum := time.Duration(0)
		counter := int64(0)
		for {
			select {
			case <-timer.C:
				goto end
			default:
			}

			buf := make([]byte, 1<<i)
			readStart := time.Now()
			n, err := rand.Read(buf)
			latencySum += time.Duration(time.Since(readStart).Nanoseconds())
			if n != 1<<i {
				log.Fatalf("wrong read bytes: expected %d, actual %d", i<<i, n)
			}
			if err != nil {
				log.Fatal(err)
			}

			counter += 1
			read += int64(n)
		}

	end:
		duration := time.Since(start)
		fmt.Printf("test duration: %s\n", duration)
		fmt.Printf("avg latency: %s\n", time.Duration(latencySum.Nanoseconds()/counter))
		fmt.Printf("read: %s\n", ByteCountIEC(int64(read)))
		fmt.Printf("throughput: %s/s\n\n", ByteCountIEC(read/int64(duration.Seconds())))
	}
}
