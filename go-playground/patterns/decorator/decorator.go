package decorator

import (
	"strings"
)

type Logger interface {
	Log(msg string) string
}

type Log struct{}

func (l *Log) Log(s string) string {
	return s
}

type DebugLog struct {
	s *Log
}

func NewDebugLog(s *Log) *DebugLog {
	return &DebugLog{
		s,
	}
}

func (l *DebugLog) Log(s string) string {
	return strings.Join([]string{"DEBUG:", s}, " ")
}

type InfoLog struct {
	s *Log
}

func NewInfoLog(s *Log) *InfoLog {
	return &InfoLog{
		s,
	}
}

func (l *InfoLog) Log(s string) string {
	return strings.Join([]string{"INFO:", s}, " ")
}
