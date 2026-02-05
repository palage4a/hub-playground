package main

import (
	"fmt"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// func main() {
// 	config := zap.NewDevelopmentConfig()
// 	config.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
// 	logger, _ := config.Build()

// 	sugar := logger.Sugar()

// 	defer logger.Sync() // flushes buffer, if any

// 	url := "asdfd://localhost"
// 	sugar.Infow("sugar: failed to fetch URL",
// 		// Structured context as loosely typed key-value pairs.
// 		"url", url,
// 		"attempt", 3,
// 		"attempt", 5,
// 		"backoff", time.Second,
// 	)

// 	sugar.Debugw("sugar: failed to fetch URL",
// 		// Structured context as loosely typed key-value pairs.
// 		"url", url,
// 		"attempt", 3,
// 		"attempt", 5,
// 		"backoff", time.Second,
// 	)

// 	sugar.Warnw("sugar: failed to fetch URL",
// 		// Structured context as loosely typed key-value pairs.
// 		"url", url,
// 		"attempt", 3,
// 		"attempt", 5,
// 		"backoff", time.Second,
// 	)

// 	sugar.Error("sugar: failed to fetch URL",
// 		// Structured context as loosely typed key-value pairs.
// 		"url", url,
// 		"attempt", 3,
// 		"attempt", 5,
// 		"backoff", time.Second,
// 	)

// 	sugar.Fatalw("sugar: failed to fetch URL",
// 		// Structured context as loosely typed key-value pairs.
// 		"url", url,
// 		"attempt", 3,
// 		"attempt", 5,
// 		"backoff", time.Second,
// 	)

// }

func main() {
	encConfig := zap.NewProductionEncoderConfig()

	enc := zapcore.NewJSONEncoder(encConfig)

	// sink := zapcore.AddSync(&lumberjack.Logger{
	// 	Filename:   "app.jsonl",
	// 	MaxSize:    1, // megabytes
	// 	MaxBackups: 3,
	// 	MaxAge:     1, // days
	// 	Compress:   true,
	// })

	sink, closeSink, err := zap.Open("app.jsonl")
	if err != nil {
		closeSink()
		panic(err)
	}

	lvl, err := zapcore.ParseLevel("debug")
	if err != nil {
		fmt.Println("can not parse logging level; continue with default info-level")
		lvl = zap.InfoLevel
	}

	logger := zap.New(
		zapcore.NewCore(enc, sink, lvl),
	)

	for i := 0; i < 100000; i++ {
		logger.Sugar().Infow("debug message", "i", i)
		logger.Sugar().Errorw("error message", "i", i)
	}
}
