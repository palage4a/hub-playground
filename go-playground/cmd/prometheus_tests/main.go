package main

import (
	"fmt"

	"github.com/prometheus/client_golang/prometheus"
)

func main() {
	exp := prometheus.ExponentialBuckets(0.001, 2, 11)
	exp_r := prometheus.ExponentialBucketsRange(0.001, 1, 20)

	lin := append(append(
		prometheus.LinearBuckets(0.001, 0.01, 5),
		prometheus.LinearBuckets(0.1, 0.1, 5)...),
		prometheus.LinearBuckets(1, 1, 5)...)

	// Ilya's variant
	custom := []float64{0.001, 0.005, 0.01, 0.02, 0.5, 0.1, 0.5, 1}

	fmt.Printf("Exp: %g\n", exp)
	fmt.Printf("Exp range: %g\n", exp_r)
	fmt.Printf("Linear: %g\n", lin)
	fmt.Printf("Custom: %g\n", custom)
}
