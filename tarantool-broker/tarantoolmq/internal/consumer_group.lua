local uuid = require("uuid")

local consumer_group = {}

function consumer_group.create_group(group_name, topic_name)
    local existing = box.space.consumer_groups.index.name_topic:get{group_name, topic_name}
    if existing then
        return {
            id = existing[1],
            name = existing[2],
            topic_name = existing[3],
            created_at = existing[4]
        }
    end

    local group_id = uuid.str()
    local now = os.time()

    box.space.consumer_groups:insert({
        group_id,
        group_name,
        topic_name,
        now
    })

    local topic = box.space.topics.index.name:get{topic_name}
    if topic then
        for partition_id = 0, topic[3] - 1 do
            box.space.offsets:insert({
                uuid.str(),
                group_name,
                topic_name,
                partition_id,
                0,
                now
            })
        end
    end

    return {
        id = group_id,
        name = group_name,
        topic_name = topic_name,
        created_at = now
    }
end

function consumer_group.get_group(group_name, topic_name)
    local group = box.space.consumer_groups.index.name_topic:get{group_name, topic_name}
    if not group then
        return nil
    end
    return {
        id = group[1],
        name = group[2],
        topic_name = group[3],
        created_at = group[4]
    }
end

function consumer_group.list_groups(topic_name)
    local groups = {}
    for _, g in box.space.consumer_groups:pairs() do
        if not topic_name or g[3] == topic_name then
            table.insert(groups, {
                id = g[1],
                name = g[2],
                topic_name = g[3],
                created_at = g[4]
            })
        end
    end
    return groups
end

function consumer_group.delete_group(group_name, topic_name)
    local group = box.space.consumer_groups.index.name_topic:get{group_name, topic_name}
    if not group then
        return false, "Group not found"
    end

    for _, o in box.space.offsets.index.group_topic_partition:pairs({group_name, topic_name}) do
        box.space.offsets:delete({o[1]})
    end

    box.space.consumer_groups:delete({group[1]})
    return true
end

function consumer_group.get_offsets(group_name, topic_name)
    local offsets = {}
    for _, o in box.space.offsets.index.group_topic_partition:pairs({group_name, topic_name}) do
        table.insert(offsets, {
            topic = o[3],
            partition = o[4],
            offset = o[5],
            updated_at = o[6]
        })
    end
    return offsets
end

function consumer_group.commit_offset(group_name, topic_name, partition_id, offset)
    local existing = box.space.offsets.index.group_topic_partition
        :get{group_name, topic_name, partition_id}
    
    if not existing then
        box.space.offsets:insert({
            uuid.str(),
            group_name,
            topic_name,
            partition_id,
            offset,
            os.time()
        })
    else
        box.space.offsets:update(
            {existing[1]},
            {{"=", 5, offset}, {"=", 6, os.time()}}
        )
    end
    
    return offset
end

function consumer_group.assign_partitions(group_name, topic_name, num_consumers)
    local topic = box.space.topics.index.name:get{topic_name}
    if not topic then
        return nil, "Topic not found"
    end

    local partitions = {}
    for i = 0, topic[3] - 1 do
        table.insert(partitions, i)
    end

    local assignments = {}
    local consumer_per_partition = math.ceil(#partitions / math.max(num_consumers, 1))
    
    for i = 1, math.min(num_consumers, #partitions) do
        local start_idx = (i - 1) * consumer_per_partition + 1
        local end_idx = math.min(i * consumer_per_partition, #partitions)
        
        local assigned_partitions = {}
        for j = start_idx, end_idx do
            table.insert(assigned_partitions, partitions[j])
        end
        
        table.insert(assignments, {
            consumer_id = "consumer-" .. i,
            partitions = assigned_partitions
        })
    end
    
    return assignments
end

return consumer_group
