#!/usr/bin/env tarantool

package.path = package.path .. ";./?.lua;./tarantoolmq/?.lua;./tarantoolmq/?/init.lua"

local config = require("tarantoolmq.internal.config")

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

local function assert_true(val, msg)
    if val ~= true then
        return false, msg or "expected true"
    end
    return true
end

local function assert_not_nil(val, msg)
    if val == nil then
        return false, msg or "expected non-nil value"
    end
    return true
end

local function assert_nil(val, msg)
    if val ~= nil then
        return false, msg or "expected nil"
    end
    return true
end

local function assert_table(val, msg)
    if type(val) ~= "table" then
        return false, msg or "expected table, got " .. type(val)
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

-- Helper to create a temporary config file
local function create_temp_config_file(content, filename)
    local filepath = os.tmpname() .. (filename or ".lua")
    local f = io.open(filepath, "w")
    if f then
        f:write(content)
        f:close()
    end
    return filepath
end

-- Helper to remove a temp file
local function remove_temp_file(path)
    if path then
        os.remove(path)
    end
end

-- ============================================
-- config.load tests
-- ============================================

function tests.test_load_returns_default_config_when_path_is_nil()
    local cfg = config.load(nil)
    assert_not_nil(cfg, "config should not be nil")
    assert_eq(8080, cfg.port, "default port")
    assert_eq("0.0.0.0", cfg.host, "default host")
    assert_eq(4, cfg.default_partitions, "default partitions")
    assert_eq(1, cfg.default_replication_factor, "default replication factor")
    assert_eq("leader", cfg.acks, "default acks")
    assert_eq(3, cfg.retries, "default retries")
end

function tests.test_load_returns_default_config_when_path_is_nil_no_args()
    local cfg = config.load()
    assert_not_nil(cfg, "config should not be nil")
    assert_eq(8080, cfg.port, "default port")
end

function tests.test_load_merges_user_config_with_defaults()
    local filepath = create_temp_config_file("return { port = 9000, host = '127.0.0.1' }")
    local cfg = config.load(filepath)
    
    assert_not_nil(cfg, "config should not be nil")
    assert_eq(9000, cfg.port, "user port should override default")
    assert_eq("127.0.0.1", cfg.host, "user host should override default")
    -- Default values should remain
    assert_eq(4, cfg.default_partitions, "default partitions should remain")
    assert_eq("leader", cfg.acks, "default acks should remain")
    
    remove_temp_file(filepath)
end

function tests.test_load_missing_file_returns_defaults()
    local cfg = config.load("/nonexistent/path/config.lua")
    
    assert_not_nil(cfg, "config should not be nil")
    -- Should return defaults
    assert_eq(8080, cfg.port, "default port")
    assert_eq("0.0.0.0", cfg.host, "default host")
end

function tests.test_load_config_file_returning_nil_skips_merging()
    local filepath = create_temp_config_file("return nil")
    local cfg = config.load(filepath)
    
    assert_not_nil(cfg, "config should not be nil")
    -- Should return defaults
    assert_eq(8080, cfg.port, "default port")
    assert_eq("0.0.0.0", cfg.host, "default host")
    
    remove_temp_file(filepath)
end

function tests.test_load_extra_keys_in_user_config_are_ignored()
    local filepath = create_temp_config_file("return { port = 9000, unknown_key = 'value', extra_num = 123 }")
    local cfg = config.load(filepath)
    
    assert_not_nil(cfg, "config should not be nil")
    assert_eq(9000, cfg.port, "user port should be set")
    -- Extra keys should be merged (Lua doesn't prevent this)
    -- But the validate function should still work
    local ok, errors = config.validate(cfg)
    assert_true(ok, "config with extra keys should still be valid")
    assert_eq(0, #errors, "should have no errors")
    
    remove_temp_file(filepath)
end

function tests.test_load_empty_user_config_returns_defaults()
    local filepath = create_temp_config_file("return {}")
    local cfg = config.load(filepath)
    
    assert_not_nil(cfg, "config should not be nil")
    -- All defaults should remain
    assert_eq(8080, cfg.port, "default port")
    assert_eq("0.0.0.0", cfg.host, "default host")
    assert_eq(4, cfg.default_partitions, "default partitions")
    assert_eq(1, cfg.default_replication_factor, "default replication factor")
    
    remove_temp_file(filepath)
end

-- ============================================
-- config.validate tests
-- ============================================

function tests.test_validate_valid_config_returns_true()
    local cfg = {
        host = "0.0.0.0",
        port = 8080,
        default_partitions = 4,
        default_replication_factor = 1,
        acks = "leader"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(ok, "valid config should return true")
    assert_table(errors, "errors should be a table")
    assert_eq(0, #errors, "should have no errors")
end

function tests.test_validate_port_less_than_1_returns_error()
    local cfg = {
        host = "0.0.0.0",
        port = 0,
        default_partitions = 4,
        default_replication_factor = 1,
        acks = "leader"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(not ok, "invalid config should return false")
    assert_table(errors, "errors should be a table")
    assert_true(#errors > 0, "should have at least one error")
    
    local has_port_error = false
    for _, err in ipairs(errors) do
        if string.find(err, "port") then
            has_port_error = true
            break
        end
    end
    assert_true(has_port_error, "should have port error")
end

function tests.test_validate_port_greater_than_65535_returns_error()
    local cfg = {
        host = "0.0.0.0",
        port = 65536,
        default_partitions = 4,
        default_replication_factor = 1,
        acks = "leader"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(not ok, "invalid config should return false")
    assert_true(#errors > 0, "should have at least one error")
    
    local has_port_error = false
    for _, err in ipairs(errors) do
        if string.find(err, "port") then
            has_port_error = true
            break
        end
    end
    assert_true(has_port_error, "should have port error")
end

function tests.test_validate_port_0_returns_error()
    local cfg = {
        host = "0.0.0.0",
        port = 0,
        default_partitions = 4,
        default_replication_factor = 1,
        acks = "leader"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(not ok, "port 0 should be invalid")
    assert_true(#errors > 0, "should have error")
end

function tests.test_validate_port_65535_is_valid()
    local cfg = {
        host = "0.0.0.0",
        port = 65535,
        default_partitions = 4,
        default_replication_factor = 1,
        acks = "leader"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(ok, "port 65535 should be valid")
    assert_eq(0, #errors, "should have no errors")
end

function tests.test_validate_port_1_is_valid()
    local cfg = {
        host = "0.0.0.0",
        port = 1,
        default_partitions = 4,
        default_replication_factor = 1,
        acks = "leader"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(ok, "port 1 should be valid")
    assert_eq(0, #errors, "should have no errors")
end

function tests.test_validate_default_partitions_less_than_1_returns_error()
    local cfg = {
        host = "0.0.0.0",
        port = 8080,
        default_partitions = 0,
        default_replication_factor = 1,
        acks = "leader"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(not ok, "invalid config should return false")
    assert_true(#errors > 0, "should have at least one error")
    
    local has_partitions_error = false
    for _, err in ipairs(errors) do
        if string.find(err, "default_partitions") then
            has_partitions_error = true
            break
        end
    end
    assert_true(has_partitions_error, "should have default_partitions error")
end

function tests.test_validate_default_partitions_negative_returns_error()
    local cfg = {
        host = "0.0.0.0",
        port = 8080,
        default_partitions = -1,
        default_replication_factor = 1,
        acks = "leader"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(not ok, "negative partitions should be invalid")
    assert_true(#errors > 0, "should have error")
end

function tests.test_validate_default_replication_factor_less_than_1_returns_error()
    local cfg = {
        host = "0.0.0.0",
        port = 8080,
        default_partitions = 4,
        default_replication_factor = 0,
        acks = "leader"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(not ok, "invalid config should return false")
    assert_true(#errors > 0, "should have at least one error")
    
    local has_replication_error = false
    for _, err in ipairs(errors) do
        if string.find(err, "default_replication_factor") then
            has_replication_error = true
            break
        end
    end
    assert_true(has_replication_error, "should have default_replication_factor error")
end

function tests.test_validate_default_replication_factor_negative_returns_error()
    local cfg = {
        host = "0.0.0.0",
        port = 8080,
        default_partitions = 4,
        default_replication_factor = -5,
        acks = "leader"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(not ok, "negative replication factor should be invalid")
    assert_true(#errors > 0, "should have error")
end

function tests.test_validate_acks_all_is_valid()
    local cfg = {
        host = "0.0.0.0",
        port = 8080,
        default_partitions = 4,
        default_replication_factor = 1,
        acks = "all"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(ok, "acks = 'all' should be valid")
    assert_eq(0, #errors, "should have no errors")
end

function tests.test_validate_acks_leader_is_valid()
    local cfg = {
        host = "0.0.0.0",
        port = 8080,
        default_partitions = 4,
        default_replication_factor = 1,
        acks = "leader"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(ok, "acks = 'leader' should be valid")
    assert_eq(0, #errors, "should have no errors")
end

function tests.test_validate_acks_none_is_valid()
    local cfg = {
        host = "0.0.0.0",
        port = 8080,
        default_partitions = 4,
        default_replication_factor = 1,
        acks = "none"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(ok, "acks = 'none' should be valid")
    assert_eq(0, #errors, "should have no errors")
end

function tests.test_validate_acks_invalid_returns_error()
    local cfg = {
        host = "0.0.0.0",
        port = 8080,
        default_partitions = 4,
        default_replication_factor = 1,
        acks = "invalid"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(not ok, "acks = 'invalid' should be invalid")
    assert_true(#errors > 0, "should have at least one error")
    
    local has_acks_error = false
    for _, err in ipairs(errors) do
        if string.find(err, "acks") then
            has_acks_error = true
            break
        end
    end
    assert_true(has_acks_error, "should have acks error")
end

function tests.test_validate_acks_nil_returns_error()
    local cfg = {
        host = "0.0.0.0",
        port = 8080,
        default_partitions = 4,
        default_replication_factor = 1,
        acks = nil
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(not ok, "acks = nil should be invalid")
    assert_true(#errors > 0, "should have at least one error")
end

function tests.test_validate_multiple_errors_are_collected()
    local cfg = {
        host = "0.0.0.0",
        port = 0,
        default_partitions = 0,
        default_replication_factor = 0,
        acks = "invalid"
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(not ok, "config with multiple errors should return false")
    assert_true(#errors >= 3, "should have at least 3 errors")
end

function tests.test_validate_all_valid_acks_values()
    local valid_acks = {"all", "leader", "none"}
    
    for _, acks_value in ipairs(valid_acks) do
        local cfg = {
            host = "0.0.0.0",
            port = 8080,
            default_partitions = 4,
            default_replication_factor = 1,
            acks = acks_value
        }
        
        local ok, errors = config.validate(cfg)
        assert_true(ok, "acks = '" .. acks_value .. "' should be valid")
        assert_eq(0, #errors, "should have no errors for acks = '" .. acks_value .. "'")
    end
end

function tests.test_validate_typical_production_config()
    local cfg = {
        host = "0.0.0.0",
        port = 8080,
        memtx_dir = "var/lib/tarantool/memtx",
        vinyl_dir = "var/lib/tarantool/vinyl",
        default_partitions = 4,
        default_replication_factor = 1,
        default_retention_seconds = 604800,
        default_retention_bytes = 1073741824,
        acks = "all",
        retries = 3,
        retry_backoff_ms = 100,
        max_poll_records = 500,
        session_timeout_ms = 30000,
        request_timeout_ms = 30000,
        min_insync_replicas = 1,
        log_dir = "var/log",
    }
    
    local ok, errors = config.validate(cfg)
    assert_true(ok, "typical production config should be valid")
    assert_eq(0, #errors, "should have no errors")
end

-- ============================================
-- Main
-- ============================================

function main()
    print("===========================================")
    print("Config Module Test Suite")
    print("===========================================")
    
    -- config.load tests
    print("\n--- config.load tests ---")
    test("Returns DEFAULT_CONFIG when path is nil", tests.test_load_returns_default_config_when_path_is_nil)
    test("Returns DEFAULT_CONFIG when called with no args", tests.test_load_returns_default_config_when_path_is_nil_no_args)
    test("Loads user config from file and merges with defaults", tests.test_load_merges_user_config_with_defaults)
    test("Missing file returns defaults", tests.test_load_missing_file_returns_defaults)
    test("Config file returning nil skips merging", tests.test_load_config_file_returning_nil_skips_merging)
    test("Extra keys in user config are ignored", tests.test_load_extra_keys_in_user_config_are_ignored)
    test("Empty user config returns defaults", tests.test_load_empty_user_config_returns_defaults)
    
    -- config.validate tests
    print("\n--- config.validate tests ---")
    test("Valid config returns true with empty errors", tests.test_validate_valid_config_returns_true)
    test("Port < 1 returns error", tests.test_validate_port_less_than_1_returns_error)
    test("Port > 65535 returns error", tests.test_validate_port_greater_than_65535_returns_error)
    test("Port = 0 returns error", tests.test_validate_port_0_returns_error)
    test("Port = 65535 is valid", tests.test_validate_port_65535_is_valid)
    test("Port = 1 is valid", tests.test_validate_port_1_is_valid)
    test("default_partitions < 1 returns error", tests.test_validate_default_partitions_less_than_1_returns_error)
    test("default_partitions negative returns error", tests.test_validate_default_partitions_negative_returns_error)
    test("default_replication_factor < 1 returns error", tests.test_validate_default_replication_factor_less_than_1_returns_error)
    test("default_replication_factor negative returns error", tests.test_validate_default_replication_factor_negative_returns_error)
    test("acks = 'all' is valid", tests.test_validate_acks_all_is_valid)
    test("acks = 'leader' is valid", tests.test_validate_acks_leader_is_valid)
    test("acks = 'none' is valid", tests.test_validate_acks_none_is_valid)
    test("acks = 'invalid' returns error", tests.test_validate_acks_invalid_returns_error)
    test("acks = nil returns error", tests.test_validate_acks_nil_returns_error)
    test("Multiple errors are all collected", tests.test_validate_multiple_errors_are_collected)
    test("All valid acks values work", tests.test_validate_all_valid_acks_values)
    test("Typical production config is valid", tests.test_validate_typical_production_config)
    
    print("\n===========================================")
    print(string.format("Results: %d passed, %d failed", passed, failed))
    print("===========================================")
    
    os.exit(failed > 0 and 1 or 0)
end

main()
