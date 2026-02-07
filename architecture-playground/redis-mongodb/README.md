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
