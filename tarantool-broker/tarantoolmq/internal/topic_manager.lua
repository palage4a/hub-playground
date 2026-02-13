local fun = require("fun")
local uuid = require("uuid")

local topic_manager = {}

function topic_manager.create_topic(name, config)
    local partitions = config.default_partitions or 4
    local replication_factor = config.default_replication_factor or 1
    local retention_seconds = config.default_retention_seconds or 604800
    local retention_bytes = config.default_retention_bytes or 1073741824

    local topic_id = uuid.str()
    local now = os.time()

    box.space.topics:insert({
        topic_id,
        name,
        partitions,
        replication_factor,
        retention_seconds,
        retention_bytes,
        now,
        now
    })

    for i = 0, partitions - 1 do
        local partition_id = uuid.str()
        box.space.partitions:insert({
            partition_id,
            name,
            i,
            "localhost",
            {"localhost"},
            true,
            now
        })
    end

    return {
        id = topic_id,
        name = name,
        partitions = partitions,
        replication_factor = replication_factor,
        retention_seconds = retention_seconds,
        retention_bytes = retention_bytes,
        created_at = now,
        updated_at = now
    }
end

function topic_manager.get_topic(name)
    local topic = box.space.topics.index.name:get{name}
    if not topic then
        return nil
    end
    return {
        id = topic[1],
        name = topic[2],
        partitions = topic[3],
        replication_factor = topic[4],
        retention_seconds = topic[5],
        retention_bytes = topic[6],
        created_at = topic[7],
        updated_at = topic[8]
    }
end

function topic_manager.list_topics()
    local topics = {}
    for _, t in box.space.topics:pairs() do
        table.insert(topics, {
            id = t[1],
            name = t[2],
            partitions = t[3],
            replication_factor = t[4],
            retention_seconds = t[5],
            retention_bytes = t[6],
            created_at = t[7],
            updated_at = t[8]
        })
    end
    return topics
end

function topic_manager.delete_topic(name)
    local topic = box.space.topics.index.name:get{name}
    if not topic then
        return false, "Topic not found"
    end

    for _, p in box.space.partitions.index.topic_partition:pairs(name) do
        box.space.partitions:delete({p[1]})
    end

    box.space.topics:delete({topic[1]})
    return true
end

function topic_manager.get_partitions(topic_name)
    local partitions = {}
    for _, p in box.space.partitions.index.topic_partition:pairs(topic_name) do
        table.insert(partitions, {
            id = p[1],
            topic_name = p[2],
            partition_id = p[3],
            leader = p[4],
            replicas = p[5],
            is_active = p[6],
            created_at = p[7]
        })
    end
    return partitions
end

function topic_manager.get_partition(topic_name, partition_id)
    local p = box.space.partitions.index.topic_partition:get{topic_name, partition_id}
    if not p then
        return nil
    end
    return {
        id = p[1],
        topic_name = p[2],
        partition_id = p[3],
        leader = p[4],
        replicas = p[5],
        is_active = p[6],
        created_at = p[7]
    }
end

function topic_manager.get_next_offset(topic_name, partition_id)
    local last_msg = box.space.messages.index.topic_partition_offset
        :tail({topic_name, partition_id})
    
    if not last_msg then
        return 0
    end
    return last_msg[4] + 1
end

return topic_manager
