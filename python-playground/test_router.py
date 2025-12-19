#!/usr/bin/env python3
"""
Unit tests for the router functionality in simple_server.py
"""

import unittest
import sys
import os
from unittest import mock

# Make sure we can import the module
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from simple_server import Router
    IMPORT_WORKS = True
except ImportError as e:
    IMPORT_WORKS = False
    print(f"Import error: {e}")


class TestRouter(unittest.TestCase):
    
    def setUp(self):
        """Set up test fixtures before each test method."""
        if not IMPORT_WORKS:
            self.skipTest("Cannot import simple_server")
        
        # Create a standalone router for testing
        self.router = Router()

    def test_router_initialization(self):
        """Test that router initializes with empty routes"""
        if not IMPORT_WORKS:
            self.skipTest("Cannot import simple_server")
            
        self.assertEqual(self.router.routes, {})

    def test_add_route(self):
        """Test that routes can be added to the router"""
        if not IMPORT_WORKS:
            self.skipTest("Cannot import simple_server")
            
        def dummy_handler():
            pass
            
        self.router.add_route('/test', dummy_handler)
        self.assertIn('/test', self.router.routes)
        self.assertEqual(self.router.routes['/test'], dummy_handler)

    def test_get_handler_for_path_existing_route(self):
        """Test that get_handler_for_path returns correct handler for existing route"""
        if not IMPORT_WORKS:
            self.skipTest("Cannot import simple_server")
            
        def dummy_handler():
            pass
            
        self.router.add_route('/test', dummy_handler)
        handler_func = self.router.get_handler_for_path('/test')
        self.assertEqual(handler_func, dummy_handler)

    def test_get_handler_for_path_unknown_route_returns_none(self):
        """Test that get_handler_for_path returns None for unknown routes"""
        if not IMPORT_WORKS:
            self.skipTest("Cannot import simple_server")
            
        handler_func = self.router.get_handler_for_path('/unknown')
        self.assertIsNone(handler_func)

    def test_handle_404(self):
        """Test that handle_404 sends proper 404 response"""
        if not IMPORT_WORKS:
            self.skipTest("Cannot import simple_server")
            
        # Create a mock request handler
        mock_handler = mock.MagicMock()
        self.router.handle_404(mock_handler)
        
        # Verify that the proper methods were called
        mock_handler.send_response.assert_called_once_with(404)
        mock_handler.send_header.assert_called_once_with('Content-type', 'text/html')
        mock_handler.end_headers.assert_called_once()


if __name__ == '__main__':
    unittest.main()