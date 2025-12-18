# 🚀 Quick Start Guide - Multi-Agent Developer System

This guide will help you get started with the Multi-Agent Developer System in under 5 minutes.

## 📋 Prerequisites

- Python 3.8 or higher
- OpenAI API key (or compatible API endpoint)

## ⚡ Quick Setup (One Command)

Run the setup script:

```bash
./setup.sh
```

This will:
1. Create a virtual environment
2. Install all dependencies
3. Create `.env` file from template
4. Run basic tests

## 🔑 Configuration

After setup, edit the `.env` file:

```bash
# Copy the template
cp .env.example .env

# Edit with your favorite editor
nano .env  # or vim, code, etc.
```

Add your API configuration:
```bash
# For OpenAI
OPENAI_API_KEY=sk-your-api-key-here

# For local models (optional)
# OPENAI_API_BASE_URL=http://localhost:11434/v1  # Ollama
# OPENAI_API_BASE_URL=REDACTED__N13__/v1  # LM Studio
```

## 🧪 Verify Installation

Check that everything works:

```bash
# Run system tests
python test.py

# Check environment
python run.py check

# Run example analysis
python run.py example
```

## 🎯 First Use - Try These Commands

### 1. Analyze Example Code
```bash
python src/cli.py analyze --file examples/example_code.py
```

### 2. Review Simple Code
```bash
python src/cli.py review --code "def add(a, b): return a + b"
```

### 3. Generate Tests
```bash
python src/cli.py test --file examples/example_code.py
```

### 4. Use with Local Models
```bash
# With Ollama
python src/cli.py analyze --file examples/example_code.py --api-url http://localhost:11434/v1

# With LM Studio
python src/cli.py review --code "def add(a, b): return a + b" --api-url REDACTED__N13__/v1
```

### 5. Interactive Mode (Recommended)
```bash
python src/cli.py interactive
```

In interactive mode, you can use commands like:
- `review "def add(a, b): return a + b"`
- `test --file your_code.py`
- `analyze "class Calculator: ..."`
- `status` - Show system status
- `help` - Show available commands
- `exit` - Quit interactive mode

## 📁 Project Structure

```
agent-playground/
├── src/                    # Source code
│   ├── agents/            # AI agents
│   ├── cli.py            # Command-line interface
│   └── multi_agent_orchestrator.py  # Main orchestrator
├── examples/              # Example code
├── .env.example          # Environment template
├── requirements.txt      # Python dependencies
├── README.md            # Full documentation
├── QUICKSTART.md        # This guide
├── run.py               # Main entry point
├── setup.sh             # Setup script
└── test.py              # Test script
```

## 🤖 Available Agents

The system includes 4 specialized AI agents:

1. **Code Reviewer** - Finds bugs, style issues, security vulnerabilities
2. **Test Writer** - Generates unit tests and integration tests
3. **Documentation Agent** - Creates API docs and usage examples
4. **Architecture Advisor** - Provides architectural guidance

## 💻 Programmatic Usage

You can also use the system programmatically:

```python
from src.multi_agent_orchestrator import MultiAgentOrchestrator

# Initialize the system
orchestrator = MultiAgentOrchestrator(verbose=True)

# Run full analysis on your code
code = """
def calculate_sum(numbers):
    return sum(numbers)
"""

results = orchestrator.execute_full_analysis(code)

# Use specific agents
review_result = orchestrator.execute_task("code_review", code)
test_result = orchestrator.execute_task("test_generation", code)
```

## 🚨 Troubleshooting

### Common Issues:

1. **"API Key not found"**
   - Make sure `.env` file exists and contains your API key
   - Run: `python run.py check` to verify configuration

2. **"Module not found"**
   - Activate virtual environment: `source venv/bin/activate`
   - Install dependencies: `pip install -r requirements.txt`

3. **Rate limiting errors**
   - Use a different model in `.env`: `OPENAI_MODEL=gpt-3.5-turbo`
   - Add delays between requests

4. **Local model connection issues**
   - Ensure your local model server (Ollama, LM Studio) is running
   - Check the API URL is correct (e.g., `http://localhost:11434/v1` for Ollama)
   - Verify the model name matches what's available locally

### Get Help:

- Check the full documentation in `README.md`
- Run `python src/cli.py --help` for CLI options
- Use `help` command in interactive mode

## 📈 Next Steps

After getting familiar with the basics:

1. **Customize agent prompts** in `.env` file
2. **Add your own code** to the `examples/` directory
3. **Extend the system** by creating new agents
4. **Integrate with your IDE** using the programmatic API
5. **Experiment with local models** using custom API URLs

## 🆘 Need Help?

If you encounter issues:

1. Check that all prerequisites are met
2. Verify your API key is valid (or local model is running)
3. Run the test script: `python test.py`
4. Consult the full `README.md` for detailed instructions
5. For local models: check server logs and connection

---

**Happy coding with your AI assistant team!** 🚀

For detailed documentation, see [README.md](README.md)