#!/usr/bin/env python3
"""
A simple HTTP server with routing capabilities using Python's built-in http.server module.
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import urllib.parse


class Router:
    """A simple router for mapping URL paths to handler functions."""
    
    def __init__(self):
        self.routes = {}
    
    def add_route(self, path, handler):
        """Add a route mapping a path to a handler function."""
        self.routes[path] = handler
    
    def get_handler_for_path(self, path):
        """Get the appropriate handler for a given path."""
        return self.routes.get(path)
    
    def handle_404(self, request_handler):
        """Handle 404 Not Found errors."""
        request_handler.send_response(404)
        request_handler.send_header('Content-type', 'text/html')
        request_handler.end_headers()
        response = "<h1>404 - Page Not Found</h1><p>The requested page could not be found.</p>"
        request_handler.wfile.write(response.encode())


class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
    def __init__(self, *args, router=None, **kwargs):
        # Use provided router or create a default one
        if router is not None:
            self.router = router
        else:
            # Create a default router
            self.router = Router()
            
            # Register routes
            self.router.add_route('/', self.handle_home)
            self.router.add_route('/about', self.handle_about)
            self.router.add_route('/api/users', self.handle_api_users)
            self.router.add_route('/api/status', self.handle_api_status)
        
        super().__init__(*args, **kwargs)

    def do_GET(self):
        """Handle GET requests"""
        # Parse the URL to get the path
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        
        # Check if we have a handler for this route
        handler = self.router.get_handler_for_path(path)
        if handler:
            handler()
        else:
            self.router.handle_404(self)
            
    def get_handler_for_path(self, path):
        """Get the appropriate handler for a given path"""
        return self.router.get_handler_for_path(path)

    def handle_home(self):
        """Handler for the home route"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        response = "<h1>Welcome to the Simple Server</h1><p>This is the home page.</p>"
        self.wfile.write(response.encode())

    def handle_about(self):
        """Handler for the about route"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        response = "<h1>About Us</h1><p>This is the about page.</p>"
        self.wfile.write(response.encode())

    def handle_api_users(self):
        """Handler for the users API endpoint"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        response = {
            "users": [
                {"id": 1, "name": "Alice"},
                {"id": 2, "name": "Bob"}
            ]
        }
        self.wfile.write(json.dumps(response).encode())

    def handle_api_status(self):
        """Handler for the status API endpoint"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        response = {"status": "OK", "message": "Server is running"}
        self.wfile.write(json.dumps(response).encode())


def run_server(port=8000):
    """Run the HTTP server"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, SimpleHTTPRequestHandler)
    print(f"Starting server on port {port}...")
    print("Available routes:")
    print("  / - Home page")
    print("  /about - About page")
    print("  /api/users - JSON API for users")
    print("  /api/status - JSON API for server status")
    print("Press Ctrl+C to stop the server")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")


if __name__ == '__main__':
    run_server()
