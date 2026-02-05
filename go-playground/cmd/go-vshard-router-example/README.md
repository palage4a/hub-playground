# Go vshard router example

## Prepare tarantool

``` shell
cd cmd/go-vshard-router-example;
tt build tarantool;
tt start tarantool;
```

## Start test service

``` shell
$ go run cmd/go-vshard-router-example/main.go
result: [[868086711418421420 1365 Ivan 10]]
typed result: {868086711418421420 1365 Ivan 10}
```
