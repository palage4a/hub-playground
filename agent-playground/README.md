# Multi-Agent Developer Productivity System

A modular, extensible multi-agent system designed to help software developers improve their productivity through AI-powered assistance. Supports multiple AI providers including OpenAI, local models (Ollama, LM Studio), Azure OpenAI, and other OpenAI-compatible APIs.

## 🚀 Overview

This system consists of four specialized AI agents that work together to help with common software development tasks:

1. **Code Reviewer** - Analyzes code for bugs, style issues, performance problems, and security vulnerabilities
2. **Test Writer** - Generates comprehensive unit tests, integration tests, and test documentation
3. **Documentation Agent** - Creates clear, well-structured documentation including API docs and usage examples
4. **Architecture Advisor** - Provides architectural guidance, design patterns, and system design recommendations

## 📋 Features

- **Multi-Provider Support**: Works with OpenAI, local models (Ollama, LM Studio), Azure OpenAI, and any OpenAI-compatible API
- **Custom API URLs**: Specify custom endpoints via environment variables or command line
- **Modular Design**: Each agent is independent and can be used separately
- **Extensible Architecture**: Easy to add new agents or customize existing ones
- **Context-Aware**: Agents can use context information for better results
- **History Tracking**: All tasks are logged with execution details
- **Multiple Interfaces**: CLI, interactive mode, and programmatic API
- **Customizable Prompts**: Agent behavior can be customized via environment variables

## 🛠️ Installation

### Prerequisites

- Python 3.8 or higher
- API key for your chosen provider (or local model server)

### Quick Setup

```bash
# Clone and navigate to project
cd agent-playground

# Run setup script
./setup.sh
```

Or manually:

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env and add your API configuration
```

## ⚙️ Configuration

Edit the `.env` file to customize the system:

```bash
# Required: API Configuration
OPENAI_API_KEY=your_api_key_here

# Optional: Custom API URL
# Use for local models or alternative providers
# Examples:
# OPENAI_API_BASE_URL=http://localhost:11434/v1  # Ollama
# OPENAI_API_BASE_URL=http://localhost:1234/v1    # LM Studio
# OPENAI_API_BASE_URL=https://api.openai.com/v1   # OpenAI (default)
OPENAI_API_BASE_URL=

# Model Configuration
OPENAI_MODEL=gpt-4-turbo-preview  # or gpt-3.5-turbo, llama3.2, etc.
OPENAI_TEMPERATURE=0.7
MAX_TOKENS=2000

# Agent Configuration
VERBOSE=True

# Custom Prompts (optional)
CODE_REVIEWER_PROMPT=Your custom prompt for code review...
TEST_WRITER_PROMPT=Your custom prompt for test writing...
DOCUMENTATION_AGENT_PROMPT=Your custom prompt for documentation...
ARCHITECTURE_ADVISOR_PROMPT=Your custom prompt for architecture advice...
```

### Common Provider Configurations

#### OpenAI (Default)
```bash
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4-turbo-preview
```

#### Ollama (Local)
```bash
OPENAI_API_KEY=ollama  # Any string works
OPENAI_API_BASE_URL=http://localhost:11434/v1
OPENAI_MODEL=llama3.2
```

#### LM Studio (Local)
```bash
OPENAI_API_KEY=lm-studio  # Any string works
OPENAI_API_BASE_URL=http://localhost:1234/v1
OPENAI_MODEL=local-model
```

#### Azure OpenAI
```bash
OPENAI_API_KEY=your-azure-key
OPENAI_API_BASE_URL=https://your-resource.openai.azure.com/openai/deployments/your-deployment
OPENAI_MODEL=gpt-4
```

## 🚀 Quick Start

### Using the CLI

Run a full analysis on example code:
```bash
python src/cli.py analyze --file examples/example_code.py
```

Run just a code review:
```bash
python src/cli.py review --file examples/example_code.py
```

Generate tests for code:
```bash
python src/cli.py test --file examples/example_code.py --language python
```

### Using Custom API URLs

Specify custom API URL directly in the command:
```bash
# Use Ollama with Llama 3.2
python src/cli.py analyze --file examples/example_code.py --api-url http://localhost:11434/v1

# Use LM Studio
python src/cli.py review --code "def add(a, b): return a + b" --api-url http://localhost:1234/v1

# Use Azure OpenAI
python src/cli.py analyze --file mycode.py --api-url https://your-resource.openai.azure.com/openai/deployments/gpt-4
```

### Interactive Mode

Start the interactive shell:
```bash
python src/cli.py interactive
```

In interactive mode, you can use commands like:
- `review "def add(a, b): return a + b"`
- `test --file mycode.py`
- `analyze "class Calculator: ..."`
- `status` - Show system status
- `history` - Show task history
- `help` - Show available commands
- `exit` - Quit interactive mode

### Programmatic Usage

```python
from src.multi_agent_orchestrator import MultiAgentOrchestrator

# Initialize the orchestrator
orchestrator = MultiAgentOrchestrator(verbose=True)

# Run a full analysis
code = """
def calculate_sum(numbers):
    return sum(numbers)
"""

results = orchestrator.execute_full_analysis(code)

# Use a specific agent
review_result = orchestrator.execute_task(
    "code_review",
    code,
    {"language": "python"}
)

# Get system status
status = orchestrator.get_system_status()
print(f"Total tasks executed: {status['total_tasks_executed']}")
```

## 📁 Project Structure

```
agent-playground/
├── src/
│   ├── agents/
│   │   ├── __init__.py          # Agents package
│   │   ├── base_agent.py        # Base agent class (supports custom URLs)
│   │   ├── code_reviewer.py     # Code review agent
│   │   ├── test_writer.py       # Test generation agent
│   │   ├── documentation_agent.py # Documentation agent
│   │   └── architecture_advisor.py # Architecture advisor agent
│   ├── multi_agent_orchestrator.py # Main orchestrator
│   └── cli.py                  # Command-line interface (supports --api-url)
├── examples/
│   ├── example_code.py         # Example code for testing
│   └── config_examples.md      # Configuration examples for different providers
├── .env.example               # Environment template with API URL support
├── .gitignore                 # Git ignore rules
├── README.md                  # This file
├── QUICKSTART.md              # Quick start guide
├── requirements.txt           # Python dependencies
├── run.py                     # Main entry point script
├── setup.sh                   # Setup script with API testing
├── test.py                    # System test script
└── test_api.py                # API connection test script
```

## 🤖 Available Agents

### Code Reviewer
- Analyzes code for bugs and logical errors
- Checks code style and best practices
- Identifies performance issues
- Detects security vulnerabilities
- Provides actionable feedback

### Test Writer
- Generates unit tests for functions/methods
- Creates integration tests
- Includes edge cases and error handling
- Provides test documentation
- Supports multiple testing frameworks

### Documentation Agent
- Creates API documentation
- Generates usage examples
- Writes installation guides
- Creates tutorials and getting started guides
- Supports multiple formats (Markdown, reStructuredText)

### Architecture Advisor
- Recommends architectural patterns
- Suggests technology stacks
- Provides scalability advice
- Offers security recommendations
- Helps with deployment strategies

## 🔧 Advanced Usage

### Custom API URLs

The system supports various AI providers through custom API URLs:

#### Via Environment Variable (.env file):
```bash
# For Ollama
OPENAI_API_BASE_URL=http://localhost:11434/v1
OPENAI_MODEL=llama3.2

# For Azure OpenAI
OPENAI_API_BASE_URL=https://your-resource.openai.azure.com/openai/deployments/your-deployment
OPENAI_MODEL=gpt-4

# For Together AI
OPENAI_API_BASE_URL=https://api.together.xyz/v1
OPENAI_MODEL=togethercomputer/llama-2-70b-chat
```

#### Via Command Line:
```bash
# Use Ollama
python src/cli.py analyze --file mycode.py --api-url http://localhost:11434/v1

# Use Azure OpenAI
python src/cli.py review --code "def add(a, b): return a + b" --api-url https://your-resource.openai.azure.com/openai/deployments/gpt-4
```

### API Connection Testing

Test your API configuration:
```bash
python test_api.py
```

This will:
1. Check your environment configuration
2. Test connection to the configured API endpoint
3. Optionally test common local providers (Ollama, LM Studio)
4. Provide recommendations based on results

### Custom Context

You can provide context to agents for better results:

```bash
python src/cli.py review --file mycode.py --context '{"language": "python", "framework": "django"}'
```

### Saving Results

Save analysis results to a JSON file:

```bash
python src/cli.py analyze --file mycode.py --output results.json
```

### History Management

View task history:
```bash
python src/cli.py history --limit 10
```

Save history to file:
```bash
python src/cli.py history --save history_backup.json
```

Load history from file:
```bash
python src/cli.py history --load history_backup.json
```

### Creating Custom Agents

1. Create a new agent class inheriting from `BaseAgent`:
```python
from agents.base_agent import BaseAgent

class MyCustomAgent(BaseAgent):
    def __init__(self, model=None):
        super().__init__(
            name="My Custom Agent",
            role="Description of what this agent does",
            model=model
        )
    
    def get_system_prompt(self):
        return "Your custom system prompt here"
    
    def process(self, input_data, context=None):
        # Your processing logic here
        pass
```

2. Register the agent in the orchestrator:
```python
orchestrator.agents["my_custom_agent"] = MyCustomAgent()
```

## 📊 Output Examples

### Code Review Output
```
=== Code Reviewer (Expert code reviewer) ===

The code looks good overall, but here are some suggestions:

1. Performance: The recursive Fibonacci function has exponential time complexity.
   Consider using memoization or an iterative approach.

2. Error Handling: Add input validation for negative numbers.

3. Documentation: Add type hints for better IDE support.

📊 Summary: Code review completed. Found 3 categories of issues.
⚠️  Severity Level: MEDIUM
```

### Test Generation Output
```
=== Test Writer (Expert test writer) ===

import pytest

def test_calculate_fibonacci():
    # Test base cases
    assert calculate_fibonacci(0) == 0
    assert calculate_fibonacci(1) == 1
    
    # Test recursive case
    assert calculate_fibonacci(5) == 5
    
    # Test error handling
    with pytest.raises(ValueError):
        calculate_fibonacci(-1)

📊 Test Statistics:
  Language: Python
  Framework: pytest
  Number of tests: 4
  Estimated coverage: HIGH

✅ Coverage Analysis:
  Edge cases covered: ✓
  Error handling tested: ✓
  Performance tests: ✗
```

## 🔍 Troubleshooting

### Common Issues

1. **API Connection Failed**
   - For local models: Ensure server is running (`ollama serve` or LM Studio)
   - Check API URL is correct (e.g., `http://localhost:11434/v1` for Ollama)
   - Verify model name matches available models

2. **API Key Error**
   - Make sure your API key is set in the `.env` file
   - For local models, any string works as API key

3. **Module Not Found**
   - Ensure you're in the correct directory
   - Activate virtual environment: `source venv/bin/activate`
   - Install dependencies: `pip install -r requirements.txt`

4. **Rate Limiting**
   - Use a local model to avoid rate limits
   - Switch to a cheaper model (gpt-3.5-turbo)
   - Add delays between requests

### Debug Mode

Run with verbose output disabled for cleaner output:
```bash
python src/cli.py --quiet analyze --file mycode.py
```

### Environment Check

Check that all required environment variables are set:
```bash
python run.py check
```

## 📈 Performance Tips

1. **Local Models**: Use Ollama or LM Studio for privacy and reduced latency
2. **Model Selection**: Use smaller models for faster responses (llama3.2, gpt-3.5-turbo)
3. **Batch Processing**: For large codebases, process files in batches
4. **Context Optimization**: Provide relevant context to reduce token usage
5. **Caching**: Implement caching for repeated analyses of the same code

## 🔮 Future Enhancements

Planned features:
- [ ] Support for additional AI providers (Anthropic, Google, etc.)
- [ ] Web interface with visualizations
- [ ] Integration with IDEs (VS Code, PyCharm)
- [ ] Code generation capabilities
- [ ] Real-time collaboration features
- [ ] Plugin system for custom agents

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [LangChain](https://github.com/langchain-ai/langchain)
- Supports multiple OpenAI-compatible APIs
- Inspired by modern AI-assisted development tools

## 📚 Resources

- [LangChain Documentation](https://python.langchain.com/docs/get_started/introduction)
- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [Ollama Documentation](https://ollama.com/)
- [LM Studio Documentation](https://lmstudio.ai/)
- [Multi-Agent Systems Research](https://arxiv.org/abs/2308.08155)

---

**Happy coding with your AI assistant team!** 🚀

For quick start instructions, see [QUICKSTART.md](QUICKSTART.md)
For configuration examples, see [examples/config_examples.md](examples/config_examples.md)