package main_test

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"testing"

	ffaker "github.com/jaswdr/faker/v2"
)

// type Request struct {
// 	// Queue            string            `msgpack:"queue"`
// 	BucketId         uint64  `msgpack:"bucket_id"`
// 	RoutingKey       *string `msgpack:"routing_key"`
// 	ShardingKey      *string `msgpack:"sharding_key"`
// 	DeduplicationKey *string `msgpack:"deduplication_key"`
// 	// Payload          []byte            `msgpack:"payload"`
// 	Metadata map[string]string `msgpack:"metadata"`
// }

// type Request1 struct {
// 	// Queue            string            `msgpack:"queue" faker:"uuid_digit"`
// 	BucketId         uint64  `msgpack:"bucket_id"`
// 	RoutingKey       *string `msgpack:"routing_key" faker:"uuid_digit"`
// 	ShardingKey      *string `msgpack:"sharding_key" faker:"uuid_digit"`
// 	DeduplicationKey *string `msgpack:"deduplication_key" faker:"uuid_digit"`
// 	// Payload          []byte            `msgpack:"payload"`
// 	Metadata map[string]string `msgpack:"metadata" faker:"length=1"`
// }

// func BenchmarkFaker(b *testing.B) {
// 	// _ = faker.AddProvider("metadata", func(v reflect.Value) (interface{}, error) {
// 	// 	return map[string]string{
// 	// 		"x-timestamp": fmt.Sprintf("%d", time.Now().UnixNano()),
// 	// 	}, nil
// 	// })

// 	faker.SetRandomSource(mrand.NewSource(time.Now().UnixNano()))
// 	faker.SetCryptoSource(rand.Reader)
// 	for i := 0; i < b.N; i++ {
// 		a := Request1{}
// 		faker.FakeData(&a)
// 	}
// }

// func BenchmarkStruct(b *testing.B) {
// 	f := ffaker.New()
// 	for i := 0; i < b.N; i++ {
// 		a := Request{}
// 		f.Struct().Fill(&a)
// 	}
// }

// V4 returns a fake UUID version 4
func uuid(r io.Reader) (uuid string) {
	var uiq [16]byte
	_, err := io.ReadFull(r, uiq[:])
	if err != nil {
		panic(err)
	}
	uiq[6] = (uiq[6] & 0x0f) | 0x40 // Version 4
	uiq[8] = (uiq[8] & 0x3f) | 0x80 // Variant RFC4122
	return fmt.Sprintf("%x-%x-%x-%x-%x", uiq[0:4], uiq[4:6], uiq[6:8], uiq[8:10], uiq[10:])
}

func BenchmarkUuuid(b *testing.B) {
	f := ffaker.New()

	for i := 0; i < b.N; i++ {
		_ = f.UUID().V4()
	}

}

func BenchmarkBufferedUuuid(b *testing.B) {
	f, _ := os.Open("/dev/urandom")
	buf := make([]byte, 1<<10)
	_, err := io.ReadAll(f)
	if err != nil {
		b.Fail()
	}

	r := bytes.NewReader(buf)
	for i := 0; i < b.N; i++ {
		_ = uuid(r)
	}

}
