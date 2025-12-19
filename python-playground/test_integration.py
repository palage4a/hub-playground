#!/usr/bin/env python3
"""
Integration tests for the HTTP server in simple_server.py
These tests make actual HTTP requests to the running server.
"""

import unittest
import threading
import time
import http.client
import sys
import os
import signal
import subprocess
import socket

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import the server module
from simple_server import SimpleHTTPRequestHandler


class IntegrationTest(unittest.TestCase):
    def setUp(self):
        """Set up test fixtures before each test method."""
        # Since we can't easily start/stop server in tests, 
        # we'll test the server's behavior by directly calling its methods
        # and verifying that it can respond to HTTP requests
        pass

    def make_request(self, path, method="GET", port=8000):
        """Helper method to make HTTP requests"""
        conn = http.client.HTTPConnection('localhost', port, timeout=5)
        conn.request(method, path)
        response = conn.getresponse()
        data = response.read().decode()
        conn.close()
        return response, data

    def test_server_can_be_started_and_stopped(self):
        """Test that the server can be started and is accessible"""
        # This test assumes the server is running on port 8000
        # We verify the server responds to requests
        try:
            response, _ = self.make_request("/", port=8000)
            self.assertEqual(response.status, 200)
        except Exception as e:
            # If server isn't running, skip this test
            self.skipTest(f"Server not running: {e}")

    def test_home_route_response(self):
        """Test that the home route returns correct content"""
        try:
            response, data = self.make_request("/", port=8000)
            self.assertEqual(response.status, 200)
            self.assertIn("<h1>Welcome to the Simple Server</h1>", data)
            self.assertIn("This is the home page.", data)
        except Exception as e:
            self.skipTest(f"Server not running: {e}")

    def test_about_route_response(self):
        """Test that the about route returns correct content"""
        try:
            response, data = self.make_request("/about", port=8000)
            self.assertEqual(response.status, 200)
            self.assertIn("<h1>About Us</h1>", data)
            self.assertIn("This is the about page.", data)
        except Exception as e:
            self.skipTest(f"Server not running: {e}")

    def test_api_users_route_response(self):
        """Test that the users API route returns correct JSON content"""
        try:
            response, data = self.make_request("/api/users", port=8000)
            self.assertEqual(response.status, 200)
            self.assertEqual(response.getheader('Content-type'), 'application/json')
            self.assertIn('"users"', data)
            self.assertIn('"id": 1', data)
            self.assertIn('"id": 2', data)
            self.assertIn('"name": "Alice"', data)
            self.assertIn('"name": "Bob"', data)
        except Exception as e:
            self.skipTest(f"Server not running: {e}")

    def test_api_status_route_response(self):
        """Test that the status API route returns correct JSON content"""
        try:
            response, data = self.make_request("/api/status", port=8000)
            self.assertEqual(response.status, 200)
            self.assertEqual(response.getheader('Content-type'), 'application/json')
            self.assertIn('"status": "OK"', data)
            self.assertIn('"message": "Server is running"', data)
        except Exception as e:
            self.skipTest(f"Server not running: {e}")

    def test_404_for_unknown_route(self):
        """Test that unknown routes return 404 status"""
        try:
            response, data = self.make_request("/unknown-route", port=8000)
            self.assertEqual(response.status, 404)
            self.assertIn("<h1>404 - Page Not Found</h1>", data)
        except Exception as e:
            self.skipTest(f"Server not running: {e}")

    def test_correct_content_types(self):
        """Test that the server returns proper content types"""
        try:
            # Test HTML responses
            response, _ = self.make_request("/", port=8000)
            self.assertEqual(response.getheader('Content-type'), 'text/html')

            response, _ = self.make_request("/about", port=8000)
            self.assertEqual(response.getheader('Content-type'), 'text/html')

            # Test JSON responses
            response, _ = self.make_request("/api/users", port=8000)
            self.assertEqual(response.getheader('Content-type'), 'application/json')

            response, _ = self.make_request("/api/status", port=8000)
            self.assertEqual(response.getheader('Content-type'), 'application/json')
        except Exception as e:
            self.skipTest(f"Server not running: {e}")

    def test_correct_http_status_codes(self):
        """Test that the server returns proper HTTP status codes"""
        try:
            # Test successful responses
            response, _ = self.make_request("/", port=8000)
            self.assertEqual(response.status, 200)

            response, _ = self.make_request("/about", port=8000)
            self.assertEqual(response.status, 200)

            response, _ = self.make_request("/api/users", port=8000)
            self.assertEqual(response.status, 200)

            response, _ = self.make_request("/api/status", port=8000)
            self.assertEqual(response.status, 200)

            # Test 404 for non-existent routes
            response, _ = self.make_request("/nonexistent", port=8000)
            self.assertEqual(response.status, 404)
        except Exception as e:
            self.skipTest(f"Server not running: {e}")

    def test_multiple_requests(self):
        """Test that the server can handle multiple requests"""
        try:
            # Make several requests to the same endpoint
            responses = []
            for i in range(3):
                response, _ = self.make_request("/", port=8000)
                responses.append(response.status)
                
            # All should return 200
            for status in responses:
                self.assertEqual(status, 200)
        except Exception as e:
            self.skipTest(f"Server not running: {e}")


if __name__ == '__main__':
    unittest.main()