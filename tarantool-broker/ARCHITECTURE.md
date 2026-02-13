# TarantoolMQ - Distributed Message Queue System

## Architecture Overview

TarantoolMQ is a distributed message queue system inspired by Apache Kafka, built on Tarantool 3. It provides high-throughput, fault-tolerant message streaming with persistent storage and consumer group support.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           TarantoolMQ Architecture                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐            │
│  │  Producer 1  │     │  Producer 2  │     │  Producer N  │            │
│  └──────┬───────┘     └──────┬───────┘     └──────┬───────┘            │
│         │                    │                    │                    │
│         └────────────────────┼────────────────────┘                    │
│                              │                                           │
│                              ▼                                           │
│                    ┌─────────────────┐                                  │
│                    │   HTTP API       │                                  │
│                    │   Gateway        │                                  │
│                    └────────┬────────┘                                  │
│                             │                                            │
│         ┌───────────────────┼───────────────────┐                       │
│         │                   │                   │                       │
│         ▼                   ▼                   ▼                       │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐                │
│  │   Topic     │     │   Topic     │     │   Topic     │                │
│  │  Manager    │     │  Manager    │     │  Manager    │                │
│  └──────┬──────┘     └──────┬──────┘     └──────┬──────┘                │
│         │                   │                   │                        │
│         ▼                   ▼                   ▼                        │
│  ┌─────────────────────────────────────────────────────┐                │
│  │              Partition Layer                         │                │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐              │                │
│  │  │Part 0   │  │Part 1   │  │Part N   │              │                │
│  │  │[Leader] │  │[Leader] │  │[Leader] │              │                │
│  │  └─────────┘  └─────────┘  └─────────┘              │                │
│  └─────────────────────────────────────────────────────┘                │
│         │                   │                   │                        │
│         ▼                   ▼                   ▼                        │
│  ┌─────────────────────────────────────────────────────┐                │
│  │              Storage Layer (Tarantool)              │                │
│  │  - Message Log (vinyl)                              │                │
│  │  - Index (memtx)                                     │                │
│  │  - WAL (snapshots)                                   │                │
│  └─────────────────────────────────────────────────────┘                │
│                                                                          │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐            │
│  │Consumer Grp1│     │Consumer Grp2  │     │Consumer GrpN │            │
│  │[offset mgr] │     │[offset mgr]  │     │[offset mgr] │            │
│  └──────────────┘     └──────────────┘     └──────────────┘            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Design Decisions

### 1. Storage Strategy

- **Primary Index (memtx)**: For fast offset lookups and metadata
- **Secondary Storage (vinyl)**: For message logs - provides better compression and scan performance
- **WAL (Write-Ahead Log)**: For durability and crash recovery

### 2. Partitioning

- **Hash Partitioning**: Messages partitioned by key hash for ordering guarantees
- **Round-Robin**: When no key provided
- **Partition Count**: Configurable per topic (default: 4)

### 3. Replication

- **Leader-Follower Model**: Each partition has one leader, configurable replicas
- **Async Replication**: For throughput, with configurable acknowledgment
- **Failover**: Automatic leader election on replica failure

### 4. Message Delivery

- **At-Least-Once**: Achieved via acknowledgment + offset commit
- **Exactly-Once**: Transaction support for producers (future enhancement)
- **Retries**: Configurable retry count and backoff

### 5. Consumer Groups

- **Shared Subscription**: One message delivered to one consumer per group
- **Offset Management**: Stored in Tarantool, per (topic, partition, group)
- **Rebalancing**: On consumer join/leave

## Key Modules

| Module | Responsibility |
|--------|----------------|
| `topic_manager` | Topic CRUD, partition allocation |
| `partition_manager` | Partition leadership, replica sync |
| `message_log` | Message storage, retention policies |
| `consumer_group` | Group membership, offset tracking |
| `producer` | Message publishing, partitioning |
| `consumer` | Message consumption, acknowledgment |
| `http_gateway` | REST API endpoints |
| `config` | Configuration management |

## Configuration Options

```lua
local config = {
    -- Server
    host = "0.0.0.0",
    port = 8080,

    -- Storage
    memtx_dir = "var/lib/tarantool/memtx",
    vinyl_dir = "var/lib/tarantool/vinyl",
    
    -- Topic defaults
    default_partitions = 4,
    default_replication_factor = 1,
    default_retention_seconds = 604800,  -- 7 days
    default_retention_bytes = 1073741824,  -- 1GB
    
    -- Producer
    acks = "leader",  -- "all", "leader", "none"
    retries = 3,
    retry_backoff_ms = 100,
    
    -- Consumer
    max_poll_records = 500,
    session_timeout_ms = 30000,
    
    -- Network
    request_timeout_ms = 30000,
}
```

## Performance Considerations

1. **Batch Publishing**: Aggregate messages before sending
2. **Compression**: LZ4 for messages, zstd for storage
3. **Zero-Copy**: Direct memory operations where possible
4. **Connection Pooling**: Reuse HTTP connections
5. **Index Optimization**: Composite indexes for common queries
