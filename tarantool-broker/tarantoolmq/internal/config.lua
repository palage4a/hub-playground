local fun = require("fun")

local config = {}

local DEFAULT_CONFIG = {
    host = "0.0.0.0",
    port = 8080,
    memtx_dir = "var/lib/tarantool/memtx",
    vinyl_dir = "var/lib/tarantool/vinyl",
    default_partitions = 4,
    default_replication_factor = 1,
    default_retention_seconds = 604800,
    default_retention_bytes = 1073741824,
    acks = "leader",
    retries = 3,
    retry_backoff_ms = 100,
    max_poll_records = 500,
    session_timeout_ms = 30000,
    request_timeout_ms = 30000,
    min_insync_replicas = 1,
    log_dir = "var/log",
}

function config.load(path)
    local cfg = {}
    for k, v in pairs(DEFAULT_CONFIG) do
        cfg[k] = v
    end

    if path then
        local f = loadfile(path)
        if f then
            local user_cfg = f()
            for k, v in pairs(user_cfg or {}) do
                cfg[k] = v
            end
        end
    end

    return setmetatable(cfg, {
        __index = function(_, key)
            return rawget(_, key) or DEFAULT_CONFIG[key]
        end
    })
end

function config.validate(cfg)
    local errors = {}

    if cfg.port < 1 or cfg.port > 65535 then
        table.insert(errors, "port must be between 1 and 65535")
    end

    if cfg.default_partitions < 1 then
        table.insert(errors, "default_partitions must be at least 1")
    end

    if cfg.default_replication_factor < 1 then
        table.insert(errors, "default_replication_factor must be at least 1")
    end

    if not fun.any(function(x) return x == cfg.acks end, {"all", "leader", "none"}) then
        table.insert(errors, "acks must be 'all', 'leader', or 'none'")
    end

    return #errors == 0, errors
end

return config
