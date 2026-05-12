#!/usr/bin/env python3
"""Simple load generator to stress the HPA example application."""
import concurrent.futures
import requests
import sys
import time

SERVICE_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:80"
REQUESTS = int(sys.argv[2]) if len(sys.argv) > 2 else 200
WORKERS = int(sys.argv[3]) if len(sys.argv) > 3 else 10

def send_load(_):
    try:
        resp = requests.get(f"{SERVICE_URL}/load", timeout=30)
        return resp.status_code
    except Exception as e:
        return f"error: {e}"

def main():
    print(f"Target: {SERVICE_URL}")
    print(f"Sending {REQUESTS} requests with {WORKERS} concurrent workers...")
    start = time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=WORKERS) as pool:
        results = list(pool.map(send_load, range(REQUESTS)))
    elapsed = time.time() - start

    ok = sum(1 for r in results if r == 200)
    err = len(results) - ok
    print(f"\nDone in {elapsed:.1f}s")
    print(f"  Success: {ok}/{len(results)}")
    print(f"  Errors:  {err}/{len(results)}")
    print(f"  RPS:     {len(results)/elapsed:.1f}")

if __name__ == "__main__":
    main()