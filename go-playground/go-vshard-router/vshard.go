package example

import (
	"context"
	"errors"

	vshard "github.com/tarantool/go-vshard-router"
)

func SetupRouter(ctx context.Context, endpoints []string, path string) (*vshard.Router, error) {
	return nil, errors.New("SetupRouter is not implemented")
}
