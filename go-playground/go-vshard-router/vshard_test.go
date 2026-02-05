package example_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"math/rand"

	"github.com/spf13/viper"
	_ "github.com/spf13/viper/remote"
	"github.com/stretchr/testify/require"
	"github.com/tarantool/go-tarantool/v2"
	vshard "github.com/tarantool/go-vshard-router"
	viperProvider "github.com/tarantool/go-vshard-router/providers/viper"
)

func generateRandomUint32() uint32 {
	return uint32(rand.Int31())
}

type User struct {
	Id       uint32 `msgpack:"id"`
	BucketID uint64 `msgpack:"bucket_id"`
	Name     string `msgpack:"name"`
	Age      int    `msgpack:"age"`
}

type TarantoolUser struct {
	Name     string
	Password string
}

func getTarantoolUsers(v *viper.Viper) (map[string]TarantoolUser, error) {
	users := make(map[string]TarantoolUser)
	err := v.UnmarshalKey("credentials.users", &users)
	if err != nil {
		return nil, err
	}
	return users, nil
}

func getTarantoolUserByName(v *viper.Viper, name string) (*TarantoolUser, error) {
	users, err := getTarantoolUsers(v)
	if err != nil {
		return nil, err
	}
	for username, user := range users {
		if username == name {
			user.Name = username
			return &user, nil
		}
	}
	return nil, fmt.Errorf("Пользователь с именем %s не найден", name)
}

func TestDebugVshardRouterWithEtcd(t *testing.T) {
	ctx := context.Background()

	v := viper.New()
	v.SetConfigType("yaml")
	v.AddRemoteProvider("etcd3", "localhost:2379", "/etcd-config/app/config/all")

	err := v.ReadRemoteConfig()
	require.NoError(t, err)

	provider := viperProvider.NewProvider(ctx, v, viperProvider.ConfigTypeTarantool3)
	require.NotNil(t, provider)

	vshardUser, err := getTarantoolUserByName(v, "client")
	require.NoError(t, err)
	routerConfig := vshard.Config{
		TopologyProvider: provider,
		TotalBucketCount: v.GetUint64("sharding.bucket_count"),
		User:             vshardUser.Name,
		Password:         vshardUser.Password,
	}

	router, err := vshard.NewRouter(ctx, routerConfig)
	require.Nil(t, err)

	t.Logf("%v\n", router.RouteAll())

	username := "Ivan"
	bucketID := router.BucketIDStrCRC32(username)

	user := User{
		Id:       generateRandomUint32(),
		BucketID: bucketID,
		Name:     username,
		Age:      13,
	}
	_, err = router.Call(
		ctx,
		bucketID,
		vshard.CallModeRW,
		"put",
		[]any{user.Id, user.BucketID, user.Name, user.Age},
		vshard.CallOpts{
			Timeout: time.Second,
		},
	)
	require.Nil(t, err)

	resp, err := router.Call(
		ctx,
		bucketID,
		vshard.CallModeRW,
		"get",
		[]any{user.Id},
		vshard.CallOpts{
			Timeout: time.Second * 1,
		},
	)
	require.Nil(t, err)

	untypedRes, err := resp.Get()
	require.Nil(t, err)
	t.Logf("%v\n", untypedRes)

	var u User // Why it requires slice of User?
	err = resp.GetTyped(&u)
	require.Nil(t, err)

	t.Logf("%v\n", u)
}

func TestDebugVshardRouterWithEtcdCallAsync(t *testing.T) {
	ctx := context.Background()

	v := viper.New()
	v.SetConfigType("yaml")
	v.AddRemoteProvider("etcd3", "localhost:2379", "/etcd-config/app/config/all")

	err := v.ReadRemoteConfig()
	require.NoError(t, err)

	provider := viperProvider.NewProvider(ctx, v, viperProvider.ConfigTypeTarantool3)
	require.NotNil(t, provider)

	vshardUser, err := getTarantoolUserByName(v, "client")
	require.NoError(t, err)
	routerConfig := vshard.Config{
		TopologyProvider: provider,
		TotalBucketCount: v.GetUint64("sharding.bucket_count"),
		User:             vshardUser.Name,
		Password:         vshardUser.Password,
	}

	router, err := vshard.NewRouter(ctx, routerConfig)
	require.Nil(t, err)

	t.Logf("%v\n", router.RouteAll())

	username := "Ivan"
	bucketID := router.BucketIDStrCRC32(username)

	user := User{
		Id:       generateRandomUint32(),
		BucketID: bucketID,
		Name:     username,
		Age:      13,
	}
	_, err = router.Call(
		ctx,
		bucketID,
		vshard.CallModeRW,
		"put",
		[]any{user.Id, user.BucketID, user.Name, user.Age},
		vshard.CallOpts{
			Timeout: time.Second,
		},
	)
	require.Nil(t, err)

	rs, err := router.Route(ctx, bucketID)
	require.Nil(t, err)

	fut := rs.CallAsync(ctx, vshard.ReplicasetCallOpts{Timeout: time.Second}, "get", []any{user.Id})
	require.Nil(t, err)

	require.Nil(t, err)

	var u User // Why it requires slice of User?
	err = fut.GetTyped(&u)
	require.Nil(t, err)

	t.Logf("%v\n", u)
}

func TestIDebugGet(t *testing.T) {
	ctx := context.Background()

	v := viper.New()
	v.SetConfigType("yaml")
	v.AddRemoteProvider("etcd3", "localhost:2379", "/etcd-config/app/config/all")

	err := v.ReadRemoteConfig()
	require.NoError(t, err)

	vshardUser, err := getTarantoolUserByName(v, "client")
	require.NoError(t, err)

	dialer := tarantool.NetDialer{
		Address:  "localhost:3301",
		User:     vshardUser.Name,
		Password: vshardUser.Password,
	}

	con, err := tarantool.Connect(ctx, dialer, tarantool.Opts{})
	require.NoError(t, err)

	username := "Ivan"
	bucketID := uint64(1)

	user := User{
		Id:       generateRandomUint32(),
		BucketID: bucketID,
		Name:     username,
		Age:      13,
	}

	req := tarantool.NewCallRequest("put").Args([]any{user.Id, user.BucketID, user.Name, user.Age})
	fut := con.Do(req)

	untypedRes, err := fut.Get()
	require.Nil(t, err)
	t.Logf("%v\n", untypedRes)

	var u User
	err = fut.GetTyped(&u)
	require.Nil(t, err)
	t.Logf("%v\n", u)

	req = tarantool.NewCallRequest("get").Args([]any{user.Id})
	fut = con.Do(req)

	untypedRes, err = fut.Get()
	require.Nil(t, err)
	t.Logf("%v\n", untypedRes)

	err = fut.GetTyped(&u)
	require.Nil(t, err)
	t.Logf("%v\n", u)
}
