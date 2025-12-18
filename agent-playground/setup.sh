#!/bin/bash

# Multi-Agent Developer System Setup Script
# This script helps set up the project environment

set -e  # Exit on error

echo "🤖 Multi-Agent Developer System Setup"
echo "======================================"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "✅ Python $PYTHON_VERSION detected"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "📦 Installing dependencies..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    echo "✅ Dependencies installed"
else
    echo "❌ requirements.txt not found"
    exit 1
fi

# Check for .env file
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo "⚙️  Creating .env file from template..."
        cp .env.example .env
        echo "✅ .env file created"
        echo ""
        echo "⚠️  IMPORTANT: Please edit the .env file and add your OpenAI API key"
        echo "   OPENAI_API_KEY=your_api_key_here"
    else
        echo "❌ .env.example not found"
        exit 1
    fi
else
    echo "✅ .env file already exists"
fi

# Run tests
echo "🧪 Running system tests..."
if [ -f "test.py" ]; then
    python3 test.py
else
    echo "⚠️  test.py not found, skipping tests"
fi

# Test API connection if .env exists
if [ -f ".env" ]; then
    echo "🔌 Testing API connection..."
    if [ -f "test_api.py" ]; then
        python3 test_api.py
    else
        echo "⚠️  test_api.py not found, skipping API test"
    fi
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env file and add your API configuration"
echo "2. Test the system:"
echo "   python3 run.py check          # Check environment"
echo "   python3 run.py example        # Run example analysis"
echo "   python3 run.py cli interactive # Start interactive mode"
echo ""
echo "Usage examples:"
echo "   python3 src/cli.py analyze --file examples/example_code.py"
echo "   python3 src/cli.py review --code 'def add(a, b): return a + b'"
echo "   python3 src/cli.py test --file your_code.py"
echo "   python3 src/cli.py analyze --file examples/example_code.py --api-url http://localhost:11434/v1  # For local models"
echo ""
echo "For more information, see README.md and QUICKSTART.md"
