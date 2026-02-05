package main_test

import (
	"context"
	"fmt"
	"log"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/tarantool/go-tarantool/v2"
	"github.com/vmihailenco/msgpack/v5"
)

type PublishResponse struct {
	Id    uint64
	Error *tarantool.BoxError
}

// func (c *Tuple2) EncodeMsgpack(e *msgpack.Encoder) error {
// 	if err := e.EncodeArrayLen(2); err != nil {
// 		return err
// 	}
// 	if err := e.EncodeUint(uint64(c.Id)); err != nil {
// 		return err
// 	}
// 	var be tarantool.BoxError
// 	if err := e.Encode(be); err != nil {
// 		return err
// 	}

// 	return nil
// }

func (c *PublishResponse) DecodeMsgpack(d *msgpack.Decoder) error {
	var err error
	var l int
	if l, err = d.DecodeArrayLen(); err != nil {
		log.Printf("decode array len: %s", err)
		return err
	}
	if c.Id, err = d.DecodeUint64(); err != nil {
		log.Printf("decode uint: %s", err)
		return err
	}
	if l == 1 {
		return nil
	}
	var be tarantool.BoxError
	if err = d.Decode(&be); err != nil {
		return err
	}

	c.Error = &be

	return nil
}

type PublishArgs struct {
	Queue            string            `msgpack:"queue"`
	RoutingKey       *string           `msgpack:"routing_key"`
	ShardingKey      *string           `msgpack:"sharding_key"`
	DeduplicationKey *string           `msgpack:"deduplication_key"`
	Payload          []byte            `msgpack:"payload"`
	Metadata         map[string]string `msgpack:"metadata"`
}

func TestArrayEncoding(t *testing.T) {
	t.Skip()

	dialer := tarantool.NetDialer{
		Address:  "127.0.0.1:3301",
		User:     "user",
		Password: "pass",
	}
	opts := tarantool.Opts{}
	ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
	conn, err := tarantool.Connect(ctx, dialer, opts)
	cancel()
	if err != nil {
		t.Fatalf("Failed to connect: %s", err.Error())
	}

	var res PublishResponse
	req := &PublishArgs{
		Queue:   "queue",
		Payload: []byte("debug"),
	}
	callReq := tarantool.NewCallRequest("storage.api_publish").
		Args([]any{req.Queue, req})
	err = conn.Do(callReq).GetTyped(&res)
	if err != nil {
		t.Fatalf("Failed to storage.api_publish: %s", err.Error())
		return
	}
	assert.Less(t, uint64(0), res.Id)
	assert.Nil(t, res.Error)
}

func TestArrayEncodingDeduplication(t *testing.T) {
	t.Skip()

	dialer := tarantool.NetDialer{
		Address:  "127.0.0.1:3301",
		User:     "user",
		Password: "pass",
	}
	opts := tarantool.Opts{}
	ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
	conn, err := tarantool.Connect(ctx, dialer, opts)
	cancel()
	if err != nil {
		t.Fatalf("Failed to connect: %s", err.Error())
	}

	var res PublishResponse
	dk := "cxvczx"
	req := &PublishArgs{
		Queue:            "queue",
		DeduplicationKey: &dk,
		Payload:          []byte("debug"),
	}
	callReq := tarantool.NewCallRequest("storage.api_publish").
		Args([]any{req.Queue, req})
	err = conn.Do(callReq).GetTyped(&res)
	if err != nil {
		t.Fatalf("Failed to storage.api_publish: %s", err.Error())
		return
	}
	assert.Equal(t, uint64(0), res.Id)
	assert.Equal(t, fmt.Sprintf("deduplication_key '%s' is found", dk), res.Error.Msg)
}

func TestArrayEncodingPaylodNotFound(t *testing.T) {
	t.Skip()

	dialer := tarantool.NetDialer{
		Address:  "127.0.0.1:3301",
		User:     "user",
		Password: "pass",
	}
	opts := tarantool.Opts{}
	ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
	conn, err := tarantool.Connect(ctx, dialer, opts)
	cancel()
	if err != nil {
		t.Fatalf("Failed to connect: %s", err.Error())
	}

	var res PublishResponse
	req := &PublishArgs{
		Queue: "queue",
	}
	callReq := tarantool.NewCallRequest("storage.api_publish").
		Args([]any{req.Queue, req})
	err = conn.Do(callReq).GetTyped(&res)

	assert.Equal(t, uint64(0), res.Id)
	assert.NotNil(t, err)
}
