package observer

// Core 1
type Observer interface {
	Update()
}

// Core 2
type Notifier interface {
	Observe(...Observer)
	Notify()
}

type BaseLogger struct {
	clicker *SimpleClicker
}

func (bl *BaseLogger) SetClicker(c *SimpleClicker) {
	bl.clicker = c
}

type InfoLogger struct {
	BaseLogger
	info int
}

func (l *InfoLogger) Update() {
	l.info++
}

func (l *InfoLogger) Counter() int {
	return l.info
}

type DebugLogger struct {
	BaseLogger
	debug int
}

func (l *DebugLogger) Update() {
	l.debug++
}

func (l *DebugLogger) Counter() int {
	return l.debug
}

type SimpleClicker struct {
	obs []Observer
}

func (st *SimpleClicker) Observe(o ...Observer) {
	st.obs = append(st.obs, o...)
}

func (st *SimpleClicker) Silence() {
	st.obs = make([]Observer, 0)
}

func (st *SimpleClicker) Notify() {
	for _, o := range st.obs {
		o.Update()
	}
}

func (st *SimpleClicker) Click(n int) {
	for i := 0; i < n; i++ {
		st.Notify()
	}
}
