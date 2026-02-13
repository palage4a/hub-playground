#!/usr/bin/env tarantool

package.path = package.path .. ";./?.lua;./tarantoolmq/?.lua;./tarantoolmq/?/init.lua"

local storage = require("tarantoolmq.internal.storage")
local config = require("tarantoolmq.internal.config")
local gateway = require("tarantoolmq.http.gateway")

local function parse_args(args)
    local cfg = {}
    for i = 1, #args do
        if args[i] == "--config" and args[i + 1] then
            cfg.config_path = args[i + 1]
            i = i + 1
        elseif args[i] == "--host" and args[i + 1] then
            cfg.host = args[i + 1]
            i = i + 1
        elseif args[i] == "--port" and args[i + 1] then
            cfg.port = tonumber(args[i + 1])
            i = i + 1
        end
    end
    return cfg
end

local function main(args)
    local cli_args = parse_args(args)
    
    local cfg = config.load(cli_args.config_path)
    
    local ok, err = config.validate(cfg)
    if not ok then
        print("Configuration error: " .. table.concat(err, ", "))
        os.exit(1)
    end

    print("Initializing TarantoolMQ...")
    storage.init()
    
    print("Starting HTTP Gateway...")
    gateway.start(cfg)
    
    print("TarantoolMQ is ready!")
    
    return true
end

if os.getenv("TARANTOOL_VERSION_NUM") then
    local args = {...}
    main(args)
end

return {
    main = main,
    parse_args = parse_args
}
