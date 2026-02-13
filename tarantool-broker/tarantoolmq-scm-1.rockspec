package = "tarantoolmq"
version = "0.1.0-1"
source = {
    url = "git+https://github.com/example/tarantoolmq.git",
}
dependencies = {
    "tarantool >= 3.0.0",
    "http >= 1.1.0",
    "queue >= 1.1.0",
}
build = {
    type = "builtin";
    modules = {
        ["tarantoolmq"] = "tarantoolmq.lua",
        ["tarantoolmq.internal.config"] = "internal/config.lua",
        ["tarantoolmq.internal.topic_manager"] = "internal/topic_manager.lua",
        ["tarantoolmq.internal.partition_manager"] = "internal/partition_manager.lua",
        ["tarantoolmq.internal.message_log"] = "internal/message_log.lua",
        ["tarantoolmq.internal.consumer_group"] = "internal/consumer_group.lua",
        ["tarantoolmq.internal.storage"] = "internal/storage.lua",
        ["tarantoolmq.http.gateway"] = "http/gateway.lua",
    };
}
