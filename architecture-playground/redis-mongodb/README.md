# Redis + MongoDB Sharded Cluster

This Docker Compose configuration sets up a complete data infrastructure with:
- **MongoDB Sharded Cluster**: Config server, 2 shards (each with 3 replicas), and mongos router
- **Redis Cluster**: 6-node Redis cluster with replication

## Architecture

### MongoDB Sharded Cluster
- **Config Server**: Single node replica set for cluster metadata
- **Shard 1**: 3-node replica set (shard1a: primary, shard1b: secondary, shard1c: secondary)
- **Shard 2**: 3-node replica set (shard2a: primary, shard2b: secondary, shard2c: secondary)
- **Mongos Router**: Query router for the sharded cluster

### Redis Cluster
- 6-node cluster with 3 masters and 3 replicas

## Quick Start

Start all services:

```bash
docker compose up -d
```

## MongoDB Sharded Cluster Setup

### 1. Initialize Config Server

Connect to the config server:

```bash
docker compose exec configSrv mongosh --port 27027
```

Initialize the config server replica set:

```javascript
rs.initiate({
  _id: "config_server",
  configsvr: true,
  members: [
    { _id: 0, host: "configSrv:27027" }
  ]
});
```

### 2. Initialize Shard 1 Replica Set

Connect to the first shard node:

```bash
docker compose exec shard1a mongosh --port 27028
```

Initialize the replica set with 3 members:

```javascript
rs.initiate({
  _id: "shard1rs",
  members: [
    { _id: 0, host: "shard1a:27028" },
    { _id: 1, host: "shard1b:27029" },
    { _id: 2, host: "shard1c:27030" }
  ]
});
```

Check replica set status:

```javascript
rs.status()
```

### 3. Initialize Shard 2 Replica Set

Connect to the first shard node:

```bash
docker compose exec shard2a mongosh --port 27031
```

Initialize the replica set with 3 members:

```javascript
rs.initiate({
  _id: "shard2rs",
  members: [
    { _id: 0, host: "shard2a:27031" },
    { _id: 1, host: "shard2b:27032" },
    { _id: 2, host: "shard2c:27033" }
  ]
});
```

Check replica set status:

```javascript
rs.status()
```

### 4. Configure Mongos Router

Connect to the mongos router:

```bash
docker compose exec mongos_router mongosh --port 27034
```

Add both shards to the cluster:

```javascript
sh.addShard("shard1rs/shard1a:27028,shard1b:27029,shard1c:27030");
sh.addShard("shard2rs/shard2a:27031,shard2b:27032,shard2c:27033");
```

Verify shard status:

```javascript
sh.status()
```

### 5. Enable Sharding

Enable sharding for a database and collection:

```javascript
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name": "hashed" });
```

### 6. Test Sharding

Insert test data to verify distribution across shards:

```javascript
use somedb;

for (var i = 0; i < 1000; i++) {
  db.helloDoc.insert({ age: i, name: "ly" + i });
}

db.helloDoc.countDocuments();
```

Expected result: `1000`

### 7. Verify Data Distribution

Check documents on each shard primary:

**Shard 1 (connect to primary):**
```bash
docker compose exec shard1a mongosh --port 27028
```

```javascript
use somedb;
db.helloDoc.countDocuments();
```

**Shard 2 (connect to primary):**
```bash
docker compose exec shard2a mongosh --port 27031
```

```javascript
use somedb;
db.helloDoc.countDocuments();
```

The total count across both shards should equal 1000.

## Redis Cluster

### 1. Create Cluster

Connect to any Redis container:

```bash
docker compose exec redis_1 bash
```

Create the cluster with 3 masters and 3 replicas:

```bash
echo "yes" | redis-cli --cluster create \
  173.17.0.2:6379 \
  173.17.0.3:6379 \
  173.17.0.4:6379 \
  173.17.0.5:6379 \
  173.17.0.6:6379 \
  173.17.0.7:6379 \
  --cluster-replicas 1
```

### 2. Verify Cluster

```bash
redis-cli cluster nodes
```

## Service Ports

| Service | Port | Description |
|---------|------|-------------|
| configSrv | 27027 | Config server |
| shard1a | 27028 | Shard 1 primary |
| shard1b | 27029 | Shard 1 secondary |
| shard1c | 27030 | Shard 1 secondary |
| shard2a | 27031 | Shard 2 primary |
| shard2b | 27032 | Shard 2 secondary |
| shard2c | 27033 | Shard 2 secondary |
| mongos_router | 27034 | Query router |
| redis_1-6 | 6379 | Redis cluster nodes |

## Replica Sets Summary

| Replica Set | Members | Ports |
|-------------|---------|-------|
| config_server | configSrv | 27027 |
| shard1rs | shard1a, shard1b, shard1c | 27028-27030 |
| shard2rs | shard2a, shard2b, shard2c | 27031-27033 |

## Troubleshooting

### Check Replica Set Status

```javascript
rs.status()
```

### Check Sharding Status

```javascript
sh.status()
```

### View Cluster Configuration

```javascript
db.getSiblingDB("config").shards.find()
```

## Cleanup

Stop and remove all containers and volumes:

```bash
docker compose down --volumes
```
