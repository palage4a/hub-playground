local uuid = require("uuid")
local json = require("json")
local fiber = require("fiber")

local message_log = {}
local offset_counter = {}

function message_log._get_next_offset(topic_name, partition_id)
    local key = topic_name .. ":" .. tostring(partition_id)
    if not offset_counter[key] then
        local last_offset = message_log._get_last_offset(topic_name, partition_id)
        offset_counter[key] = last_offset + 1
    end
    local offset = offset_counter[key]
    offset_counter[key] = offset + 1
    return offset
end

function message_log.produce(topic_name, partition_id, key, value, headers, config)
    local topic = box.space.topics.index.name:get{topic_name}
    if not topic then
        return nil, "Topic not found"
    end

    local partition = box.space.partitions.index.topic_partition:get{topic_name, partition_id}
    if not partition then
        return nil, "Partition not found"
    end

    local offset = message_log._get_next_offset(topic_name, partition_id)
    
    local msg_id = uuid.str()
    local timestamp = tonumber(fiber.time64()) / 1000
    local produced_at = os.time()

    local acks = config and config.acks or "leader"
    local should_ack = acks ~= "none"

    local headers_str = headers and json.encode(headers) or "{}"

    box.space.messages:insert({
        msg_id,
        topic_name,
        partition_id,
        offset,
        key,
        value,
        headers_str,
        timestamp,
        produced_at,
        false
    })

    if should_ack then
        box.space.messages:update({msg_id}, {{"=", 10, true}})
    end

    return {
        id = msg_id,
        topic = topic_name,
        partition = partition_id,
        offset = offset,
        timestamp = timestamp,
        acked = should_ack
    }
end

function message_log._get_last_offset(topic_name, partition_id)
    local last_offset = -1
    for _, msg in box.space.messages:pairs() do
        if msg[2] == topic_name and msg[3] == partition_id then
            if msg[4] > last_offset then
                last_offset = msg[4]
            end
        end
    end
    return last_offset
end

function message_log.consume(topic_name, partition_id, offset, max_records)
    max_records = max_records or 100
    
    local messages = {}
    local count = 0
    
    for _, msg in box.space.messages:pairs() do
        if msg[2] == topic_name and msg[3] == partition_id and msg[4] >= offset then
            table.insert(messages, {
                id = msg[1],
                topic = msg[2],
                partition = msg[3],
                offset = msg[4],
                key = msg[5],
                value = msg[6],
                headers = json.decode(msg[7] or "{}"),
                timestamp = msg[8],
                produced_at = msg[9],
                acked = msg[10]
            })
            count = count + 1
            if count >= max_records then
                break
            end
        end
    end
    
    return messages
end

function message_log.seek(topic_name, partition_id, group_name, offset)
    local offset_record = box.space.offsets.index.group_topic_partition
        :get{group_name, topic_name, partition_id}
    
    if not offset_record then
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
            {offset_record[1]},
            {{"=", 5, offset}, {"=", 6, os.time()}}
        )
    end
    
    return offset
end

function message_log.get_offset(topic_name, partition_id, group_name)
    local offset_record = box.space.offsets.index.group_topic_partition
        :get{group_name, topic_name, partition_id}
    
    if not offset_record then
        return 0
    end
    
    return offset_record[5]
end

function message_log.get_high_watermark(topic_name, partition_id)
    return message_log._get_last_offset(topic_name, partition_id) + 1
end

function message_log.get_low_watermark(topic_name, partition_id)
    return 0
end

function message_log.ack_message(message_id)
    box.space.messages:update({message_id}, {{"=", 10, true}})
end

function message_log.cleanup_expired(topic_name)
    local topic = box.space.topics.index.name:get{topic_name}
    if not topic then
        return 0
    end

    local retention_seconds = topic[5]
    local cutoff_time = os.time() - retention_seconds
    
    local count = 0
    local to_delete = {}
    for _, msg in box.space.messages:pairs() do
        if msg[2] == topic_name and msg[9] < cutoff_time then
            table.insert(to_delete, msg[1])
        end
    end
    
    for _, id in ipairs(to_delete) do
        box.space.messages:delete({id})
        count = count + 1
    end
    
    return count
end

return message_log
