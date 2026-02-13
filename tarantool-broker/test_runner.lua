#!/usr/bin/env tarantool

package.path = package.path .. ";./?.lua;./tarantoolmq/?.lua;./tarantoolmq/?/init.lua"

local storage = require("tarantoolmq.internal.storage")
local topic_manager = require("tarantoolmq.internal.topic_manager")
local message_log = require("tarantoolmq.internal.message_log")
local consumer_group = require("tarantoolmq.internal.consumer_group")

local tests = {}
local passed = 0
local failed = 0

local function assert_eq(expected, actual, msg)
    if expected ~= actual then
        return false, string.format("%s: expected %s, got %s", 
            msg or "assertion failed", tostring(expected), tostring(actual))
    end
    return true
end

local function assert_not_nil(val, msg)
    if val == nil then
        return false, msg or "expected non-nil value"
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

function tests.test_topic_creation()
    local topic = topic_manager.create_topic("test-topic-1", {
        default_partitions = 3,
        default_replication_factor = 1,
        default_retention_seconds = 3600,
        default_retention_bytes = 1000000
    })
    
    assert_not_nil(topic, "topic should be created")
    assert_eq("test-topic-1", topic.name, "topic name")
    assert_eq(3, topic.partitions, "partition count")
end

function tests.test_topic_retrieval()
    local topic = topic_manager.get_topic("test-topic-1")
    assert_not_nil(topic, "topic should be retrieved")
    assert_eq("test-topic-1", topic.name, "topic name")
end

function tests.test_topic_list()
    local topics = topic_manager.list_topics()
    assert_not_nil(topics, "should have topics")
    assert_eq(true, #topics > 0, "should have at least one topic")
end

function tests.test_partition_retrieval()
    local partitions = topic_manager.get_partitions("test-topic-1")
    assert_not_nil(partitions, "should have partitions")
    assert_eq(3, #partitions, "should have 3 partitions")
end

function tests.test_message_production()
    local result, err = message_log.produce("test-topic-1", 0, "key1", "value1", {header1 = "value1"}, {acks = "leader"})
    assert_not_nil(result, "message should be produced")
    assert_eq("test-topic-1", result.topic, "topic name")
    assert_eq(0, result.partition, "partition")
    assert_eq(0, result.offset, "first offset should be 0")
end

function tests.test_message_consumption()
    local messages = message_log.consume("test-topic-1", 0, 0, 10)
    assert_not_nil(messages, "should get messages")
    assert_eq(true, #messages > 0, "should have at least one message")
end

function tests.test_multiple_partitions()
    local test_topic = "test-topic-msgs"
    topic_manager.create_topic(test_topic, {
        default_partitions = 1,
        default_replication_factor = 1
    })
    
    for i = 1, 10 do
        message_log.produce(test_topic, 0, "key" .. i, "value" .. i, nil, {acks = "leader"})
    end
    
    local messages = message_log.consume(test_topic, 0, 0, 100)
    assert_eq(10, #messages, "should have 10 messages")
    
    topic_manager.delete_topic(test_topic)
end

function tests.test_consumer_group_creation()
    local group = consumer_group.create_group("test-group-1", "test-topic-1")
    assert_not_nil(group, "group should be created")
    assert_eq("test-group-1", group.name, "group name")
end

function tests.test_offset_commit()
    consumer_group.commit_offset("test-group-1", "test-topic-1", 0, 5)
    local offset = message_log.get_offset("test-topic-1", 0, "test-group-1")
    assert_eq(5, offset, "offset should be 5")
end

function tests.test_watermarks()
    local high = message_log.get_high_watermark("test-topic-1", 0)
    local low = message_log.get_low_watermark("test-topic-1", 0)
    assert_eq(true, high > 0, "high watermark should be positive")
    assert_eq(0, low, "low watermark should be 0")
end

function tests.test_topic_deletion()
    topic_manager.create_topic("to-delete", {
        default_partitions = 1,
        default_replication_factor = 1
    })
    
    local ok, err = topic_manager.delete_topic("to-delete")
    assert_eq(true, ok, "should delete topic")
    
    local topic = topic_manager.get_topic("to-delete")
    assert_eq(nil, topic, "topic should be nil after deletion")
end

function tests.test_partition_assignment()
    local assignments = consumer_group.assign_partitions("test-group-assign", "test-topic-1", 3)
    assert_not_nil(assignments, "should have assignments")
end

function main()
    print("===========================================")
    print("TarantoolMQ Test Suite")
    print("===========================================")
    
    storage.init()
    
    print("\n--- Topic Tests ---")
    test("Topic Creation", tests.test_topic_creation)
    test("Topic Retrieval", tests.test_topic_retrieval)
    test("Topic List", tests.test_topic_list)
    test("Partition Retrieval", tests.test_partition_retrieval)
    test("Topic Deletion", tests.test_topic_deletion)
    
    print("\n--- Message Tests ---")
    test("Message Production", tests.test_message_production)
    test("Message Consumption", tests.test_message_consumption)
    test("Multiple Partitions", tests.test_multiple_partitions)
    test("Watermarks", tests.test_watermarks)
    
    print("\n--- Consumer Group Tests ---")
    test("Consumer Group Creation", tests.test_consumer_group_creation)
    test("Offset Commit", tests.test_offset_commit)
    test("Partition Assignment", tests.test_partition_assignment)
    
    print("\n===========================================")
    print(string.format("Results: %d passed, %d failed", passed, failed))
    print("===========================================")
    
    os.exit(failed > 0 and 1 or 0)
end

main()
