#!/usr/bin/env python3

import json
import random
import argparse

def main():
    parser = argparse.ArgumentParser(description='Replace values in JSONL file with random numbers')
    parser.add_argument('--input', required=True, help='Input JSONL file path')
    parser.add_argument('--output', required=True, help='Output JSONL file path')
    parser.add_argument('--key', required=True, help='JSON key to replace')
    parser.add_argument('--min', type=int, required=True, help='Minimum value')
    parser.add_argument('--max', type=int, required=True, help='Maximum value')
    
    args = parser.parse_args()
    
    if args.min > args.max:
        raise ValueError("Error: min value cannot be greater than max value")
    
    random.seed()  # Инициализация генератора случайных чисел
    
    with open(args.input, 'r') as infile, open(args.output, 'w') as outfile:
        count = 0
        for line_number, line in enumerate(infile, 1):
            line = line.strip()
            if not line:
                continue
            
            try:
                data = json.loads(line)
                if args.key in data:
                    new_value = random.randint(int(args.min), int(args.max))
                    data[args.key] = f"{new_value}"
                outfile.write(json.dumps(data) + '\n')
                count += 1
            except json.JSONDecodeError as e:
                print(f"Error decoding JSON at line {line_number}: {e}")
            except Exception as e:
                print(f"Error processing line {line_number}: {e}")
        print(f"Successfully processed {count} lines.")

if __name__ == "__main__":
    main()