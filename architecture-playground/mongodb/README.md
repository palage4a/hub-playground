# MongoDB replication


1. Start 3 mongo db instances

```
docker compose up -d
```

2. Log in to first mongodb instance by mongosh

```
docker compose exec mongodb1 mongosh
```

3. Start replication

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

5. Shut down mongo

```
docker compose down --volumes
```
