# Redis + MongoDB Cluster

This Docker Compose configuration sets up a complete data infrastructure with:
- **MongoDB Replication**: 3-node replica set for high availability
- **MongoDB Sharding**: Config server, 2 shards, and mongos router for horizontal scaling
- **Redis Cluster**: 6-node Redis cluster with replication

## Quick Start

Start all services:

```bash
docker compose up -d
```

## MongoDB Replication

The replication setup consists of 3 MongoDB instances (ports 27017-27019).

### 1. Initialize Replication

Connect to the primary instance:

```bash
docker compose exec mongodb1 mongosh
```

Initialize the replica set:

```javascript
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongodb1:27017" },
    { _id: 1, host: "mongodb2:27018" },
    { _id: 2, host: "mongodb3:27019" }
  ]
})
```

Expected output: `"ok": 1`

### 2. Verify Replication Status

```javascript
rs.status()
```

## MongoDB Sharding

The sharding setup includes a config server, 2 shards, and a mongos router (ports 27027-27030).

### 1. Initialize Config Server

Connect to the config server:

```bash
docker compose exec configSrv mongosh --port 27027
```

Initialize:

```javascript
rs.initiate({
  _id: "config_server",
  configsvr: true,
  members: [
    { _id: 0, host: "configSrv:27027" }
  ]
});
```

### 2. Initialize Shards

#### Shard 1

```bash
docker compose exec shard1 mongosh --port 27028
```

```javascript
rs.initiate({
  _id: "shard1",
  members: [
    { _id: 0, host: "shard1:27028" }
  ]
});
```

#### Shard 2

```bash
docker compose exec shard2 mongosh --port 27029
```

```javascript
rs.initiate({
  _id: "shard2",
  members: [
    { _id: 0, host: "shard2:27029" }
  ]
});
```

### 3. Configure Router

Connect to the mongos router:

```bash
docker compose exec mongos_router mongosh --port 27030
```

Add shards to the cluster:

```javascript
sh.addShard("shard1/shard1:27028");
sh.addShard("shard2/shard2:27029");
```

Enable sharding for a database and collection:

```javascript
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name": "hashed" });
```

### 4. Test Sharding

Insert test data:

```javascript
use somedb;

for (var i = 0; i < 1000; i++) {
  db.helloDoc.insert({ age: i, name: "ly" + i });
}

db.helloDoc.countDocuments();
```

Expected result: `1000`

### 5. Verify Data Distribution

Check documents on each shard:

**Shard 1:**
```bash
docker compose exec shard1 mongosh --port 27028
```

```javascript
use somedb;
db.helloDoc.countDocuments();
```

**Shard 2:**
```bash
docker compose exec shard2 mongosh --port 27029
```

```javascript
use somedb;
db.helloDoc.countDocuments();
```

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
| mongodb1 | 27017 | Replica set primary |
| mongodb2 | 27018 | Replica set secondary |
| mongodb3 | 27019 | Replica set secondary |
| configSrv | 27027 | Config server for sharding |
| shard1 | 27028 | Shard 1 |
| shard2 | 27029 | Shard 2 |
| mongos_router | 27030 | MongoDB query router |
| redis_1-6 | 6379 | Redis cluster nodes |

## Cleanup

Stop and remove all containers and volumes:

```bash
docker compose down --volumes
```
