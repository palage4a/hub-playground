# Redis + MongoDB cluster

1. Start cluster

```
docker compose up -d
```

## Mongo DB

2. Log in to first mongodb instance by mongosh

```
docker compose exec mongodb1 mongosh
```

3. Setup replication for mongo db cluster

```
rs.initiate({_id: "rs0", members: [
{_id: 0, host: "mongodb1:27017"},
{_id: 1, host: "mongodb2:27018"},
{_id: 2, host: "mongodb3:27019"}
]})
```

"Status: Ok" should be received.

4. Check replication status

```
rs.status()
```

## Redis Cluster

5. Connect to redis container

```
docker compose exec -it redis_1 bash
```

6. Connect redis instances into replicate cluster.

```
echo "yes" | \
    redis-cli --cluster create \
        173.17.0.2:6379 \
        173.17.0.3:6379 \
        173.17.0.4:6379 \
        173.17.0.5:6379 \
        173.17.0.6:6379 \
        173.17.0.7:6379 \
        --cluster-replicas 1
```


7. View cluster nodes

```
redis-cli cluster nodes
```

5. Shut down cluster

```
docker compose down --volumes
```


# sharded mongo

```
docker compose -f compose.yaml.sharding up -d
```

Connect to mongo config server 

```
docker compose -f compose.yaml.sharding exec -it configSrv mongosh --port 27017
```

Setup config server

```
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
```

Setup shards

Shard 1

```
docker compose -f compose.yaml.sharding exec -it shard1 mongosh --port 27018
```

Shard 1

```
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27018" },
       // { _id : 1, host : "shard2:27019" }
      ]
    }
);
```

Shard 2

```
docker compose -f compose.yaml.sharding exec -it shard2 mongosh --port 27019
```

```
rs.initiate(
    {
      _id : "shard2",
      members: [
       // { _id : 0, host : "shard1:27018" },
        { _id : 1, host : "shard2:27019" }
      ]
    }
  );
```


Setup router 

```
docker compose -f compose.yaml.sharding exec -it mongos_router mongosh --port 27020
```

```
sh.addShard( "shard1/shard1:27018");
sh.addShard( "shard2/shard2:27019");


sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

use somedb

for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})

db.helloDoc.countDocuments() 
```

Number of documents must be equal 1000.


Check sharding on shards

Shard 1

```
docker compose -f compose.yaml.sharding exec -it shard1 mongosh --port 27018
```

```
use somedb;

db.helloDoc.countDocuments();
```

Shard 2

```
docker compose -f compose.yaml.sharding exec -it shard2 mongosh --port 27019
```

```
use somedb;

db.helloDoc.countDocuments();
```
