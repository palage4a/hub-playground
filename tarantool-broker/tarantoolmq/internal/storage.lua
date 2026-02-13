local log = require("log")

local storage = {}

function storage.init()
    box.cfg({
        memtx_dir = "var/lib/tarantool/memtx",
        vinyl_dir = "var/lib/tarantool/vinyl",
        log = "var/log/tarantool.log",
        log_level = 5,
        checkpoint_interval = 3600,
        checkpoint_count = 3,
    })

    if not box.space.topics then
        box.schema.space.create("topics", {
            format = {
                {name = "id", type = "string"},
                {name = "name", type = "string"},
                {name = "partitions", type = "unsigned"},
                {name = "replication_factor", type = "unsigned"},
                {name = "retention_seconds", type = "unsigned"},
                {name = "retention_bytes", type = "unsigned"},
                {name = "created_at", type = "number"},
                {name = "updated_at", type = "number"},
            }
        })
        box.space.topics:create_index("id", {unique = true, parts = {{field = 1, type = "string"}}})
        box.space.topics:create_index("name", {unique = true, parts = {{field = 2, type = "string"}}})
    end

    if not box.space.partitions then
        box.schema.space.create("partitions", {
            format = {
                {name = "id", type = "string"},
                {name = "topic_name", type = "string"},
                {name = "partition_id", type = "unsigned"},
                {name = "leader", type = "string"},
                {name = "replicas", type = "array"},
                {name = "is_active", type = "boolean"},
                {name = "created_at", type = "number"},
            }
        })
        box.space.partitions:create_index("id", {unique = true, parts = {{field = 1, type = "string"}}})
        box.space.partitions:create_index("topic_partition", {unique = true, parts = {{field = 2, type = "string"}, {field = 3, type = "unsigned"}}})
    end

    if not box.space.messages then
        box.schema.space.create("messages", {
            format = {
                {name = "id", type = "string"},
                {name = "topic_name", type = "string"},
                {name = "partition_id", type = "unsigned"},
                {name = "offset", type = "unsigned"},
                {name = "key", type = "string", is_nullable = true},
                {name = "value", type = "string"},
                {name = "headers", type = "string"},
                {name = "timestamp", type = "number"},
                {name = "produced_at", type = "number"},
                {name = "acked", type = "boolean"},
            }
        })
        box.space.messages:create_index("id", {unique = true, parts = {{field = 1, type = "string"}}})
    end

    if not box.space.consumer_groups then
        box.schema.space.create("consumer_groups", {
            format = {
                {name = "id", type = "string"},
                {name = "name", type = "string"},
                {name = "topic_name", type = "string"},
                {name = "created_at", type = "number"},
            }
        })
        box.space.consumer_groups:create_index("id", {unique = true, parts = {{field = 1, type = "string"}}})
        box.space.consumer_groups:create_index("name_topic", {unique = true, parts = {{field = 2, type = "string"}, {field = 3, type = "string"}}})
    end

    if not box.space.offsets then
        box.schema.space.create("offsets", {
            format = {
                {name = "id", type = "string"},
                {name = "group_name", type = "string"},
                {name = "topic_name", type = "string"},
                {name = "partition_id", type = "unsigned"},
                {name = "offset", type = "unsigned"},
                {name = "updated_at", type = "number"},
            }
        })
        box.space.offsets:create_index("id", {unique = true, parts = {{field = 1, type = "string"}}})
        box.space.offsets:create_index("group_topic_partition", {unique = true, parts = {{field = 2, type = "string"}, {field = 3, type = "string"}, {field = 4, type = "unsigned"}}})
    end

    log.info("Storage initialized successfully")
end

return storage
