# Agent Development Guidelines

## Commands
- Build: `pip install -r requirements.txt`
- Lint: `ruff check .` or `flake8 src/`
- Test: `python test.py` or `python -m pytest test.py`
- Single test: `python -m pytest test.py::test_function_name`

## Code Style
- Imports: Standard library first, then third-party, then local imports
- Formatting: Black style with 88 character line length
- Types: Use type hints consistently
- Naming: snake_case for functions and variables, PascalCase for classes
- Error handling: Use try/except blocks with specific exception types
- Docstrings: Follow Google-style docstrings
- Logging: Use standard logging module with appropriate levels
- Configuration: Load environment variables using python-dotenv

## Testing
- Unit tests in test.py
- Mock external API calls when testing
- Test edge cases and error conditions
- Use pytest fixtures for test setup

## Security
- Never hardcode secrets in source code
- API keys loaded from environment variables
- .env files excluded from version control via .gitignore

## Best Practices
- All agents must inherit from BaseAgent and implement process() method
- Handle API rate limits gracefully with exponential backoff
- Validate all inputs before processing
- Log important events at appropriate levels (DEBUG, INFO, WARNING, ERROR)
- Keep methods small and focused on single responsibilities
- Return structured data that can be easily serialized
- Include comprehensive error handling with meaningful error messages

## Running Tests
To run a specific test function:
```bash
python -m pytest test.py::test_function_name -v
```

To run all tests:
```bash
python -m pytest test.py
```

To run tests with coverage:
```bash
python -m pytest test.py --cov=src
```