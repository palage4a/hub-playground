package main

import (
	"context"
	"fmt"
	"math/rand/v2"
	"os"
	"strconv"
	"time"

	vshard "github.com/KaymeKaydex/go-vshard-router"
	"github.com/KaymeKaydex/go-vshard-router/providers/static"

	"github.com/google/uuid"
	"github.com/tarantool/go-tarantool/v2"
	"github.com/tarantool/go-tarantool/v2/pool"
)

type User struct {
	ID       uint64 `msgpack"id"`
	BucketID uint64 `msgpack:"bucket_id"`
	Name     string `msgpack:"name"`
	Age      int    `msgpack:"age"`
}

func main() {
	ctx := context.Background()

	r, err := vshard.NewRouter(ctx, vshard.Config{
		DiscoveryTimeout: time.Minute,
		DiscoveryMode:    vshard.DiscoveryModeOn,
		TopologyProvider: static.NewProvider(map[vshard.ReplicasetInfo][]vshard.InstanceInfo{
			vshard.ReplicasetInfo{
				Name:   "replcaset_1",
				UUID:   uuid.New(),
				Weight: 1,
			}: {
				{
					Addr: "localhost:3301",
					UUID: uuid.New(),
				},
				{
					Addr: "localhost:3302",
					UUID: uuid.New(),
				},
			},
			vshard.ReplicasetInfo{
				Name:   "replcaset_2",
				UUID:   uuid.New(),
				Weight: 1,
			}: {
				{
					Addr: "localhost:3303",
					UUID: uuid.New(),
				},
				{
					Addr: "localhost:3304",
					UUID: uuid.New(),
				},
			},
		}),
		User:             "client",
		Password:         "secret",
		TotalBucketCount: 3000,
		PoolOpts: tarantool.Opts{
			Timeout: time.Second,
		},
	})
	if err != nil {
		fmt.Printf("new router err: %s\n", err)
		os.Exit(1)
	}

	err = r.ClusterBootstrap(ctx, true)
	if err != nil {
		fmt.Printf("bootstrap err: %s\n", err)
		os.Exit(1)
	}

	user := User{
		ID:   rand.Uint64(),
		Name: "Ivan",
		Age:  10,
	}

	bucketID := r.RouterBucketIDStrCRC32(strconv.FormatUint(user.ID, 10))
	user.BucketID = bucketID
	if _, _, err := r.RouterCallImpl(
		ctx,
		bucketID,
		vshard.CallOpts{VshardMode: vshard.WriteMode, PoolMode: pool.RW, Timeout: time.Second * 2},
		"put",
		[]any{user.ID, user.BucketID, user.Name, user.Age},
	); err != nil {
		fmt.Printf("router put call err: %s\n", err)
		os.Exit(1)
	}

	res, getTyped, err := r.RouterCallImpl(
		ctx,
		bucketID,
		vshard.CallOpts{VshardMode: vshard.ReadMode, PoolMode: pool.PreferRO, Timeout: time.Second * 2},
		"get",
		[]any{user.ID},
	)
	if err != nil {
		fmt.Printf("router get call err: %s\n", err)
		os.Exit(1)
	}

	fmt.Printf("result: %v\n", res)
	var u User
	if err := getTyped(&u); err != nil {
		fmt.Printf("get typed err: %s\n", err)
		os.Exit(1)
	}

	fmt.Printf("typed result: %v\n", u)
}
