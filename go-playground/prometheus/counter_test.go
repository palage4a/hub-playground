package prometheus

import (
	"testing"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	dto "github.com/prometheus/client_model/go"
	"github.com/stretchr/testify/assert"
)

func TestCounterVectorWrite(t *testing.T) {
	req := prometheus.NewRegistry()

	c := promauto.With(req).NewCounterVec(prometheus.CounterOpts{
		Name: "counter_total",
		Help: "help",
	}, []string{"code", "method"})

	for range 10 {
		c.WithLabelValues("404", "GET").Inc()
	}

	for range 20 {
		c.WithLabelValues("200", "POST").Inc()
	}

	metricCh := make(chan prometheus.Metric)
	go func() {
		c.Collect(metricCh)
		close(metricCh)
	}()

	for m := range metricCh {
		metric := dto.Metric{}
		m.Write(&metric)
		for _, l := range metric.Label {
			switch l.GetValue() {
			case "404":
				assert.Equal(t, float64(10), metric.GetCounter().GetValue())
			case "200":
				assert.Equal(t, float64(20), metric.GetCounter().GetValue())
			}
		}
	}
}

func payload() {
	var i uint64 = 0
	for range 1 << 10 {
		i += 1
	}
}

func BenchmarkCounterVectorWithLabelValuesInc(b *testing.B) {
	req := prometheus.NewRegistry()
	cv := promauto.With(req).NewCounterVec(prometheus.CounterOpts{
		Name: "counter_2_total",
		Help: "help",
	}, []string{"code", "success"})

	for range b.N {
		cv.WithLabelValues("200", "true").Inc()
	}
}

func BenchmarkCounterVectorWithLabelValuesIncAsync(b *testing.B) {
	req := prometheus.NewRegistry()
	cv := promauto.With(req).NewCounterVec(prometheus.CounterOpts{
		Name: "counter_2_total",
		Help: "help",
	}, []string{"code", "success"})

	for range b.N {
		go func() {
			cv.WithLabelValues("200", "true").Inc()
		}()
	}
}

func BenchmarkDebug(b *testing.B) {
	req := prometheus.NewRegistry()

	cv := promauto.With(req).NewCounterVec(prometheus.CounterOpts{
		Name: "counter_3_total",
		Help: "help",
	}, []string{"code"})

	r := promauto.With(req).NewCounter(prometheus.CounterOpts{
		Name: "req_total",
		Help: "help",
	})

	for range b.N {
		cv.WithLabelValues("200").Inc()
		r.Inc()
	}
}

func BenchmarkCounterVecInc(b *testing.B) {
	req := prometheus.NewRegistry()

	cv := promauto.With(req).NewCounterVec(prometheus.CounterOpts{
		Name: "counter_3_total",
		Help: "help",
	}, []string{"code"})

	c := cv.WithLabelValues("200")
	for range b.N {
		c.Inc()
	}
}

func BenchmarkCounterInc(b *testing.B) {
	req := prometheus.NewRegistry()

	r := promauto.With(req).NewCounter(prometheus.CounterOpts{
		Name: "req_total",
		Help: "help",
	})

	for range b.N {
		r.Inc()
	}
}

func BenchmarkCounterAdd(b *testing.B) {
	req := prometheus.NewRegistry()

	c := promauto.With(req).NewCounter(prometheus.CounterOpts{
		Name: "counter_total",
		Help: "help",
	})

	for range b.N {
		c.Add(float64(1))
	}
}

// BenchmarkCounterInc10-12    	62908081	        19.01 ns/op	       0 B/op	       0 allocs/op
func BenchmarkCounterInc10(b *testing.B) {
	req := prometheus.NewRegistry()

	r := promauto.With(req).NewCounter(prometheus.CounterOpts{
		Name: "req_total",
		Help: "help",
	})

	for range b.N {
		for range 10 {
			r.Inc()
		}
	}
}

// BenchmarkCounterAdd10-12    	595445830	         1.951 ns/op	       0 B/op	       0 allocs/op
func BenchmarkCounterAdd10(b *testing.B) {
	req := prometheus.NewRegistry()

	c := promauto.With(req).NewCounter(prometheus.CounterOpts{
		Name: "counter_total",
		Help: "help",
	})

	for range b.N {
		c.Add(float64(10))
	}
}
