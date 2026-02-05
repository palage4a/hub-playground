package main

import (
	"os"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func main() {

	// logger := zerolog.New(zerolog.ConsoleWriter{
	// 	Out: os.Stderr,
	// }).With().Timestamp().Logger()

	// logger.Error().Msg("E level")
	// logger.Warn().Msg("W level")
	// logger.Info().Msg("I level")
	// logger.Debug().Msg("D level")
	// logger.Trace().Msg("T level")

	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stdout})
	log.Error().Msg("E level")
	log.Warn().Msg("W level")
	log.Info().Msg("I level")
	log.Debug().Msg("D level")
	log.Trace().Msg("T level")

	log.Println("println debug")
	log.Printf("printf debug: %s", "str")

	return
}
