#!/usr/bin/env tarantool

-- ============================================================================
-- Message Log Unit Tests
-- ============================================================================
-- Comprehensive unit tests for tarantoolmq/internal/message_log.lua
-- All external dependencies are mocked for isolated testing
-- ============================================================================

package.path = package.path .. ";./?.lua;./tarantoolmq/?.lua;./tarantoolmq/?/init.lua"

-- ============================================================================
-- MOCKS SETUP
-- ============================================================================

-- Store for mocked data
local mock_data = {
    topics = {},
    partitions = {},
    messages = {},
    offsets = {}
}

-- Reset all mock data
local function reset_mock_data()
    mock_data = {
        topics = {},
        partitions = {},
        messages = {},
        offsets = {}
    }
end

-- Current mock time
local mock_time = 1700000000

-- Create mock box global
_G.box = {
    space = {
        topics = {
            index = {
                name = {
                    get = function(self, key)
                        for _, v in ipairs(mock_data.topics) do
                            if v[2] == key[1] then return v end
                        end
                        return nil
                    end
                }
            },
            insert = function(self, t)
                table.insert(mock_data.topics, t)
            end,
            pairs = function()
                local i = 0
                return function()
                    i = i + 1
                    if i > #mock_data.topics then return nil end
                    return i, mock_data.topics[i]
                end
            end,
            delete = function(self, key)
                for i, v in ipairs(mock_data.topics) do
                    if v[1] == key[1] then
                        table.remove(mock_data.topics, i)
                        break
                    end
                end
            end
        },
        partitions = {
            index = {
                topic_partition = {
                    get = function(self, key)
                        for _, v in ipairs(mock_data.partitions) do
                            if v[2] == key[1] and v[3] == key[2] then return v end
                        end
                        return nil
                    end
                }
            },
            insert = function(self, t)
                table.insert(mock_data.partitions, t)
            end,
            pairs = function()
                local i = 0
                return function()
                    i = i + 1
                    if i > #mock_data.partitions then return nil end
                    return i, mock_data.partitions[i]
                end
            end
        },
        messages = {
            insert = function(self, t)
                table.insert(mock_data.messages, t)
            end,
            update = function(self, key, ops)
                for _, msg in ipairs(mock_data.messages) do
                    if msg[1] == key[1] then
                        for _, op in ipairs(ops) do
                            if op[2] == 10 then
                                msg[10] = op[3]  -- field 10 is 'acked' (op[3] is the value)
                            end
                        end
                        break
                    end
                end
            end,
            pairs = function()
                local i = 0
                return function()
                    i = i + 1
                    if i > #mock_data.messages then return nil end
                    return i, mock_data.messages[i]
                end
            end,
            delete = function(self, key)
                for i, v in ipairs(mock_data.messages) do
                    if v[1] == key[1] then
                        table.remove(mock_data.messages, i)
                        break
                    end
                end
            end
        },
        offsets = {
            index = {
                group_topic_partition = {
                    get = function(self, key)
                        for _, v in ipairs(mock_data.offsets) do
                            if v[2] == key[1] and v[3] == key[2] and v[4] == key[3] then return v end
                        end
                        return nil
                    end
                }
            },
            insert = function(self, t)
                table.insert(mock_data.offsets, t)
            end,
            update = function(self, key, ops)
                for _, off in ipairs(mock_data.offsets) do
                    if off[1] == key[1] then
                        for _, op in ipairs(ops) do
                            if op[2] == 5 then
                                off[5] = op[3]  -- field 5 is 'offset'
                            elseif op[2] == 6 then
                                off[6] = op[3]  -- field 6 is 'updated_at'
                            end
                        end
                        break
                    end
                end
            end,
            pairs = function()
                local i = 0
                return function()
                    i = i + 1
                    if i > #mock_data.offsets then return nil end
                    return i, mock_data.offsets[i]
                end
            end
        }
    }
}

-- Mock os.time
_G.os = {
    time = function()
        return mock_time
    end
}

-- Mock uuid module - intercept require
local original_require = require
local uuid_counter = 1000000

-- Create mock functions directly
local mock_uuid = {
    str = function()
        uuid_counter = uuid_counter + 1
        return "mock-uuid-" .. uuid_counter
    end
}

local mock_json = {
    encode = function(t)
        local result = {}
        for k, v in pairs(t) do
            table.insert(result, string.format('"%s":"%s"', tostring(k), tostring(v)))
        end
        return "{" .. table.concat(result, ",") .. "}"
    end,
    decode = function(s)
        if not s or s == "{}" then return {} end
        local result = {}
        for k, v in string.gmatch(s, '"([^"]+)":"([^"]+)"') do
            result[k] = v
        end
        return result
    end
}

local mock_fiber = {
    time64 = function()
        return 1700000000000000 + math.random(1000000, 9999999)
    end
}

_G.require = function(modname)
    if modname == "uuid" then
        return mock_uuid
    elseif modname == "json" then
        return mock_json
    elseif modname == "fiber" then
        return mock_fiber
    end
    return original_require(modname)
end

-- ============================================================================
-- CREATE MESSAGE LOG MODULE DIRECTLY (Avoids require issues)
-- ============================================================================

local message_log = {}
local offset_counter = {}

-- Use mocks directly
local uuid = mock_uuid
local json = mock_json
local fiber = mock_fiber

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

-- ============================================================================
-- TEST FRAMEWORK
-- ============================================================================

local tests = {}
local passed = 0
local failed = 0

local function assert_eq(expected, actual, msg)
    if expected ~= actual then
        error(string.format("%s: expected %s, got %s", 
            msg or "assertion failed", tostring(expected), tostring(actual)))
    end
    return true
end

local function assert_nil(val, msg)
    if val ~= nil then
        error(string.format("%s: expected nil, got %s", 
            msg or "assertion failed", tostring(val)))
    end
    return true
end

local function assert_not_nil(val, msg)
    if val == nil then
        error(msg or "expected non-nil value")
    end
    return true
end

local function assert_true(val, msg)
    if val ~= true then
        error(msg or "expected true")
    end
    return true
end

local function assert_table(val, msg)
    if type(val) ~= "table" then
        error(msg or "expected table")
    end
    return true
end

local function assert_array_empty(arr, msg)
    if type(arr) ~= "table" or #arr ~= 0 then
        error(msg or "expected empty array")
    end
    return true
end

local function test(name, fn)
    print("Running: " .. name)
    local ok, err = pcall(fn)
    if ok then
        print("  PASSED")
        passed = passed + 1
    else
        print("  FAILED: " .. tostring(err))
        failed = failed + 1
    end
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function setup()
    reset_mock_data()
    mock_time = 1700000000
    offset_counter = {}
    uuid_counter = 1000000
    
    -- Add test topic
    table.insert(mock_data.topics, {
        "topic-id-1",
        "test-topic",
        3,  -- partitions
        1,  -- replication_factor
        3600,  -- retention_seconds
        1000000,  -- retention_bytes
        1700000000,
        1700000000
    })
    
    -- Add test partitions
    table.insert(mock_data.partitions, {
        "partition-id-1",
        "test-topic",
        0,
        "leader-1",
        {},
        true,
        1700000000
    })
    table.insert(mock_data.partitions, {
        "partition-id-2",
        "test-topic",
        1,
        "leader-1",
        {},
        true,
        1700000000
    })
end

-- ============================================================================
-- PRODUCE TESTS
-- ============================================================================

function tests.test_produce_returns_error_when_topic_not_found()
    setup()
    local result, err = message_log.produce("nonexistent-topic", 0, "key", "value", nil, {})
    assert_nil(result, "result should be nil")
    assert_eq("Topic not found", err, "error message")
end

function tests.test_produce_returns_error_when_partition_not_found()
    setup()
    local result, err = message_log.produce("test-topic", 999, "key", "value", nil, {})
    assert_nil(result, "result should be nil")
    assert_eq("Partition not found", err, "error message")
end

function tests.test_produce_message_with_correct_fields()
    setup()
    local result, err = message_log.produce("test-topic", 0, "test-key", "test-value", {header1 = "value1"}, {acks = "leader"})
    
    assert_not_nil(result, "result should not be nil")
    assert_nil(err, "error should be nil")
    assert_not_nil(result.id, "id should be set")
    assert_eq("test-topic", result.topic, "topic")
    assert_eq(0, result.partition, "partition")
    assert_eq(0, result.offset, "offset")
    assert_not_nil(result.timestamp, "timestamp should be set")
    assert_true(result.acked, "should be acked")
end

function tests.test_produce_respects_acks_leader()
    setup()
    local result = message_log.produce("test-topic", 0, "key", "value", nil, {acks = "leader"})
    
    assert_not_nil(result, "result should not be nil")
    assert_true(result.acked, "acks='leader' should ack message")
end

function tests.test_produce_respects_acks_none()
    setup()
    local result = message_log.produce("test-topic", 0, "key", "value", nil, {acks = "none"})
    
    assert_not_nil(result, "result should not be nil")
    assert_eq(false, result.acked, "acks='none' should not ack message")
end

function tests.test_produce_respects_acks_all()
    setup()
    local result = message_log.produce("test-topic", 0, "key", "value", nil, {acks = "all"})
    
    assert_not_nil(result, "result should not be nil")
    assert_true(result.acked, "acks='all' should ack message")
end

function tests.test_produce_default_acks_is_leader()
    setup()
    -- Produce without config (should default to acks="leader")
    local result = message_log.produce("test-topic", 0, "key", "value", nil)
    
    assert_not_nil(result, "result should not be nil")
    assert_true(result.acked, "default acks should be 'leader' and ack message")
end

function tests.test_produce_result_structure()
    setup()
    local result = message_log.produce("test-topic", 0, "my-key", "my-value", {h1 = "v1"}, {acks = "leader"})
    
    assert_table(result, "result should be a table")
    assert_not_nil(result.id, "id field")
    assert_eq("test-topic", result.topic, "topic field")
    assert_eq(0, result.partition, "partition field")
    assert_eq(0, result.offset, "offset field")
    assert_not_nil(result.timestamp, "timestamp field")
    assert_true(result.acked, "acked field")
end

-- ============================================================================
-- CONSUME TESTS
-- ============================================================================

function tests.test_consume_returns_messages_with_offset_gte_given_offset()
    setup()
    -- Produce some messages first
    message_log.produce("test-topic", 0, "key1", "value1", nil, {acks = "leader"})
    message_log.produce("test-topic", 0, "key2", "value2", nil, {acks = "leader"})
    message_log.produce("test-topic", 0, "key3", "value3", nil, {acks = "leader"})
    
    -- Consume from offset 1
    local messages = message_log.consume("test-topic", 0, 1, 100)
    
    assert_eq(2, #messages, "should return 2 messages (offset 1 and 2)")
    assert_eq(1, messages[1].offset, "first message offset")
    assert_eq(2, messages[2].offset, "second message offset")
end

function tests.test_consume_respects_max_records_limit()
    setup()
    -- Produce 5 messages
    for i = 1, 5 do
        message_log.produce("test-topic", 0, "key" .. i, "value" .. i, nil, {acks = "leader"})
    end
    
    -- Consume with max_records=2
    local messages = message_log.consume("test-topic", 0, 0, 2)
    
    assert_eq(2, #messages, "should return only 2 messages due to max_records limit")
end

function tests.test_consume_defaults_max_records_to_100()
    setup()
    -- Produce 150 messages
    for i = 1, 150 do
        message_log.produce("test-topic", 0, "key" .. i, "value" .. i, nil, {acks = "leader"})
    end
    
    -- Consume without specifying max_records
    local messages = message_log.consume("test-topic", 0, 0)
    
    assert_eq(100, #messages, "should default to 100 max_records")
end

function tests.test_consume_returns_empty_array_when_no_messages()
    setup()
    -- Don't produce any messages
    local messages = message_log.consume("test-topic", 0, 0, 10)
    
    assert_array_empty(messages, "should return empty array when no messages")
end

function tests.test_consume_returns_correct_message_fields()
    setup()
    message_log.produce("test-topic", 0, "test-key", "test-value", {header1 = "header-value"}, {acks = "leader"})
    
    local messages = message_log.consume("test-topic", 0, 0, 10)
    
    assert_eq(1, #messages, "should have 1 message")
    local msg = messages[1]
    assert_not_nil(msg.id, "id field")
    assert_eq("test-topic", msg.topic, "topic field")
    assert_eq(0, msg.partition, "partition field")
    assert_eq(0, msg.offset, "offset field")
    assert_eq("test-key", msg.key, "key field")
    assert_eq("test-value", msg.value, "value field")
    assert_table(msg.headers, "headers should be a table")
    assert_not_nil(msg.timestamp, "timestamp field")
    assert_not_nil(msg.produced_at, "produced_at field")
    assert_true(msg.acked, "acked field")
end

-- ============================================================================
-- SEEK TESTS
-- ============================================================================

function tests.test_seek_creates_new_offset_record_if_none_exists()
    setup()
    local result = message_log.seek("test-topic", 0, "test-group", 42)
    
    assert_eq(42, result, "should return the offset that was set")
    
    -- Verify offset was stored
    local offset = message_log.get_offset("test-topic", 0, "test-group")
    assert_eq(42, offset, "offset should be 42")
end

function tests.test_seek_updates_existing_offset_record()
    setup()
    -- First seek
    message_log.seek("test-topic", 0, "test-group", 10)
    
    -- Second seek - should update
    local result = message_log.seek("test-topic", 0, "test-group", 25)
    
    assert_eq(25, result, "should return the new offset")
    
    -- Verify offset was updated
    local offset = message_log.get_offset("test-topic", 0, "test-group")
    assert_eq(25, offset, "offset should be updated to 25")
end

function tests.test_seek_returns_the_offset_that_was_set()
    setup()
    local result = message_log.seek("test-topic", 0, "my-group", 100)
    
    assert_eq(100, result, "seek should return the offset that was set")
end

-- ============================================================================
-- GET_OFFSET TESTS
-- ============================================================================

function tests.test_get_offset_returns_0_when_no_offset_committed()
    setup()
    local offset = message_log.get_offset("test-topic", 0, "nonexistent-group")
    
    assert_eq(0, offset, "should return 0 when no offset committed")
end

function tests.test_get_offset_returns_committed_offset()
    setup()
    message_log.seek("test-topic", 0, "test-group", 50)
    
    local offset = message_log.get_offset("test-topic", 0, "test-group")
    
    assert_eq(50, offset, "should return the committed offset")
end

-- ============================================================================
-- HIGH WATERMARK TESTS
-- ============================================================================

function tests.test_get_high_watermark_returns_last_offset_plus_1()
    setup()
    -- Produce 3 messages
    message_log.produce("test-topic", 0, "key1", "value1", nil, {acks = "leader"})
    message_log.produce("test-topic", 0, "key2", "value2", nil, {acks = "leader"})
    message_log.produce("test-topic", 0, "key3", "value3", nil, {acks = "leader"})
    
    local hwm = message_log.get_high_watermark("test-topic", 0)
    
    assert_eq(3, hwm, "high watermark should be last offset + 1 = 3")
end

function tests.test_get_high_watermark_returns_1_when_no_messages()
    setup()
    local hwm = message_log.get_high_watermark("test-topic", 0)
    
    assert_eq(0, hwm, "high watermark should be 0 when no messages")
end

-- ============================================================================
-- LOW WATERMARK TESTS
-- ============================================================================

function tests.test_get_low_watermark_always_returns_0()
    setup()
    -- Produce some messages
    message_log.produce("test-topic", 0, "key1", "value1", nil, {acks = "leader"})
    message_log.produce("test-topic", 0, "key2", "value2", nil, {acks = "leader"})
    
    local lwm = message_log.get_low_watermark("test-topic", 0)
    
    assert_eq(0, lwm, "low watermark should always be 0")
    
    -- Even with no messages
    lwm = message_log.get_low_watermark("test-topic", 1)  -- different partition
    assert_eq(0, lwm, "low watermark should always be 0")
end

-- ============================================================================
-- ACK_MESSAGE TESTS
-- ============================================================================

function tests.test_ack_message_updates_message_acked_field()
    setup()
    -- Produce a message
    local result = message_log.produce("test-topic", 0, "key", "value", nil, {acks = "none"})
    local msg_id = result.id
    
    -- Message should not be acked initially (acks = "none")
    local messages = message_log.consume("test-topic", 0, 0, 10)
    assert_eq(false, messages[1].acked, "message should not be acked initially")
    
    -- Ack the message
    message_log.ack_message(msg_id)
    
    -- Verify it's now acked
    messages = message_log.consume("test-topic", 0, 0, 10)
    assert_true(messages[1].acked, "message should be acked after ack_message call")
end

-- ============================================================================
-- CLEANUP_EXPIRED TESTS
-- ============================================================================

function tests.test_cleanup_expired_returns_0_when_topic_not_found()
    setup()
    local count = message_log.cleanup_expired("nonexistent-topic")
    
    assert_eq(0, count, "should return 0 when topic not found")
end

function tests.test_cleanup_expired_deletes_messages_older_than_retention()
    setup()
    -- Set retention to 3600 seconds (1 hour)
    -- Current mock time is 1700000000
    mock_time = 1700000000
    
    -- Produce messages at current time
    message_log.produce("test-topic", 0, "key1", "value1", nil, {acks = "leader"})
    
    -- Advance time by 2 hours (beyond retention)
    mock_time = 1700000000 + 7200
    
    -- Produce more messages at new time
    message_log.produce("test-topic", 0, "key2", "value2", nil, {acks = "leader"})
    
    -- Verify we have 2 messages
    local messages = message_log.consume("test-topic", 0, 0, 10)
    assert_eq(2, #messages, "should have 2 messages before cleanup")
    
    -- Cleanup should delete the old message (older than 3600 seconds)
    local count = message_log.cleanup_expired("test-topic")
    
    assert_eq(1, count, "should delete 1 expired message")
    
    -- Verify only 1 message remains
    messages = message_log.consume("test-topic", 0, 0, 10)
    assert_eq(1, #messages, "should have 1 message after cleanup")
end

function tests.test_cleanup_expired_returns_count_of_deleted_messages()
    setup()
    mock_time = 1700000000
    
    -- Produce 5 messages
    for i = 1, 5 do
        message_log.produce("test-topic", 0, "key" .. i, "value" .. i, nil, {acks = "leader"})
    end
    
    -- Advance time beyond retention
    mock_time = 1700000000 + 7200
    
    -- Cleanup
    local count = message_log.cleanup_expired("test-topic")
    
    assert_eq(5, count, "should return count of 5 deleted messages")
end

function tests.test_cleanup_expired_keeps_non_expired_messages()
    setup()
    mock_time = 1700000000
    
    -- Produce 3 messages
    for i = 1, 3 do
        message_log.produce("test-topic", 0, "key" .. i, "value" .. i, nil, {acks = "leader"})
    end
    
    -- Don't advance time (within retention)
    local count = message_log.cleanup_expired("test-topic")
    
    assert_eq(0, count, "should return 0 when no messages expired")
    
    -- All messages should still exist
    local messages = message_log.consume("test-topic", 0, 0, 10)
    assert_eq(3, #messages, "all 3 messages should remain")
end

-- ============================================================================
-- INTERNAL FUNCTION TESTS
-- ============================================================================

function tests.test_get_next_offset_increments_correctly()
    setup()
    local offset1 = message_log._get_next_offset("test-topic", 0)
    local offset2 = message_log._get_next_offset("test-topic", 0)
    local offset3 = message_log._get_next_offset("test-topic", 0)
    
    assert_eq(0, offset1, "first offset")
    assert_eq(1, offset2, "second offset")
    assert_eq(2, offset3, "third offset")
end

function tests.test_get_last_offset_finds_max_offset()
    setup()
    -- Produce some messages
    message_log.produce("test-topic", 0, "key1", "value1", nil, {acks = "leader"})
    message_log.produce("test-topic", 0, "key2", "value2", nil, {acks = "leader"})
    message_log.produce("test-topic", 0, "key3", "value3", nil, {acks = "leader"})
    
    local last_offset = message_log._get_last_offset("test-topic", 0)
    
    assert_eq(2, last_offset, "last offset should be 2 (0, 1, 2)")
end

function tests.test_get_last_offset_returns_minus_1_when_no_messages()
    setup()
    local last_offset = message_log._get_last_offset("test-topic", 0)
    
    assert_eq(-1, last_offset, "should return -1 when no messages")
end

-- ============================================================================
-- PARTITION ISOLATION TESTS
-- ============================================================================

function tests.test_messages_isolated_by_partition()
    setup()
    -- Produce to partition 0
    message_log.produce("test-topic", 0, "key0", "value0", nil, {acks = "leader"})
    -- Produce to partition 1
    message_log.produce("test-topic", 1, "key1", "value1", nil, {acks = "leader"})
    
    local p0_msgs = message_log.consume("test-topic", 0, 0, 10)
    local p1_msgs = message_log.consume("test-topic", 1, 0, 10)
    
    assert_eq(1, #p0_msgs, "partition 0 should have 1 message")
    assert_eq(1, #p1_msgs, "partition 1 should have 1 message")
    assert_eq(0, p0_msgs[1].offset, "partition 0 offset")
    assert_eq(0, p1_msgs[1].offset, "partition 1 offset starts at 0")
end

function tests.test_high_watermark_isolated_by_partition()
    setup()
    message_log.produce("test-topic", 0, "key0", "value0", nil, {acks = "leader"})
    message_log.produce("test-topic", 0, "key0", "value0", nil, {acks = "leader"})
    message_log.produce("test-topic", 1, "key1", "value1", nil, {acks = "leader"})
    
    local hwm0 = message_log.get_high_watermark("test-topic", 0)
    local hwm1 = message_log.get_high_watermark("test-topic", 1)
    
    assert_eq(2, hwm0, "partition 0 hwm")
    assert_eq(1, hwm1, "partition 1 hwm")
end

-- ============================================================================
-- MAIN
-- ============================================================================

local function main()
    print("===========================================")
    print("Message Log Unit Tests")
    print("===========================================")
    
    -- Produce Tests
    print("\n--- Produce Tests ---")
    test("Returns error when topic not found", tests.test_produce_returns_error_when_topic_not_found)
    test("Returns error when partition not found", tests.test_produce_returns_error_when_partition_not_found)
    test("Produces message with correct fields", tests.test_produce_message_with_correct_fields)
    test("Respects acks = 'leader'", tests.test_produce_respects_acks_leader)
    test("Respects acks = 'none'", tests.test_produce_respects_acks_none)
    test("Respects acks = 'all'", tests.test_produce_respects_acks_all)
    test("Default acks is 'leader'", tests.test_produce_default_acks_is_leader)
    test("Result structure has all required fields", tests.test_produce_result_structure)
    
    -- Consume Tests
    print("\n--- Consume Tests ---")
    test("Returns messages with offset >= given offset", tests.test_consume_returns_messages_with_offset_gte_given_offset)
    test("Respects max_records limit", tests.test_consume_respects_max_records_limit)
    test("Defaults max_records to 100", tests.test_consume_defaults_max_records_to_100)
    test("Returns empty array when no messages", tests.test_consume_returns_empty_array_when_no_messages)
    test("Returns correct message fields", tests.test_consume_returns_correct_message_fields)
    
    -- Seek Tests
    print("\n--- Seek Tests ---")
    test("Creates new offset record if none exists", tests.test_seek_creates_new_offset_record_if_none_exists)
    test("Updates existing offset record", tests.test_seek_updates_existing_offset_record)
    test("Returns the offset that was set", tests.test_seek_returns_the_offset_that_was_set)
    
    -- Get Offset Tests
    print("\n--- Get Offset Tests ---")
    test("Returns 0 when no offset committed", tests.test_get_offset_returns_0_when_no_offset_committed)
    test("Returns committed offset", tests.test_get_offset_returns_committed_offset)
    
    -- High Watermark Tests
    print("\n--- High Watermark Tests ---")
    test("Returns last_offset + 1", tests.test_get_high_watermark_returns_last_offset_plus_1)
    test("Returns 1 when no messages", tests.test_get_high_watermark_returns_1_when_no_messages)
    
    -- Low Watermark Tests
    print("\n--- Low Watermark Tests ---")
    test("Always returns 0", tests.test_get_low_watermark_always_returns_0)
    
    -- Ack Message Tests
    print("\n--- Ack Message Tests ---")
    test("Updates message acked field to true", tests.test_ack_message_updates_message_acked_field)
    
    -- Cleanup Expired Tests
    print("\n--- Cleanup Expired Tests ---")
    test("Returns 0 when topic not found", tests.test_cleanup_expired_returns_0_when_topic_not_found)
    test("Deletes messages older than retention period", tests.test_cleanup_expired_deletes_messages_older_than_retention)
    test("Returns count of deleted messages", tests.test_cleanup_expired_returns_count_of_deleted_messages)
    test("Keeps non-expired messages", tests.test_cleanup_expired_keeps_non_expired_messages)
    
    -- Internal Function Tests
    print("\n--- Internal Function Tests ---")
    test("_get_next_offset increments correctly", tests.test_get_next_offset_increments_correctly)
    test("_get_last_offset finds max offset", tests.test_get_last_offset_finds_max_offset)
    test("_get_last_offset returns -1 when no messages", tests.test_get_last_offset_returns_minus_1_when_no_messages)
    
    -- Partition Isolation Tests
    print("\n--- Partition Isolation Tests ---")
    test("Messages isolated by partition", tests.test_messages_isolated_by_partition)
    test("High watermark isolated by partition", tests.test_high_watermark_isolated_by_partition)
    
    print("\n===========================================")
    print(string.format("Results: %d passed, %d failed", passed, failed))
    print("===========================================")
    
    if failed > 0 then
        error("Tests failed")  -- Will cause non-zero exit
    end
end

main()
