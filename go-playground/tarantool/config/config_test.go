package config_test

import (
	"path/filepath"
	"testing"

	"github.com/spf13/viper"
	"github.com/stretchr/testify/require"

	"github.com/tarantool/tt/lib/cluster"
)

func TestDataCollectorFactorys_NewFile_valid(t *testing.T) {
	testYamlPath := filepath.Join("testdata", "config.yml")
	factory := cluster.NewDataCollectorFactory()

	collector, err := factory.NewFile(testYamlPath)
	require.NoError(t, err)

	data, err := collector.Collect()
	require.NoError(t, err)

	c := cluster.NewYamlDataMergeCollector(data...)
	require.NoError(t, err)

	config, err := c.Collect()
	require.NoError(t, err)

	grpc, err := config.Get([]string{"roles_cfg", "app.roles.grpc"})
	require.NoError(t, err)
	require.Equal(t, "", grpc)

	cfg, err := cluster.MakeClusterConfig(config)
	require.NoError(t, err)

	require.Equal(t, "", cfg.Groups["app"].Replicasets["app"])
}

func TestGrpcConfigurationFromCluster(t *testing.T) {
	testYamlPath := filepath.Join("testdata", "config.yml")

	v := viper.New()
	v.SetConfigFile(testYamlPath)
	v.SetConfigType("yaml")
	err := v.ReadInConfig()
	require.NoError(t, err)

	grpcConfig := v.Get("roles_cfg.app.roles.grpc")

	require.Equal(t, "", grpcConfig)
}
