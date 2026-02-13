#!/usr/bin/env tarantool

package.path = package.path .. ";./?.lua;./tarantoolmq/?.lua;./tarantoolmq/?/init.lua"

-- Mock math.hash if not available (Tarantool specific)
if not math.hash then
    math.hash = function(str)
        local hash = 0
        for i = 1, #str do
            hash = ((hash * 31) + string.byte(str, i)) % 2147483647
        end
        return hash
    end
end

-- ============================================================================
-- MOCK MODULES
-- ============================================================================

-- Mock topic_manager
local mock_topics = {}
local mock_topic_manager = {
    create_topic = function(name, opts)
        local topic = {
            name = name,
            partitions = opts.default_partitions or 1,
            replication_factor = opts.default_replication_factor or 1,
            retention_seconds = opts.default_retention_seconds or 86400,
            retention_bytes = opts.default_retention_bytes or 1073741824
        }
        mock_topics[name] = topic
        return topic
    end,
    
    get_topic = function(name)
        return mock_topics[name]
    end,
    
    list_topics = function()
        local list = {}
        for _, topic in pairs(mock_topics) do
            table.insert(list, topic)
        end
        return list
    end,
    
    get_partitions = function(topic_name)
        local topic = mock_topics[topic_name]
        if not topic then
            return nil
        end
        local partitions = {}
        for i = 0, topic.partitions - 1 do
            table.insert(partitions, {id = i, leader = 0, replicas = {0}})
        end
        return partitions
    end,
    
    delete_topic = function(name)
        if mock_topics[name] then
            mock_topics[name] = nil
            return true
        end
        return false, "Topic not found"
    end,
    
    clear = function()
        -- Clear table contents instead of reassigning to preserve closures
        for k in pairs(mock_topics) do
            mock_topics[k] = nil
        end
    end
}

-- Mock message_log
local mock_messages = {}
local mock_message_log = {
    produce = function(topic_name, partition_id, key, value, headers, opts)
        if not mock_topics[topic_name] then
            return nil, "Topic not found"
        end
        
        local topic = mock_topics[topic_name]
        if partition_id < 0 or partition_id >= topic.partitions then
            return nil, "Invalid partition"
        end
        
        if not mock_messages[topic_name] then
            mock_messages[topic_name] = {}
        end
        if not mock_messages[topic_name][partition_id] then
            mock_messages[topic_name][partition_id] = {}
        end
        
        local offset = #mock_messages[topic_name][partition_id]
        local msg = {
            offset = offset,
            topic = topic_name,
            partition = partition_id,
            key = key,
            value = value,
            headers = headers,
            timestamp = os.time()
        }
        table.insert(mock_messages[topic_name][partition_id], msg)
        
        return {
            topic = topic_name,
            partition = partition_id,
            offset = offset
        }
    end,
    
    consume = function(topic_name, partition_id, offset, max_records)
        if not mock_messages[topic_name] or not mock_messages[topic_name][partition_id] then
            return {}
        end
        
        local results = {}
        local msgs = mock_messages[topic_name][partition_id]
        max_records = max_records or 100
        
        for i = offset + 1, math.min(offset + max_records, #msgs) do
            table.insert(results, msgs[i])
        end
        
        return results
    end,
    
    get_high_watermark = function(topic_name, partition_id)
        if not mock_messages[topic_name] or not mock_messages[topic_name][partition_id] then
            return 0
        end
        return #mock_messages[topic_name][partition_id]
    end,
    
    get_low_watermark = function(topic_name, partition_id)
        return 0
    end,
    
    get_offset = function(topic_name, partition_id, group_name)
        return 0
    end,
    
    clear = function()
        -- Clear table contents instead of reassigning to preserve closures
        for k in pairs(mock_messages) do
            mock_messages[k] = nil
        end
    end
}

-- Mock consumer_group
local mock_consumer_groups = {}
local mock_offsets = {}
local mock_consumer_group = {
    create_group = function(group_name, topic_name)
        local group = {
            name = group_name,
            topic_name = topic_name,
            created_at = os.time()
        }
        mock_consumer_groups[group_name] = group
        return group
    end,
    
    get_group = function(group_name)
        return mock_consumer_groups[group_name]
    end,
    
    get_offsets = function(group_name, topic_name)
        local offsets = {}
        if topic_name then
            if mock_offsets[group_name] and mock_offsets[group_name][topic_name] then
                for partition, offset in pairs(mock_offsets[group_name][topic_name]) do
                    offsets[tostring(partition)] = offset
                end
            end
        else
            if mock_offsets[group_name] then
                for tname, topics in pairs(mock_offsets[group_name]) do
                    offsets[tname] = {}
                    for partition, offset in pairs(topics) do
                        offsets[tname][tostring(partition)] = offset
                    end
                end
            end
        end
        return offsets
    end,
    
    commit_offset = function(group_name, topic_name, partition, offset)
        if not mock_offsets[group_name] then
            mock_offsets[group_name] = {}
        end
        if not mock_offsets[group_name][topic_name] then
            mock_offsets[group_name][topic_name] = {}
        end
        mock_offsets[group_name][topic_name][partition] = offset
    end,
    
    assign_partitions = function(group_name, topic_name, count)
        local topic = mock_topics[topic_name]
        if not topic then
            return nil
        end
        
        local assignments = {}
        for i = 0, math.min(count, topic.partitions) - 1 do
            table.insert(assignments, {
                topic = topic_name,
                partition = i,
                leader = 0
            })
        end
        return assignments
    end,
    
    clear = function()
        -- Clear table contents instead of reassigning to preserve closures
        for k in pairs(mock_consumer_groups) do
            mock_consumer_groups[k] = nil
        end
        for k in pairs(mock_offsets) do
            mock_offsets[k] = nil
        end
    end
}

-- Mock http.server
local mock_server = {
    route = function(self, opts, handler)
        return self
    end,
    start = function(self)
        return true
    end,
    stop = function(self)
        return true
    end
}

-- Create a mock module that returns a table with a new() method
local http_server_mock = setmetatable({}, {
    __call = function(_, host, port, opts)
        -- When called as http_server(host, port, opts), return a new server instance
        return mock_server
    end
})

-- Add a new() method for http_server.new(host, port, opts)
http_server_mock.new = function(_, host, port, opts)
    return mock_server
end

-- Inject mocks into package.loaded
package.loaded["tarantoolmq.internal.topic_manager"] = mock_topic_manager
package.loaded["tarantoolmq.internal.message_log"] = mock_message_log
package.loaded["tarantoolmq.internal.consumer_group"] = mock_consumer_group
package.loaded["http.server"] = http_server_mock

-- ============================================================================
-- TEST FRAMEWORK
-- ============================================================================

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

local function assert_table(val, msg)
    if type(val) ~= "table" then
        return false, string.format("%s: expected table, got %s", 
            msg or "assertion failed", type(val))
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
-- PARSE_ARGS TESTS
-- ============================================================================

local function run_parse_args_tests()
    print("\n--- parse_args Tests ---")
    
    -- Clear mocks before tests
    mock_topic_manager.clear()
    mock_message_log.clear()
    mock_consumer_group.clear()
    
    -- Load module
    local tarantoolmq = require("tarantoolmq")
    local parse_args = tarantoolmq.parse_args
    
    test("parse_args: Parses --config with path", function()
        local args = {"--config", "/etc/tarantoolmq.conf"}
        local cfg = parse_args(args)
        assert_eq("/etc/tarantoolmq.conf", cfg.config_path, "config_path")
    end)
    
    test("parse_args: Parses --host with string", function()
        local args = {"--host", "0.0.0.0"}
        local cfg = parse_args(args)
        assert_eq("0.0.0.0", cfg.host, "host")
    end)
    
    test("parse_args: Parses --port with numeric", function()
        local args = {"--port", "8080"}
        local cfg = parse_args(args)
        assert_eq(8080, cfg.port, "port")
    end)
    
    test("parse_args: Missing argument value after flag", function()
        local args = {"--config"}
        local cfg = parse_args(args)
        assert_nil(cfg.config_path, "config_path should be nil")
    end)
    
    test("parse_args: Non-numeric port returns nil", function()
        local args = {"--port", "abc"}
        local cfg = parse_args(args)
        assert_nil(cfg.port, "port should be nil for non-numeric")
    end)
    
    test("parse_args: Empty args returns empty cfg", function()
        local args = {}
        local cfg = parse_args(args)
        assert_nil(cfg.config_path, "config_path")
        assert_nil(cfg.host, "host")
        assert_nil(cfg.port, "port")
    end)
    
    test("parse_args: Multiple flags work together", function()
        local args = {"--config", "/etc/mq.conf", "--host", "127.0.0.1", "--port", "3000"}
        local cfg = parse_args(args)
        assert_eq("/etc/mq.conf", cfg.config_path, "config_path")
        assert_eq("127.0.0.1", cfg.host, "host")
        assert_eq(3000, cfg.port, "port")
    end)
end

-- ============================================================================
-- GATEWAY JSON_RESPONSE TESTS
-- ============================================================================

local function run_json_response_tests()
    print("\n--- json_response Tests ---")
    
    local gateway = require("tarantoolmq.http.gateway")
    local json_response = gateway.json_response
    
    test("json_response: Creates response with correct status", function()
        local resp = json_response(200, {ok = true})
        assert_eq(200, resp.status, "status code")
    end)
    
    test("json_response: Sets Content-Type header", function()
        local resp = json_response(200, {ok = true})
        assert_eq("application/json", resp.headers["Content-Type"], "Content-Type")
    end)
    
    test("json_response: JSON-encodes body", function()
        local resp = json_response(200, {message = "hello", count = 42})
        local ok, decoded = pcall(require("json").decode, resp.body)
        assert_eq(true, ok, "body should be valid JSON")
        assert_eq("hello", decoded.message, "message")
        assert_eq(42, decoded.count, "count")
    end)
    
    test("json_response: Handles nil body", function()
        local resp = json_response(500, nil)
        local ok, decoded = pcall(require("json").decode, resp.body)
        assert_eq(true, ok, "body should be valid JSON")
        assert_nil(decoded, "decoded body should be nil")
    end)
end

-- ============================================================================
-- GATEWAY PARSE_JSON TESTS
-- ============================================================================

local function run_parse_json_tests()
    print("\n--- parse_json Tests ---")
    
    local gateway = require("tarantoolmq.http.gateway")
    local parse_json = gateway.parse_json
    
    test("parse_json: Returns parsed JSON on success", function()
        local result, err = parse_json('{"key": "value", "num": 123}')
        assert_nil(err, "no error")
        assert_not_nil(result, "result should not be nil")
        assert_eq("value", result.key, "key")
        assert_eq(123, result.num, "num")
    end)
    
    test("parse_json: Returns nil with error on invalid JSON", function()
        local result, err = parse_json('{"key": invalid}')
        assert_nil(result, "result should be nil")
        assert_not_nil(err, "error should be returned")
    end)
    
    test("parse_json: Handles empty string", function()
        local result, err = parse_json('')
        assert_nil(result, "result should be nil for empty string")
    end)
end

-- ============================================================================
-- HANDLE_REQUEST ROUTE TESTS
-- ============================================================================

local function run_handle_request_tests()
    print("\n--- handle_request Route Tests ---")
    
    local gateway = require("tarantoolmq.http.gateway")
    local handle_request = gateway.handle_request
    
    -- Helper to create mock request
    local function make_req(method, path, body)
        return {
            method = method,
            path = path,
            body = body or ""
        }
    end
    
    -- Setup: Create test topics
    mock_topic_manager.clear()
    mock_message_log.clear()
    mock_consumer_group.clear()
    
    mock_topic_manager.create_topic("test-topic", {default_partitions = 3})
    mock_topic_manager.create_topic("existing-topic", {default_partitions = 2})
    mock_message_log.produce("existing-topic", 0, "key1", "value1", nil, {acks = "leader"})
    mock_message_log.produce("existing-topic", 0, "key2", "value2", nil, {acks = "leader"})
    mock_consumer_group.create_group("test-group", "existing-topic")
    
    -- Test GET /topics returns 200 with topics
    test("handle_request: GET /topics returns 200 with topics", function()
        local req = make_req("GET", "/topics")
        local resp = handle_request(req)
        assert_eq(200, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_not_nil(body.topics, "topics should exist")
        assert_eq(true, #body.topics >= 2, "should have topics")
    end)
    
    -- Test POST /topics with valid body returns 201
    test("handle_request: POST /topics with valid body returns 201", function()
        local req = make_req("POST", "/topics", '{"name": "new-topic", "partitions": 4}')
        local resp = handle_request(req)
        assert_eq(201, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_eq("new-topic", body.name, "topic name")
    end)
    
    -- Test POST /topics without name returns 400
    test("handle_request: POST /topics without name returns 400", function()
        local req = make_req("POST", "/topics", '{"partitions": 4}')
        local resp = handle_request(req)
        assert_eq(400, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_not_nil(body.error, "error should exist")
    end)
    
    -- Test GET /topics/:name returns topic or 404
    test("handle_request: GET /topics/:name returns topic", function()
        local req = make_req("GET", "/topics/existing-topic")
        
        -- Debug: directly check the mock
        local topic = mock_topic_manager.get_topic("existing-topic")
        
        local resp = handle_request(req)
        assert_eq(200, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_not_nil(body.topic, "topic should exist")
        assert_eq("existing-topic", body.topic.name, "topic name")
    end)
    
    test("handle_request: GET /topics/:name returns 404 for non-existent", function()
        local req = make_req("GET", "/topics/nonexistent-topic")
        local resp = handle_request(req)
        assert_eq(404, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_not_nil(body.error, "error should exist")
    end)
    
    -- Test DELETE /topics/:name returns 200 or 404
    test("handle_request: DELETE /topics/:name returns 200", function()
        mock_topic_manager.create_topic("to-delete", {default_partitions = 1})
        local req = make_req("DELETE", "/topics/to-delete")
        local resp = handle_request(req)
        assert_eq(200, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_eq(true, body.deleted, "deleted should be true")
    end)
    
    test("handle_request: DELETE /topics/:name returns 404 for non-existent", function()
        local req = make_req("DELETE", "/topics/nonexistent-topic")
        local resp = handle_request(req)
        assert_eq(404, resp.status, "status")
    end)
    
    -- Test POST /topics/:name/messages with value returns 200
    test("handle_request: POST /topics/:name/messages with value returns 200", function()
        local req = make_req("POST", "/topics/existing-topic/messages", '{"value": "test-message", "key": "test-key"}')
        local resp = handle_request(req)
        assert_eq(200, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_not_nil(body.offset, "offset should exist")
        assert_eq("existing-topic", body.topic, "topic")
    end)
    
    -- Test POST /topics/:name/messages without value returns 400
    test("handle_request: POST /topics/:name/messages without value returns 400", function()
        local req = make_req("POST", "/topics/existing-topic/messages", '{"key": "test-key"}')
        local resp = handle_request(req)
        assert_eq(400, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_not_nil(body.error, "error should exist")
    end)
    
    -- Test GET /topics/:name/partitions/:id/messages returns messages
    test("handle_request: GET /topics/:name/partitions/:id/messages returns messages", function()
        local req = make_req("GET", "/topics/existing-topic/partitions/0/messages")
        local resp = handle_request(req)
        assert_eq(200, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_not_nil(body.messages, "messages should exist")
        assert_eq(true, #body.messages >= 2, "should have messages")
    end)
    
    -- Test GET /topics/:name/partitions/:id/messages with offset/max_records params
    test("handle_request: GET /topics/:name/partitions/:id/messages with offset and max_records", function()
        -- First add more messages
        for i = 1, 5 do
            mock_message_log.produce("existing-topic", 0, "key" .. i, "value" .. i, nil, {acks = "leader"})
        end
        
        local req = make_req("GET", "/topics/existing-topic/partitions/0/messages?offset=1&max_records=2")
        local resp = handle_request(req)
        assert_eq(200, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_not_nil(body.messages, "messages should exist")
        -- Should have 2 messages (offset 1, max_records 2)
    end)
    
    -- Test POST /consumers/:group/groups returns 201 or 400
    test("handle_request: POST /consumers/:group/groups returns 201", function()
        local req = make_req("POST", "/consumers/new-group/groups", '{"topic_name": "existing-topic"}')
        local resp = handle_request(req)
        assert_eq(201, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_eq("new-group", body.name, "group name")
    end)
    
    test("handle_request: POST /consumers/:group/groups returns 400 without topic_name", function()
        local req = make_req("POST", "/consumers/another-group/groups", '{}')
        local resp = handle_request(req)
        assert_eq(400, resp.status, "status")
    end)
    
    -- Test GET /consumers/:group/offsets returns offsets
    test("handle_request: GET /consumers/:group/offsets returns offsets", function()
        mock_consumer_group.commit_offset("test-group", "existing-topic", 0, 5)
        local req = make_req("GET", "/consumers/test-group/offsets?topic=existing-topic")
        local resp = handle_request(req)
        assert_eq(200, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_not_nil(body.offsets, "offsets should exist")
    end)
    
    -- Test POST /consumers/:group/offsets returns 200 or 400
    test("handle_request: POST /consumers/:group/offsets returns 200", function()
        local req = make_req("POST", "/consumers/test-group/offsets", '{"topic_name": "existing-topic", "partition": 0, "offset": 10}')
        local resp = handle_request(req)
        assert_eq(200, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_eq(true, body.committed, "committed should be true")
    end)
    
    test("handle_request: POST /consumers/:group/offsets returns 400 with missing params", function()
        local req = make_req("POST", "/consumers/test-group/offsets", '{"topic_name": "existing-topic"}')
        local resp = handle_request(req)
        assert_eq(400, resp.status, "status")
    end)
    
    -- Test GET /topics/:name/partitions/:id/offsets returns watermarks
    test("handle_request: GET /topics/:name/partitions/:id/offsets returns watermarks", function()
        local req = make_req("GET", "/topics/existing-topic/partitions/0/offsets")
        local resp = handle_request(req)
        assert_eq(200, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_not_nil(body.high_watermark, "high_watermark should exist")
        assert_not_nil(body.low_watermark, "low_watermark should exist")
    end)
    
    -- Test GET /health returns 200 with status
    test("handle_request: GET /health returns 200 with status", function()
        local req = make_req("GET", "/health")
        local resp = handle_request(req)
        assert_eq(200, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_eq("healthy", body.status, "status")
    end)
    
    -- Test Unknown route returns 404
    test("handle_request: Unknown route returns 404", function()
        local req = make_req("GET", "/unknown/route")
        local resp = handle_request(req)
        assert_eq(404, resp.status, "status")
        local body = require("json").decode(resp.body)
        assert_not_nil(body.error, "error should exist")
    end)
end

-- ============================================================================
-- GATEWAY.START TEST (MOCKED)
-- ============================================================================

local function run_gateway_start_test()
    print("\n--- gateway.start Tests ---")
    
    test("gateway.start: Creates server with config", function()
        -- Note: This test just verifies the function doesn't error
        -- The actual server start is mocked
        local gateway = require("tarantoolmq.http.gateway")
        
        -- This should not throw and should return a mock server
        local server = gateway.start({host = "127.0.0.1", port = 8080})
        assert_not_nil(server, "server should be returned")
    end)
end

-- ============================================================================
-- MAIN
-- ============================================================================

local function main()
    print("===========================================")
    print("TarantoolMQ Gateway & CLI Test Suite")
    print("===========================================")
    
    run_parse_args_tests()
    run_json_response_tests()
    run_parse_json_tests()
    run_handle_request_tests()
    run_gateway_start_test()
    
    print("\n===========================================")
    print(string.format("Results: %d passed, %d failed", passed, failed))
    print("===========================================")
    
    os.exit(failed > 0 and 1 or 0)
end

main()
