local http_server = require("http.server")
local json = require("json")

local topic_manager = require("tarantoolmq.internal.topic_manager")
local message_log = require("tarantoolmq.internal.message_log")
local consumer_group = require("tarantoolmq.internal.consumer_group")

local gateway = {}

local function json_response(status, body)
    return {
        status = status,
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = json.encode(body)
    }
end

local function parse_json(body)
    local ok, result = pcall(json.decode, body)
    if not ok then
        return nil, "Invalid JSON"
    end
    return result
end

local routes = {}

function routes.handle_request(req)
    local path, query
    -- Handle both string requests and table requests
    if type(req) == "string" then
        path = req:match("^([^?]+)")
        query = req:match("%?(.+)$")
    else
        path = req.path and req.path:match("^([^?]+)") or ""
        query = req.path and req.path:match("%?(.+)$")
    end
    
    local method = req.method
    local body = req.body

    if method == "GET" and path == "/topics" then
        local topics = topic_manager.list_topics()
        return json_response(200, {topics = topics})
    end

    if method == "POST" and path == "/topics" then
        local params = parse_json(body)
        if not params or not params.name then
            return json_response(400, {error = "Missing topic name"})
        end

        local topic = topic_manager.create_topic(params.name, {
            default_partitions = params.partitions,
            default_replication_factor = params.replication_factor,
            default_retention_seconds = params.retention_seconds,
            default_retention_bytes = params.retention_bytes
        })

        return json_response(201, topic)
    end

    if method == "GET" and path:match("^/topics/([^/]+)$") then
        local topic_name = path:match("^/topics/([^/]+)$")
        local topic = topic_manager.get_topic(topic_name)
        if not topic then
            return json_response(404, {error = "Topic not found"})
        end

        local partitions = topic_manager.get_partitions(topic_name)
        return json_response(200, {
            topic = topic,
            partitions = partitions
        })
    end

    if method == "DELETE" and path:match("^/topics/([^/]+)$") then
        local topic_name = path:match("^/topics/([^/]+)$")
        local ok, err = topic_manager.delete_topic(topic_name)
        if not ok then
            return json_response(404, {error = err})
        end
        return json_response(200, {deleted = true})
    end

    if method == "POST" and path:match("^/topics/([^/]+)/messages$") then
        local topic_name = path:match("^/topics/([^/]+)/messages$")
        local params = parse_json(body)
        if not params or not params.value then
            return json_response(400, {error = "Missing message value"})
        end

        local partition_id = params.partition
        if not partition_id then
            local topic = topic_manager.get_topic(topic_name)
            if topic then
                if params.key then
                    partition_id = math.abs(math.hash(params.key) % topic.partitions)
                else
                    partition_id = math.random(0, topic.partitions - 1)
                end
            end
        end

        local result, err = message_log.produce(
            topic_name,
            partition_id,
            params.key,
            params.value,
            params.headers,
            {acks = params.acks or "leader"}
        )

        if err then
            return json_response(400, {error = err})
        end

        return json_response(200, result)
    end

    if method == "GET" and path:match("^/topics/([^/]+)/partitions/([^/]+)/messages$") then
        local topic_name, partition_id_str = path:match("^/topics/([^/]+)/partitions/([^/]+)/messages$")
        local partition_id = tonumber(partition_id_str)
        
        local offset = 0
        if query then
            for k, v in query:gmatch("([^=]+)=([^&]*)") do
                if k == "offset" then
                    offset = tonumber(v) or 0
                end
            end
        end

        local max_records = 100
        if query then
            for k, v in query:gmatch("([^=]+)=([^&]*)") do
                if k == "max_records" then
                    max_records = tonumber(v) or 100
                end
            end
        end

        local messages = message_log.consume(topic_name, partition_id, offset, max_records)
        return json_response(200, {messages = messages})
    end

    if method == "POST" and path:match("^/consumers/([^/]+)/groups$") then
        local group_name = path:match("^/consumers/([^/]+)/groups$")
        local params = parse_json(body)
        if not params or not params.topic_name then
            return json_response(400, {error = "Missing topic_name"})
        end

        local group = consumer_group.create_group(group_name, params.topic_name)
        return json_response(201, group)
    end

    if method == "GET" and path:match("^/consumers/([^/]+)/offsets$") then
        local group_name = path:match("^/consumers/([^/]+)/offsets$")
        local topic_name = nil
        
        if query then
            for k, v in query:gmatch("([^=]+)=([^&]*)") do
                if k == "topic" then
                    topic_name = v
                end
            end
        end

        local offsets = consumer_group.get_offsets(group_name, topic_name)
        return json_response(200, {offsets = offsets})
    end

    if method == "POST" and path:match("^/consumers/([^/]+)/offsets$") then
        local group_name = path:match("^/consumers/([^/]+)/offsets$")
        local params = parse_json(body)
        if not params or not params.topic_name or params.partition == nil or params.offset == nil then
            return json_response(400, {error = "Missing required params"})
        end

        consumer_group.commit_offset(group_name, params.topic_name, params.partition, params.offset)
        return json_response(200, {committed = true})
    end

    if method == "GET" and path:match("^/topics/([^/]+)/partitions/([^/]+)/offsets$") then
        local topic_name, partition_id_str = path:match("^/topics/([^/]+)/partitions/([^/]+)/offsets$")
        local partition_id = tonumber(partition_id_str)

        local high = message_log.get_high_watermark(topic_name, partition_id)
        local low = message_log.get_low_watermark(topic_name, partition_id)
        
        return json_response(200, {
            high_watermark = high,
            low_watermark = low
        })
    end

    if method == "GET" and path == "/health" then
        return json_response(200, {status = "healthy"})
    end

    return json_response(404, {error = "Not found"})
end

function gateway.start(config)
    local server = http_server.new(config.host, config.port, {
        app_name = "tarantoolmq"
    })

    server:route({path = "/", method = "GET"}, function(req)
        return json_response(200, {
            service = "TarantoolMQ",
            version = "0.1.0",
            endpoints = {
                "GET /topics",
                "POST /topics",
                "GET /topics/:name",
                "DELETE /topics/:name",
                "POST /topics/:name/messages",
                "GET /topics/:name/partitions/:id/messages",
                "POST /consumers/:group/groups",
                "GET /consumers/:group/offsets",
                "POST /consumers/:group/offsets",
                "GET /topics/:name/partitions/:id/offsets",
                "GET /health"
            }
        })
    end)

    server:route({path = "/.*", method = "GET"}, routes.handle_request)
    server:route({path = "/.*", method = "POST"}, routes.handle_request)
    server:route({path = "/.*", method = "DELETE"}, routes.handle_request)

    server:start()
    print(string.format("TarantoolMQ HTTP Gateway started on %s:%d", config.host, config.port))
    
    return server
end

-- Export functions for testing
gateway.json_response = json_response
gateway.parse_json = parse_json
gateway.handle_request = routes.handle_request

return gateway
