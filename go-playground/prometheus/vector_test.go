package prometheus_test

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	dto "github.com/prometheus/client_model/go"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestVectorWrite(t *testing.T) {
	req := prometheus.NewRegistry()

	c := promauto.With(req).NewCounterVec(prometheus.CounterOpts{
		Name: "counter_total",
		Help: "help",
	}, []string{"code", "success"})

	for range 5 {
		c.WithLabelValues("404", "false").Inc()
	}

	for range 10 {
		c.WithLabelValues("502", "false").Inc()
	}

	for range 30 {
		c.WithLabelValues("200", "true").Inc()
	}

	for range 5 {
		c.WithLabelValues("201", "true").Inc()
	}

	ch := make(chan prometheus.Metric)
	go func() {
		c.Collect(ch)
		close(ch)
	}()

	expectedFailed := float64(15)
	expectedSuccessed := float64(35)

	s := float64(0)
	f := float64(0)

	for metric := range ch {
		var m dto.Metric
		err := metric.Write(&m)
		assert.Nil(t, err)
		// t.Logf("%v\n", m)

		for _, l := range m.Label {
			if l.GetName() == "success" && l.GetValue() == "true" {
				s += m.GetCounter().GetValue()
			}

			if l.GetName() == "success" && l.GetValue() == "false" {
				f += m.GetCounter().GetValue()
			}
		}
	}

	assert.Equal(t, expectedSuccessed, s)
	assert.Equal(t, expectedFailed, f)
}
