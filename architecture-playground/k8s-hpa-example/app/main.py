from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import time
import os

PORT = int(os.environ.get("PORT", 8080))

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            response = {"message": "Hello from HPA example!", "status": "ok"}
            self.wfile.write(json.dumps(response).encode())
        elif self.path == "/load":
            # CPU-intensive work to trigger HPA scaling
            start = time.time()
            result = 0
            for i in range(5_000_000):
                result += i * i
            elapsed = time.time() - start
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            response = {"message": "Load processed", "elapsed_s": round(elapsed, 3)}
            self.wfile.write(json.dumps(response).encode())
        elif self.path == "/healthz":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"OK")
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # Suppress logs for cleaner output

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"Server listening on port {PORT}")
    server.serve_forever()