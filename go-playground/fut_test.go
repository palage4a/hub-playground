package main_test

// import (
// 	"testing"
// 	"bytes"
// 	"io"
// 	"context"

// 	"github.com/vmihailenco/msgpack/v5"
// 	"github.com/tarantool/go-tarantool/v2"
// 	"github.com/tarantool/go-iproto"

// )

// type futureMockRequest struct {
// }

// func (req *futureMockRequest) Type() iproto.Type {
// 	return iproto.Type(0)
// }

// func (req *futureMockRequest) Async() bool {
// 	return false
// }

// func (req *futureMockRequest) Body(resolver tarantool.SchemaResolver, enc *msgpack.Encoder) error {
// 	return nil
// }

// func (req *futureMockRequest) Conn() *tarantool.Connection {
// 	return &tarantool.Connection{}
// }

// func (req *futureMockRequest) Ctx() context.Context {
// 	return nil
// }

// func (req *futureMockRequest) Response(header tarantool.Header, body io.Reader) (tarantool.Response, error) {
// 	resp, err := createFutureMockResponse(header, body)
// 	return resp, err
// }

// type futureMockResponse struct {
// 	header tarantool.Header
// 	data   []byte

// 	decodeCnt      int
// 	decodeTypedCnt int
// }

// func (resp *futureMockResponse) Header() tarantool.Header {
// 	return resp.header
// }

// func (resp *futureMockResponse) Decode() ([]interface{}, error) {
// 	resp.decodeCnt++

// 	dataInt := make([]interface{}, len(resp.data))
// 	for i := range resp.data {
// 		dataInt[i] = resp.data[i]
// 	}
// 	return dataInt, nil
// }

// func (resp *futureMockResponse) DecodeTyped(res interface{}) error {
// 	resp.decodeTypedCnt++
// 	return nil
// }

// func createFutureMockResponse(header tarantool.Header, body io.Reader) (tarantool.Response, error) {
// 	data, err := io.ReadAll(body)
// 	if err != nil {
// 		return nil, err
// 	}
// 	return &futureMockResponse{header: header, data: data}, nil
// }

// func TestFuture_GetTyped(t *testing.T) {
// 	fut := tarantool.NewFuture(tarantool.NewEvalRequest(""))

// 	fut.SetResponse(tarantool.Header{}, bytes.NewReader([]byte{'v', '2'}))

// 	resp, err := fut.GetResponse()
// 	if err != nil {
// 		t.Error(err)
// 	}
//     t.Error(resp)

// 	var data []byte

// 	err = fut.GetTyped(&data)
// 	if err != nil {
// 		t.Error(err)
// 	}
//     t.Error(data)
// }

// func TestDebug(t *testing.T) {
//     t.Skip()

// 	tntReq := tarantool.NewCallRequest("queue.publish").Args([]any{1,2})

// 	fut := tarantool.NewFuture(tntReq)

// 	body := []byte{'1', '2'}

// 	buf := new(bytes.Buffer)
// 	enc := msgpack.NewEncoder(buf)

// 	err := enc.Encode(body)
// 	if err != nil {
// 		t.Errorf("unexpected error while encoding: %s", err)
// 	}

// 	fut.SetResponse(tarantool.Header{}, buf)

// 	t.Error(fut.Get())

// 	var resp []byte

// 	err = fut.GetTyped(&resp)
// 	if err != nil {
// 		t.Error(err)
// 	}

// 	t.Error(resp)
// }
