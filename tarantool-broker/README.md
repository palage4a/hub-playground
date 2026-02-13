# TarantoolMQ

A distributed message queue system similar to Apache Kafka, built on Tarantool 3.

## Quick Start

```bash
# Start the server
tarantool tarantoolmq.lua

# Or with custom config
tarantool tarantoolmq.lua --config config.lua --port 9090
```

## Running Tests

```bash
tarantool test_runner.lua
```

## API Examples

### Create a Topic

```bash
curl -X POST http://localhost:8080/topics \
  -H "Content-Type: application/json" \
  -d '{"name": "my-topic", "partitions": 4}'
```

### List Topics

```bash
curl http://localhost:8080/topics
```

### Produce Messages

```bash
curl -X POST http://localhost:8080/topics/my-topic/messages \
  -H "Content-Type: application/json" \
  -d '{"key": "user-1", "value": "Hello World", "partition": 0}'
```

### Consume Messages

```bash
curl "http://localhost:8080/topics/my-topic/partitions/0/messages?offset=0&max_records=10"
```

### Create Consumer Group

```bash
curl -X POST http://localhost:8080/consumers/my-group/groups \
  -H "Content-Type: application/json" \
  -d '{"topic_name": "my-topic"}'
```

### Commit Offset

```bash
curl -X POST http://localhost:8080/consumers/my-group/offsets \
  -H "Content-Type: application/json" \
  -d '{"topic_name": "my-topic", "partition": 0, "offset": 5}'
```

### Get Offsets

```bash
curl "http://localhost:8080/consumers/my-group/offsets?topic=my-topic"
```

### Get Partition Offsets

```bash
curl http://localhost:8080/topics/my-topic/partitions/0/offsets
```

### Delete Topic

```bash
curl -X DELETE http://localhost:8080/topics/my-topic
```

### Health Check

```bash
curl http://localhost:8080/health
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed design decisions.

## Features

- **Topic-based messaging**: Organize messages into topics
- **Partitioning**: Distribute load across partitions
- **Consumer groups**: Shared subscription with offset management
- **At-least-once delivery**: Ack-based delivery guarantee
- **Retention policies**: Time and size-based message retention
- **HTTP API**: RESTful interface for producers/consumers

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `host` | "0.0.0.0" | HTTP server host |
| `port` | 8080 | HTTP server port |
| `default_partitions` | 4 | Default partitions per topic |
| `default_retention_seconds` | 604800 | 7 days retention |
| `acks` | "leader" | Acknowledgment level |

## License

MIT
