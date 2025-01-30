# Python-playground

This is a playground for Python projects. It contains various scripts and examples to help you get started with Python programming.

## Generate ssh config from plain text file

### Usage

`input.txt`:
```
123.123.21.123  fronted
123.123.23.198  backend
```

```bash
./generate_ssh_config.py -i input.txt -o output.txt -u root -p prefix-
```

## Change key in JSONL file by random integer

### Usage

`input.jsonl`:
```jsonl
{"key": "asdfas", "value": "1234"}
{"key": "asdfas", "value": "1234"}
{"key": "asdfas", "value": "1234"}
{"key": "asdfas", "value": "1234"}
{"key": "asdfas", "value": "1234"}
{"key": "asdfas", "value": "1234"}
{"key": "asdfas", "value": "1234"}
{"key": "asdfas", "value": "1234"}
{"key": "asdfas", "value": "1234"}
```

```bash
./change_key_by_randint.py --input input.jsonl --output output.example.jsonl --key value --min 1 --max 1000
```