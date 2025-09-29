# Nats playgournd

Simple nats cluster for benchmarking.
Nats three-note cluster with single stream with file storage.
Replication factor set to 3.

## Preparations

Install nats-server binary in the current directory:
```
curl -fsSL https://binaries.nats.dev/nats-io/nats-server/v2@v2.12.0 | sh
```

Install nats CLI tool for benchmarking (requires golang):
```
go install github.com/nats-io/natscli/nats@v0.3.0
```

Create stream:

Stream with 3 replicas (sync replication ???)
file storage
without any limits

```
nats stream add test_stream \
  --replicas=3 \
  --cluster=cluster1 \
  --retention=limits \
  --storage=file \
  --subjects=subj \
  --discard=old \
  --max-age=-1 \
  --max-msgs=-1 \
  --max-msg-size=-1 \
  --max-bytes=-1 \
  --dupe-window=2y \
  --no-allow-rollup \
  --no-deny-delete \
  --no-deny-purge \
  --max-msgs-per-subject=-1 \
  --user=test \
  --password=test
```

Start three nodes:

```
nats-server -c n1.conf
nats-server -c n2.conf
nats-server -c n3.conf
```

## Benchmarks

Publishing:

```
nats bench js pub sync \
    --clients 1 \
    --msgs 1e6 \
    --size 1024B \
    --purge \
    --stream test_stream \
    --user test \
    --password test \
    subj
```

Consuming:

```
nats bench js consume \
    --clients 1 \
    --msgs 1e6 \
    --stream test_stream \
    --user test \
    --password test
```
