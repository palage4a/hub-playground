# Hello-world like tarantool app

## Quick start

Download tarantool sdk or use existed.

Build an app:

```shell
tt build app
```

To start each application, use `tt`, for example:
```shell
tt start app
```

Check an instance health, for example:
```shell
tt connect client:secret@localhost:3301 << EOF
box.info()
EOF
```
