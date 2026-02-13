#!/usr/bin/env tarantool

-- Unit tests for consumer_group module
-- Mocks box global and dependencies

package.path = package.path .. ";./?.lua;./tarantoolmq/?.lua;./tarantoolmq/?/init.lua"

-- Test framework
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

local function assert_nil(val, msg)
    if val ~= nil then
        return false, string.format("%s: expected nil, got %s", 
            msg or "assertion failed", tostring(val))
    end
    return true
end

local function assert_not_nil(val, msg)
    if val == nil then
        return false, msg or "expected non-nil value"
    end
    return true
end

local function assert_table_eq(expected, actual, msg)
    if type(expected) ~= "table" or type(actual) ~= "table" then
        return false, "both arguments must be tables"
    end
    for k, v in pairs(expected) do
        if type(v) == "table" then
            local ok, err = assert_table_eq(v, actual[k], msg)
            if not ok then return ok, err end
        else
            if actual[k] ~= v then
                return false, string.format("%s: expected[%s]=%s, got=%s", 
                    msg or "table assertion failed", tostring(k), tostring(v), tostring(actual[k]))
            end
        end
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
-- MOCK IMPLEMENTATIONS
-- ============================================================================

-- Mock UUID generator
local uuid_counter = 0
package.loaded["uuid"] = {
    str = function()
        uuid_counter = uuid_counter + 1
        return "mock-uuid-" .. uuid_counter
    end
}

-- Mock time
local mock_time = 1000000
package.loaded["os"] = {
    time = function()
        return mock_time
    end
}

-- In-memory storage for mocks - stored in a global table for dynamic access
_MOCK_STORAGE = {
    consumer_groups = {},
    offsets = {},
    topics = {},
    consumer_groups_index_name_topic = {},
    offsets_index_group_topic_partition = {},
    topics_index_name = {}
}

-- Shortcut references
local mock_consumer_groups = _MOCK_STORAGE.consumer_groups
local mock_offsets = _MOCK_STORAGE.offsets
local mock_topics = _MOCK_STORAGE.topics
local mock_consumer_groups_index_name_topic = _MOCK_STORAGE.consumer_groups_index_name_topic
local mock_offsets_index_group_topic_partition = _MOCK_STORAGE.offsets_index_group_topic_partition
local mock_topics_index_name = _MOCK_STORAGE.topics_index_name

-- Helper to rebuild indexes
local function rebuild_indexes()
    _MOCK_STORAGE.consumer_groups_index_name_topic = {}
    for _, row in ipairs(_MOCK_STORAGE.consumer_groups) do
        _MOCK_STORAGE.consumer_groups_index_name_topic[row[2] .. "|" .. row[3]] = row
    end
    
    _MOCK_STORAGE.offsets_index_group_topic_partition = {}
    for _, row in ipairs(_MOCK_STORAGE.offsets) do
        local key = row[2] .. "|" .. row[3] .. "|" .. row[4]
        _MOCK_STORAGE.offsets_index_group_topic_partition[key] = row
    end
    
    _MOCK_STORAGE.topics_index_name = {}
    for _, row in ipairs(_MOCK_STORAGE.topics) do
        _MOCK_STORAGE.topics_index_name[row[2]] = row
    end
    
    -- Update local references
    mock_consumer_groups_index_name_topic = _MOCK_STORAGE.consumer_groups_index_name_topic
    mock_offsets_index_group_topic_partition = _MOCK_STORAGE.offsets_index_group_topic_partition
    mock_topics_index_name = _MOCK_STORAGE.topics_index_name
end

-- Mock box.global pairs
-- In Tarantool, box.space.xxx:pairs() returns an iterator when called in a for loop
-- We need to dynamically look up the current storage table each time
local function create_pairs_mock(storage_key)
    -- When called as: for _, g in box.space.consumer_groups:pairs() do
    -- it calls pairs() which returns iterator function
    return function()
        local storage_table = _MOCK_STORAGE[storage_key]
        if not storage_table then
            return function() return nil end
        end
        local i = 0
        local n = #storage_table
        return function()
            i = i + 1
            if i <= n then
                return i, storage_table[i]
            end
            return nil
        end
    end
end

local mock_consumer_groups_space = {
    insert = function(self, row)
        table.insert(mock_consumer_groups, row)
        rebuild_indexes()
        return row
    end,
    delete = function(self, key)
        for i, row in ipairs(mock_consumer_groups) do
            if row[1] == key[1] then
                table.remove(mock_consumer_groups, i)
                rebuild_indexes()
                return true
            end
        end
        return false
    end,
    get = function(self, key)
        for _, row in ipairs(mock_consumer_groups) do
            if row[1] == key[1] then
                return row
            end
        end
        return nil
    end,
    pairs = create_pairs_mock("consumer_groups"),
    index = {
        name_topic = {
            get = function(self, key)
                return _MOCK_STORAGE.consumer_groups_index_name_topic[key[1] .. "|" .. key[2]]
            end
        }
    }
}

-- Mock box.space.offsets
local mock_offsets_space = {
    insert = function(self, row)
        table.insert(mock_offsets, row)
        rebuild_indexes()
        return row
    end,
    delete = function(self, key)
        for i, row in ipairs(mock_offsets) do
            if row[1] == key[1] then
                table.remove(mock_offsets, i)
                rebuild_indexes()
                return true
            end
        end
        return false
    end,
    update = function(self, key, operations)
        for _, row in ipairs(mock_offsets) do
            if row[1] == key[1] then
                for _, op in ipairs(operations) do
                    if op[1] == "=" then
                        row[op[2]] = op[3]
                    end
                end
                rebuild_indexes()
                return row
            end
        end
        return nil
    end,
    pairs = create_pairs_mock("offsets"),
    index = {
        group_topic_partition = {
            get = function(self, key)
                return _MOCK_STORAGE.offsets_index_group_topic_partition[key[1] .. "|" .. key[2] .. "|" .. key[3]]
            end,
            pairs = function(self, prefix_key)
                local group_name = prefix_key[1]
                local topic_name = prefix_key[2]
                -- Collect all matching offset IDs first to avoid iteration issues during deletion
                local matching_ids = {}
                for _, row in ipairs(_MOCK_STORAGE.offsets) do
                    if row[2] == group_name and row[3] == topic_name then
                        table.insert(matching_ids, row[1])
                    end
                end
                local idx = 0
                return function()
                    idx = idx + 1
                    if idx <= #matching_ids then
                        local offset_id = matching_ids[idx]
                        -- Find and return the actual row
                        for _, row in ipairs(_MOCK_STORAGE.offsets) do
                            if row[1] == offset_id then
                                return idx, row
                            end
                        end
                    end
                    return nil
                end
            end
        }
    }
}

-- Mock box.space.topics
local mock_topics_space = {
    insert = function(self, row)
        table.insert(mock_topics, row)
        rebuild_indexes()
        return row
    end,
    delete = function(self, key)
        for i, row in ipairs(mock_topics) do
            if row[1] == key[1] then
                table.remove(mock_topics, i)
                rebuild_indexes()
                return true
            end
        end
        return false
    end,
    get = function(self, key)
        for _, row in ipairs(mock_topics) do
            if row[1] == key[1] then
                return row
            end
        end
        return nil
    end,
    pairs = create_pairs_mock("topics"),
    index = {
        name = {
            get = function(self, key)
                return _MOCK_STORAGE.topics_index_name[key[1]]
            end
        }
    }
}

-- Mock box global
_G.box = {
    space = {
        consumer_groups = mock_consumer_groups_space,
        offsets = mock_offsets_space,
        topics = mock_topics_space
    },
    schema = {
        space = {
            create = function() end
        }
    }
}

-- Reset mock data between tests
local function reset_mocks()
    -- Clear the _MOCK_STORAGE tables (keep the same references)
    _MOCK_STORAGE.consumer_groups = {}
    _MOCK_STORAGE.offsets = {}
    _MOCK_STORAGE.topics = {}
    _MOCK_STORAGE.consumer_groups_index_name_topic = {}
    _MOCK_STORAGE.offsets_index_group_topic_partition = {}
    _MOCK_STORAGE.topics_index_name = {}
    
    -- Update local references to point to cleared tables
    mock_consumer_groups = _MOCK_STORAGE.consumer_groups
    mock_offsets = _MOCK_STORAGE.offsets
    mock_topics = _MOCK_STORAGE.topics
    mock_consumer_groups_index_name_topic = _MOCK_STORAGE.consumer_groups_index_name_topic
    mock_offsets_index_group_topic_partition = _MOCK_STORAGE.offsets_index_group_topic_partition
    mock_topics_index_name = _MOCK_STORAGE.topics_index_name
    
    mock_time = 1000000
    uuid_counter = 0
    rebuild_indexes()
    -- Clear the module cache so it uses fresh mocks
    package.loaded["tarantoolmq.internal.consumer_group"] = nil
end

-- Helper to add a topic
local function add_mock_topic(name, partitions)
    local topic = {
        "topic-id-" .. name,
        name,
        partitions,
        1,
        3600,
        1000000,
        mock_time,
        mock_time
    }
    table.insert(mock_topics, topic)
    rebuild_indexes()
end

-- ============================================================================
-- TESTS FOR consumer_group.create_group
-- ============================================================================

function tests.test_create_group_returns_existing_group_if_exists()
    reset_mocks()
    
    -- Pre-insert a group
    table.insert(mock_consumer_groups, {"existing-id", "test-group", "test-topic", 1000})
    rebuild_indexes()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local group = consumer_group.create_group("test-group", "test-topic")
    
    local ok, err = assert_not_nil(group, "group should be returned")
    if not ok then error(err) end
    
    ok, err = assert_eq("existing-id", group.id, "group id should match")
    if not ok then error(err) end
    
    ok, err = assert_eq("test-group", group.name, "group name should match")
    if not ok then error(err) end
    
    -- Should not have created any new groups
    ok, err = assert_eq(1, #mock_consumer_groups, "should not create new group")
    if not ok then error(err) end
end

function tests.test_create_group_creates_new_group_when_not_exists()
    reset_mocks()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local group = consumer_group.create_group("new-group", "new-topic")
    
    local ok, err = assert_not_nil(group, "group should be created")
    if not ok then error(err) end
    
    ok, err = assert_eq("new-group", group.name, "group name should match")
    if not ok then error(err) end
    
    ok, err = assert_eq("new-topic", group.topic_name, "topic name should match")
    if not ok then error(err) end
    
    ok, err = assert_not_nil(group.id, "group id should be generated")
    if not ok then error(err) end
    
    ok, err = assert_not_nil(group.created_at, "created_at should be set")
    if not ok then error(err) end
    
    -- Should have 1 group
    ok, err = assert_eq(1, #mock_consumer_groups, "should have 1 group")
    if not ok then error(err) end
end

function tests.test_create_group_initializes_offsets_for_all_partitions()
    reset_mocks()
    add_mock_topic("test-topic", 4)
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local group = consumer_group.create_group("test-group", "test-topic")
    
    local ok, err = assert_not_nil(group, "group should be created")
    if not ok then error(err) end
    
    -- Should have 4 offsets (one per partition)
    ok, err = assert_eq(4, #mock_offsets, "should have 4 offset records")
    if not ok then error(err) end
    
    -- Verify each partition has offset 0
    local partition_offsets = {}
    for _, o in ipairs(mock_offsets) do
        partition_offsets[o[4]] = o[5]
    end
    
    for i = 0, 3 do
        ok, err = assert_eq(0, partition_offsets[i], "partition " .. i .. " offset should be 0")
        if not ok then error(err) end
    end
end

function tests.test_create_group_handles_topic_not_exists()
    reset_mocks()
    -- No topic added
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local group = consumer_group.create_group("test-group", "non-existent-topic")
    
    local ok, err = assert_not_nil(group, "group should be created even without topic")
    if not ok then error(err) end
    
    ok, err = assert_eq("test-group", group.name, "group name should match")
    if not ok then error(err) end
    
    -- Should have 0 offsets since topic doesn't exist
    ok, err = assert_eq(0, #mock_offsets, "should have no offset records")
    if not ok then error(err) end
end

-- ============================================================================
-- TESTS FOR consumer_group.get_group
-- ============================================================================

function tests.test_get_group_returns_group_when_exists()
    reset_mocks()
    table.insert(mock_consumer_groups, {"group-id", "test-group", "test-topic", 1000})
    rebuild_indexes()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local group = consumer_group.get_group("test-group", "test-topic")
    
    local ok, err = assert_not_nil(group, "group should be found")
    if not ok then error(err) end
    
    ok, err = assert_eq("group-id", group.id, "group id should match")
    if not ok then error(err) end
    
    ok, err = assert_eq("test-group", group.name, "group name should match")
    if not ok then error(err) end
    
    ok, err = assert_eq("test-topic", group.topic_name, "topic name should match")
    if not ok then error(err) end
end

function tests.test_get_group_returns_nil_when_not_found()
    reset_mocks()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local group = consumer_group.get_group("non-existent", "non-existent-topic")
    
    local ok, err = assert_nil(group, "should return nil when not found")
    if not ok then error(err) end
end

-- ============================================================================
-- TESTS FOR consumer_group.list_groups
-- ============================================================================

function tests.test_list_groups_returns_all_groups_when_topic_nil()
    reset_mocks()
    table.insert(mock_consumer_groups, {"id1", "group1", "topic1", 1000})
    table.insert(mock_consumer_groups, {"id2", "group2", "topic2", 1001})
    table.insert(mock_consumer_groups, {"id3", "group3", "topic1", 1002})
    rebuild_indexes()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local groups = consumer_group.list_groups(nil)
    
    local ok, err = assert_eq(3, #groups, "should return all 3 groups")
    if not ok then error(err) end
end

function tests.test_list_groups_returns_only_groups_for_specific_topic()
    reset_mocks()
    table.insert(mock_consumer_groups, {"id1", "group1", "topic1", 1000})
    table.insert(mock_consumer_groups, {"id2", "group2", "topic2", 1001})
    table.insert(mock_consumer_groups, {"id3", "group3", "topic1", 1002})
    rebuild_indexes()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local groups = consumer_group.list_groups("topic1")
    
    local ok, err = assert_eq(2, #groups, "should return 2 groups for topic1")
    if not ok then error(err) end
    
    for _, g in ipairs(groups) do
        ok, err = assert_eq("topic1", g.topic_name, "all groups should be for topic1")
        if not ok then error(err) end
    end
end

function tests.test_list_groups_returns_empty_array_when_no_groups()
    reset_mocks()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local groups = consumer_group.list_groups("any-topic")
    
    local ok, err = assert_eq(0, #groups, "should return empty array")
    if not ok then error(err) end
end

-- ============================================================================
-- TESTS FOR consumer_group.delete_group
-- ============================================================================

function tests.test_delete_group_returns_false_when_not_found()
    reset_mocks()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local ok, err = consumer_group.delete_group("non-existent", "non-existent-topic")
    
    local ok2, err2 = assert_eq(false, ok, "should return false")
    if not ok2 then error(err2) end
    
    ok2, err2 = assert_eq("Group not found", err, "error message should match")
    if not ok2 then error(err2) end
end

function tests.test_delete_group_deletes_group_and_offsets()
    reset_mocks()
    add_mock_topic("test-topic", 2)
    
    -- Insert group
    table.insert(mock_consumer_groups, {"group-id", "test-group", "test-topic", 1000})
    -- Insert offsets
    table.insert(mock_offsets, {"offset-id-1", "test-group", "test-topic", 0, 5, 1001})
    table.insert(mock_offsets, {"offset-id-2", "test-group", "test-topic", 1, 10, 1002})
    rebuild_indexes()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local result, err = consumer_group.delete_group("test-group", "test-topic")
    
    local ok, err = assert_eq(true, result, "should return true")
    if not ok then error(err) end
    
    ok, err = assert_eq(0, #mock_consumer_groups, "group should be deleted")
    if not ok then error(err) end
    
    ok, err = assert_eq(0, #mock_offsets, "all offsets should be deleted")
    if not ok then error(err) end
end

function tests.test_delete_group_returns_true_on_success()
    reset_mocks()
    table.insert(mock_consumer_groups, {"group-id", "test-group", "test-topic", 1000})
    rebuild_indexes()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local result = consumer_group.delete_group("test-group", "test-topic")
    
    local ok, err = assert_eq(true, result, "should return true on success")
    if not ok then error(err) end
end

-- ============================================================================
-- TESTS FOR consumer_group.get_offsets
-- ============================================================================

function tests.test_get_offsets_returns_all_offset_records()
    reset_mocks()
    table.insert(mock_offsets, {"id1", "test-group", "test-topic", 0, 5, 1000})
    table.insert(mock_offsets, {"id2", "test-group", "test-topic", 1, 10, 1001})
    table.insert(mock_offsets, {"id3", "test-group", "test-topic", 2, 15, 1002})
    -- This one is for a different group
    table.insert(mock_offsets, {"id4", "other-group", "test-topic", 0, 1, 1003})
    rebuild_indexes()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local offsets = consumer_group.get_offsets("test-group", "test-topic")
    
    local ok, err = assert_eq(3, #offsets, "should return 3 offsets")
    if not ok then error(err) end
    
    -- Verify structure
    for _, o in ipairs(offsets) do
        ok, err = assert_not_nil(o.topic, "offset should have topic")
        if not ok then error(err) end
        ok, err = assert_not_nil(o.partition, "offset should have partition")
        if not ok then error(err) end
        ok, err = assert_not_nil(o.offset, "offset should have offset value")
        if not ok then error(err) end
    end
end

function tests.test_get_offsets_returns_empty_array_when_no_offsets()
    reset_mocks()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local offsets = consumer_group.get_offsets("test-group", "test-topic")
    
    local ok, err = assert_eq(0, #offsets, "should return empty array")
    if not ok then error(err) end
end

-- ============================================================================
-- TESTS FOR consumer_group.commit_offset
-- ============================================================================

function tests.test_commit_offset_inserts_new_offset()
    reset_mocks()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local result = consumer_group.commit_offset("test-group", "test-topic", 0, 42)
    
    local ok, err = assert_eq(42, result, "should return committed offset")
    if not ok then error(err) end
    
    ok, err = assert_eq(1, #mock_offsets, "should have 1 offset record")
    if not ok then error(err) end
    
    local offset_record = mock_offsets[1]
    ok, err = assert_eq("test-group", offset_record[2], "group name should match")
    if not ok then error(err) end
    ok, err = assert_eq("test-topic", offset_record[3], "topic name should match")
    if not ok then error(err) end
    ok, err = assert_eq(0, offset_record[4], "partition should match")
    if not ok then error(err) end
    ok, err = assert_eq(42, offset_record[5], "offset value should match")
    if not ok then error(err) end
end

function tests.test_commit_offset_updates_existing_offset()
    reset_mocks()
    table.insert(mock_offsets, {"existing-id", "test-group", "test-topic", 0, 10, 1000})
    rebuild_indexes()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local result = consumer_group.commit_offset("test-group", "test-topic", 0, 99)
    
    local ok, err = assert_eq(99, result, "should return new offset")
    if not ok then error(err) end
    
    ok, err = assert_eq(1, #mock_offsets, "should still have 1 offset record")
    if not ok then error(err) end
    
    local offset_record = mock_offsets[1]
    ok, err = assert_eq(99, offset_record[5], "offset should be updated")
    if not ok then error(err) end
end

function tests.test_commit_offset_returns_committed_offset()
    reset_mocks()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local result = consumer_group.commit_offset("test-group", "test-topic", 2, 123)
    
    local ok, err = assert_eq(123, result, "should return the offset that was committed")
    if not ok then error(err) end
end

-- ============================================================================
-- TESTS FOR consumer_group.assign_partitions
-- ============================================================================

function tests.test_assign_partitions_returns_nil_when_topic_not_found()
    reset_mocks()
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local assignments, err = consumer_group.assign_partitions("test-group", "non-existent-topic", 2)
    
    local ok, result_err = assert_nil(assignments, "should return nil")
    if not ok then error(result_err) end
    
    ok, result_err = assert_not_nil(err, "error message should be returned")
    if not ok then error(result_err) end
    
    ok, result_err = assert_eq("Topic not found", err, "error message should match")
    if not ok then error(result_err) end
end

function tests.test_assign_partitions_4_partitions_2_consumers()
    reset_mocks()
    add_mock_topic("test-topic", 4)
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local assignments = consumer_group.assign_partitions("test-group", "test-topic", 2)
    
    local ok, err = assert_not_nil(assignments, "assignments should not be nil")
    if not ok then error(err) end
    
    ok, err = assert_eq(2, #assignments, "should have 2 assignments")
    if not ok then error(err) end
    
    -- consumer-1 should get partitions [0, 1]
    ok, err = assert_eq("consumer-1", assignments[1].consumer_id, "first consumer id")
    if not ok then error(err) end
    
    ok, err = assert_eq(2, #assignments[1].partitions, "consumer-1 should have 2 partitions")
    if not ok then error(err) end
    
    ok, err = assert_eq(0, assignments[1].partitions[1], "consumer-1 first partition")
    if not ok then error(err) end
    
    ok, err = assert_eq(1, assignments[1].partitions[2], "consumer-1 second partition")
    if not ok then error(err) end
    
    -- consumer-2 should get partitions [2, 3]
    ok, err = assert_eq("consumer-2", assignments[2].consumer_id, "second consumer id")
    if not ok then error(err) end
    
    ok, err = assert_eq(2, #assignments[2].partitions, "consumer-2 should have 2 partitions")
    if not ok then error(err) end
    
    ok, err = assert_eq(2, assignments[2].partitions[1], "consumer-2 first partition")
    if not ok then error(err) end
    
    ok, err = assert_eq(3, assignments[2].partitions[2], "consumer-2 second partition")
    if not ok then error(err) end
end

function tests.test_assign_partitions_4_partitions_3_consumers()
    reset_mocks()
    add_mock_topic("test-topic", 4)
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local assignments = consumer_group.assign_partitions("test-group", "test-topic", 3)
    
    local ok, err = assert_eq(3, #assignments, "should have 3 assignments")
    if not ok then error(err) end
    
    -- Verify distribution (should be roughly even)
    local total_assigned = 0
    for _, a in ipairs(assignments) do
        total_assigned = total_assigned + #a.partitions
    end
    
    ok, err = assert_eq(4, total_assigned, "all 4 partitions should be assigned")
    if not ok then error(err) end
    
    -- Collect all assigned partitions
    local all_partitions = {}
    for _, a in ipairs(assignments) do
        for _, p in ipairs(a.partitions) do
            table.insert(all_partitions, p)
        end
    end
    
    -- Each partition should be assigned exactly once
    table.sort(all_partitions)
    for i = 0, 3 do
        ok, err = assert_eq(i, all_partitions[i + 1], "partition " .. i .. " should be assigned")
        if not ok then error(err) end
    end
end

function tests.test_assign_partitions_more_consumers_than_partitions()
    reset_mocks()
    add_mock_topic("test-topic", 2)
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local assignments = consumer_group.assign_partitions("test-group", "test-topic", 4)
    
    local ok, err = assert_eq(2, #assignments, "should only have assignments for available partitions")
    if not ok then error(err) end
    
    -- First 2 consumers should get partitions
    ok, err = assert_eq(1, #assignments[1].partitions, "consumer-1 should have 1 partition")
    if not ok then error(err) end
    
    ok, err = assert_eq(1, #assignments[2].partitions, "consumer-2 should have 1 partition")
    if not ok then error(err) end
    
    -- Consumers 3 and 4 should not exist (not enough partitions)
    ok, err = assert_eq(nil, assignments[3], "no third assignment")
    if not ok then error(err) end
end

function tests.test_assign_partitions_zero_consumers()
    reset_mocks()
    add_mock_topic("test-topic", 4)
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local assignments = consumer_group.assign_partitions("test-group", "test-topic", 0)
    
    local ok, err = assert_eq(0, #assignments, "should return empty assignments")
    if not ok then error(err) end
end

function tests.test_assign_partitions_topic_with_zero_partitions()
    reset_mocks()
    add_mock_topic("empty-topic", 0)
    
    local consumer_group = require("tarantoolmq.internal.consumer_group")
    local assignments = consumer_group.assign_partitions("test-group", "empty-topic", 2)
    
    local ok, err = assert_eq(0, #assignments, "should return empty array for 0 partitions")
    if not ok then error(err) end
end

-- ============================================================================
-- MAIN
-- ============================================================================

function main()
    print("===========================================")
    print("Consumer Group Unit Tests (with mocks)")
    print("===========================================")
    
    -- Test create_group
    print("\n--- create_group Tests ---")
    test("Returns existing group if already exists", tests.test_create_group_returns_existing_group_if_exists)
    test("Creates new group when not exists", tests.test_create_group_creates_new_group_when_not_exists)
    test("Initializes offsets for all partitions", tests.test_create_group_initializes_offsets_for_all_partitions)
    test("Handles case when topic doesn't exist", tests.test_create_group_handles_topic_not_exists)
    
    -- Test get_group
    print("\n--- get_group Tests ---")
    test("Returns group when exists", tests.test_get_group_returns_group_when_exists)
    test("Returns nil when not found", tests.test_get_group_returns_nil_when_not_found)
    
    -- Test list_groups
    print("\n--- list_groups Tests ---")
    test("Returns all groups when topic_name is nil", tests.test_list_groups_returns_all_groups_when_topic_nil)
    test("Returns only groups for specific topic", tests.test_list_groups_returns_only_groups_for_specific_topic)
    test("Returns empty array when no groups", tests.test_list_groups_returns_empty_array_when_no_groups)
    
    -- Test delete_group
    print("\n--- delete_group Tests ---")
    test("Returns false with error when group not found", tests.test_delete_group_returns_false_when_not_found)
    test("Deletes group and all offset records", tests.test_delete_group_deletes_group_and_offsets)
    test("Returns true on success", tests.test_delete_group_returns_true_on_success)
    
    -- Test get_offsets
    print("\n--- get_offsets Tests ---")
    test("Returns all offset records for group/topic", tests.test_get_offsets_returns_all_offset_records)
    test("Returns empty array when no offsets", tests.test_get_offsets_returns_empty_array_when_no_offsets)
    
    -- Test commit_offset
    print("\n--- commit_offset Tests ---")
    test("Inserts new offset if none exists", tests.test_commit_offset_inserts_new_offset)
    test("Updates existing offset", tests.test_commit_offset_updates_existing_offset)
    test("Returns the offset that was committed", tests.test_commit_offset_returns_committed_offset)
    
    -- Test assign_partitions
    print("\n--- assign_partitions Tests ---")
    test("Returns nil when topic not found", tests.test_assign_partitions_returns_nil_when_topic_not_found)
    test("4 partitions, 2 consumers", tests.test_assign_partitions_4_partitions_2_consumers)
    test("4 partitions, 3 consumers", tests.test_assign_partitions_4_partitions_3_consumers)
    test("More consumers than partitions", tests.test_assign_partitions_more_consumers_than_partitions)
    test("num_consumers = 0", tests.test_assign_partitions_zero_consumers)
    test("Topic with 0 partitions", tests.test_assign_partitions_topic_with_zero_partitions)
    
    print("\n===========================================")
    print(string.format("Results: %d passed, %d failed", passed, failed))
    print("===========================================")
    
    os.exit(failed > 0 and 1 or 0)
end

main()
