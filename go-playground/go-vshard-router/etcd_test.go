package example

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	clientv3 "go.etcd.io/etcd/client/v3"
)

func TestDebugEtcd(t *testing.T) {
	ctx := context.Background()
	// Конфигурация клиента
	cli, err := clientv3.New(clientv3.Config{
		Endpoints:   []string{"localhost:2379"}, // Адреса etcd серверов
		DialTimeout: 5 * time.Second,
	})
	require.NoError(t, err, "Не удалось создать клиента etcd")
	defer cli.Close()

	resp, err := cli.Get(ctx, "/etcd-config/app/config/all", clientv3.WithPrefix())
	require.NoError(t, err, "Ошибка при получении ключа из etcd")
	// Вывод значений
	if len(resp.Kvs) == 0 {
		t.Logf("Ключ 'key' не найден в etcd")
	} else {
		for _, kv := range resp.Kvs {
			t.Logf("%s : %s\n", kv.Key, kv.Value)
		}
	}
}
