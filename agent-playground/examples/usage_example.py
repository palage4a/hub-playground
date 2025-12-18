#!/usr/bin/env python3
"""
Example Usage Script for Multi-Agent Developer System with Custom API URLs

This script demonstrates how to use the system with different AI providers
including local models (Ollama, LM Studio) and cloud providers.
"""

import os
import sys
from pathlib import Path

# Add src directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from colorama import Fore, Style, init
from multi_agent_orchestrator import MultiAgentOrchestrator, TaskType

# Initialize colorama for colored output
init(autoreset=True)


def print_header(title):
    """Print a formatted header."""
    print(f"\n{Fore.CYAN}{'=' * 60}{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}{title}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'=' * 60}{Style.RESET_ALL}")


def example_with_openai():
    """Example using OpenAI (default provider)."""
    print_header("Example 1: Using OpenAI (Default)")

    print(f"{Fore.GREEN}This example uses the default OpenAI API.{Style.RESET_ALL}")
    print(
        f"{Fore.YELLOW}Make sure OPENAI_API_KEY is set in your .env file.{Style.RESET_ALL}"
    )

    # Sample code to analyze
    sample_code = """
def calculate_fibonacci(n):
    \"\"\"Calculate the nth Fibonacci number.\"\"\"
    if n <= 0:
        return 0
    elif n == 1:
        return 1
    else:
        return calculate_fibonacci(n-1) + calculate_fibonacci(n-2)

def is_prime(num):
    \"\"\"Check if a number is prime.\"\"\"
    if num < 2:
        return False
    for i in range(2, int(num**0.5) + 1):
        if num % i == 0:
            return False
    return True
    """

    try:
        # Initialize orchestrator
        orchestrator = MultiAgentOrchestrator(verbose=True)

        # Run code review
        print(f"\n{Fore.CYAN}🔍 Running code review...{Style.RESET_ALL}")
        review_result = orchestrator.execute_task(TaskType.CODE_REVIEW, sample_code)

        if review_result.success:
            print(
                f"{Fore.GREEN}✅ Code review completed successfully!{Style.RESET_ALL}"
            )
        else:
            print(
                f"{Fore.RED}❌ Code review failed: {review_result.error_message}{Style.RESET_ALL}"
            )

    except Exception as e:
        print(f"{Fore.RED}❌ Error: {e}{Style.RESET_ALL}")
        print(
            f"{Fore.YELLOW}Make sure your OpenAI API key is configured correctly.{Style.RESET_ALL}"
        )


def example_with_custom_url(api_url, provider_name):
    """Example using a custom API URL."""
    print_header(f"Example 2: Using {provider_name}")

    print(f"{Fore.GREEN}This example uses a custom API URL: {api_url}{Style.RESET_ALL}")
    print(
        f"{Fore.YELLOW}Make sure the server is running at the specified URL.{Style.RESET_ALL}"
    )

    # Sample code to analyze
    sample_code = """
class Calculator:
    \"\"\"A simple calculator class.\"\"\"

    def __init__(self):
        self.memory = 0

    def add(self, a, b):
        \"\"\"Add two numbers.\"\"\"
        return a + b

    def subtract(self, a, b):
        \"\"\"Subtract b from a.\"\"\"
        return a - b

    def multiply(self, a, b):
        \"\"\"Multiply two numbers.\"\"\"
        return a * b

    def divide(self, a, b):
        \"\"\"Divide a by b.\"\"\"
        if b == 0:
            raise ValueError("Cannot divide by zero")
        return a / b
    """

    try:
        # Set custom API URL in environment
        os.environ["OPENAI_API_BASE_URL"] = api_url
        os.environ["OPENAI_API_KEY"] = "test-key"  # Any string works for local models

        # Initialize orchestrator
        orchestrator = MultiAgentOrchestrator(verbose=True)

        # Generate tests
        print(f"\n{Fore.CYAN}🧪 Generating tests...{Style.RESET_ALL}")
        test_result = orchestrator.execute_task(TaskType.TEST_GENERATION, sample_code)

        if test_result.success:
            print(
                f"{Fore.GREEN}✅ Test generation completed successfully!{Style.RESET_ALL}"
            )

            # Show test statistics
            if "test_count" in test_result.output:
                print(f"\n{Fore.CYAN}📊 Test Statistics:{Style.RESET_ALL}")
                print(f"  Number of tests: {test_result.output['test_count']}")
                print(f"  Language: {test_result.output.get('language', 'Unknown')}")
                print(
                    f"  Framework: {test_result.output.get('test_framework', 'Unknown')}"
                )
        else:
            print(
                f"{Fore.RED}❌ Test generation failed: {test_result.error_message}{Style.RESET_ALL}"
            )

    except Exception as e:
        print(f"{Fore.RED}❌ Error: {e}{Style.RESET_ALL}")
        print(
            f"{Fore.YELLOW}Make sure {provider_name} is running at {api_url}{Style.RESET_ALL}"
        )
    finally:
        # Clean up environment
        if "OPENAI_API_BASE_URL" in os.environ:
            del os.environ["OPENAI_API_BASE_URL"]


def example_full_analysis():
    """Example running full analysis on a file."""
    print_header("Example 3: Full Analysis of Example Code")

    example_file = Path(__file__).parent / "example_code.py"

    if not example_file.exists():
        print(f"{Fore.RED}❌ Example file not found: {example_file}{Style.RESET_ALL}")
        return

    print(f"{Fore.GREEN}Running full analysis on: {example_file}{Style.RESET_ALL}")

    try:
        # Read the example code
        with open(example_file, "r") as f:
            code_content = f.read()

        # Initialize orchestrator
        orchestrator = MultiAgentOrchestrator(verbose=True)

        # Run full analysis
        print(f"\n{Fore.CYAN}🔍 Starting full analysis...{Style.RESET_ALL}")
        results = orchestrator.execute_full_analysis(code_content)

        # Print summary
        print(f"\n{Fore.GREEN}🎉 Full analysis complete!{Style.RESET_ALL}")

        successful_tasks = sum(1 for r in results.values() if r.success)
        total_tasks = len(results)
        total_time = sum(r.execution_time for r in results.values())

        print(f"\n{Fore.CYAN}📊 Summary:{Style.RESET_ALL}")
        print(f"  Tasks completed: {successful_tasks}/{total_tasks}")
        print(f"  Total execution time: {total_time:.2f}s")
        print(f"  Average time per task: {total_time / total_tasks:.2f}s")

    except Exception as e:
        print(f"{Fore.RED}❌ Error: {e}{Style.RESET_ALL}")


def example_programmatic_usage():
    """Example of programmatic usage with custom configuration."""
    print_header("Example 4: Programmatic Usage")

    print(
        f"{Fore.GREEN}This example shows how to use the system programmatically.{Style.RESET_ALL}"
    )

    # Sample code
    sample_code = """
def process_data(data):
    \"\"\"Process a list of data points.\"\"\"
    if not data:
        return []

    results = []
    for item in data:
        # Some processing logic
        processed = item * 2
        results.append(processed)

    return results
    """

    try:
        # You can configure the system programmatically
        config = {
            "api_key": os.getenv("OPENAI_API_KEY", "test-key"),
            "api_base_url": None,  # Set to custom URL if needed
            "model": "gpt-3.5-turbo",  # Use a faster/cheaper model
            "temperature": 0.3,  # More deterministic
            "max_tokens": 1000,
            "verbose": False,
        }

        # Note: In a real scenario, you would pass these to the orchestrator
        # For this example, we'll use the default initialization

        orchestrator = MultiAgentOrchestrator(verbose=False)

        # Generate documentation
        print(f"\n{Fore.CYAN}📝 Generating documentation...{Style.RESET_ALL}")
        doc_result = orchestrator.execute_task(TaskType.DOCUMENTATION, sample_code)

        if doc_result.success:
            print(
                f"{Fore.GREEN}✅ Documentation generated successfully!{Style.RESET_ALL}"
            )

            # Show documentation analysis
            if "analysis" in doc_result.output:
                analysis = doc_result.output["analysis"]
                print(f"\n{Fore.CYAN}📊 Documentation Analysis:{Style.RESET_ALL}")
                print(f"  Completeness: {analysis.get('completeness_score', 0):.1%}")
                print(f"  Readability: {analysis.get('readability_score', 'Unknown')}")
                print(
                    f"  Estimated reading time: {doc_result.output.get('estimated_reading_time', 'Unknown')}"
                )
        else:
            print(
                f"{Fore.RED}❌ Documentation generation failed: {doc_result.error_message}{Style.RESET_ALL}"
            )

    except Exception as e:
        print(f"{Fore.RED}❌ Error: {e}{Style.RESET_ALL}")


def main():
    """Main function to run all examples."""
    print(
        f"{Fore.CYAN}🤖 Multi-Agent Developer System - Usage Examples{Style.RESET_ALL}"
    )
    print(f"{Fore.CYAN}{'=' * 60}{Style.RESET_ALL}")

    print(
        f"{Fore.YELLOW}This script demonstrates various ways to use the system.{Style.RESET_ALL}"
    )
    print(f"{Fore.YELLOW}Choose an example to run:{Style.RESET_ALL}")
    print(f"  1. OpenAI (default provider)")
    print(f"  2. Ollama (local model)")
    print(f"  3. LM Studio (local model)")
    print(f"  4. Full analysis of example code")
    print(f"  5. Programmatic usage")
    print(f"  6. Run all examples")
    print(f"  0. Exit")

    try:
        choice = input(
            f"\n{Fore.GREEN}Enter your choice (0-6): {Style.RESET_ALL}"
        ).strip()

        if choice == "1":
            example_with_openai()
        elif choice == "2":
            example_with_custom_url("http://localhost:11434/v1", "Ollama")
        elif choice == "3":
            example_with_custom_url("http://localhost:1234/v1", "LM Studio")
        elif choice == "4":
            example_full_analysis()
        elif choice == "5":
            example_programmatic_usage()
        elif choice == "6":
            example_with_openai()
            example_with_custom_url("http://localhost:11434/v1", "Ollama")
            example_with_custom_url("http://localhost:1234/v1", "LM Studio")
            example_full_analysis()
            example_programmatic_usage()
        elif choice == "0":
            print(f"\n{Fore.YELLOW}👋 Goodbye!{Style.RESET_ALL}")
            return
        else:
            print(
                f"{Fore.RED}❌ Invalid choice. Please enter a number between 0 and 6.{Style.RESET_ALL}"
            )
            return

    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}👋 Goodbye!{Style.RESET_ALL}")
        return

    # Show next steps
    print(f"\n{Fore.CYAN}💡 Next Steps:{Style.RESET_ALL}")
    print(f"  1. Check out the configuration examples: examples/config_examples.md")
    print(f"  2. Try the CLI: python src/cli.py interactive")
    print(f"  3. Test API connection: python test_api.py")
    print(f"  4. Read the quick start guide: QUICKSTART.md")
    print(f"  5. Explore the full documentation: README.md")


if __name__ == "__main__":
    main()
