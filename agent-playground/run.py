#!/usr/bin/env python3
"""
Main entry point for the Multi-Agent Developer Productivity System.

This script provides an easy way to run the system with various options.
"""

import argparse
import os
import sys
from pathlib import Path

# Add the src directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

from colorama import Fore, Style, init

# Initialize colorama
init(autoreset=True)


def check_environment():
    """Check if the environment is properly set up."""
    print(f"{Fore.CYAN}🔍 Checking environment...{Style.RESET_ALL}")

    # Check Python version
    python_version = sys.version_info
    if python_version.major < 3 or (
        python_version.major == 3 and python_version.minor < 8
    ):
        print(f"{Fore.RED}❌ Python 3.8 or higher is required{Style.RESET_ALL}")
        print(
            f"Current version: {python_version.major}.{python_version.minor}.{python_version.micro}"
        )
        return False

    print(
        f"✅ Python version: {python_version.major}.{python_version.minor}.{python_version.micro}"
    )

    # Check for .env file
    env_file = Path(".env")
    if not env_file.exists():
        print(f"{Fore.YELLOW}⚠️  .env file not found{Style.RESET_ALL}")
        print(f"Please copy .env.example to .env and add your OpenAI API key")
        return False

    print("✅ .env file found")

    # Check for requirements
    try:
        import dotenv
        import langchain
        import langchain_openai

        print("✅ All required packages are installed")
    except ImportError as e:
        print(f"{Fore.RED}❌ Missing package: {e}{Style.RESET_ALL}")
        print(f"Please run: pip install -r requirements.txt")
        return False

    # Check OpenAI API key
    from dotenv import load_dotenv

    load_dotenv()

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key or api_key == "your_openai_api_key_here":
        print(f"{Fore.RED}❌ OpenAI API key not configured{Style.RESET_ALL}")
        print(f"Please add your API key to the .env file")
        return False

    print("✅ OpenAI API key configured")

    return True


def run_cli():
    """Run the CLI interface."""
    from src.cli import SimpleCLI

    cli = SimpleCLI()
    return cli.run()


def run_example():
    """Run an example analysis."""
    from src.multi_agent_orchestrator import SimpleMultiAgentOrchestrator

    print(f"{Fore.CYAN}🚀 Running example analysis...{Style.RESET_ALL}")

    try:
        orchestrator = SimpleMultiAgentOrchestrator(verbose=True)

        # Read example code
        example_file = Path("examples/example_code.py")
        if not example_file.exists():
            print(
                f"{Fore.RED}❌ Example file not found: {example_file}{Style.RESET_ALL}"
            )
            return 1

        with open(example_file, "r") as f:
            code = f.read()

        print(
            f"{Fore.YELLOW}📝 Analyzing example code ({len(code)} characters)...{Style.RESET_ALL}"
        )

        # Run full analysis
        results = orchestrator.execute_full_analysis(code)

        print(f"\n{Fore.GREEN}✅ Example analysis complete!{Style.RESET_ALL}")
        print(f"{Fore.CYAN}Try these commands next:{Style.RESET_ALL}")
        print(f"  python run.py cli interactive          # Start interactive mode")
        print(f"  python run.py cli analyze --file examples/example_code.py")
        print(f"  python run.py cli review --code 'def add(a, b): return a + b'")

        return 0

    except Exception as e:
        print(f"{Fore.RED}❌ Error running example: {e}{Style.RESET_ALL}")
        return 1


def show_help():
    """Show help information."""
    help_text = f"""
{Fore.CYAN}🤖 Multi-Agent Developer Productivity System{Style.RESET_ALL}
{Fore.CYAN}==========================================={Style.RESET_ALL}

{Fore.YELLOW}Usage:{Style.RESET_ALL}
  python run.py [command] [options]

{Fore.YELLOW}Commands:{Style.RESET_ALL}
  {Fore.GREEN}check{Style.RESET_ALL}       - Check environment setup
  {Fore.GREEN}example{Style.RESET_ALL}     - Run example analysis
  {Fore.GREEN}cli{Style.RESET_ALL}         - Run CLI interface (pass arguments to CLI)
  {Fore.GREEN}help{Style.RESET_ALL}        - Show this help message

{Fore.YELLOW}Examples:{Style.RESET_ALL}
  {Fore.CYAN}# Check environment setup{Style.RESET_ALL}
  python run.py check

  {Fore.CYAN}# Run example analysis{Style.RESET_ALL}
  python run.py example

  {Fore.CYAN}# Run CLI with specific command{Style.RESET_ALL}
  python run.py cli analyze --file examples/example_code.py
  python run.py cli review --code "def add(a, b): return a + b"
  python run.py cli interactive

  {Fore.CYAN}# Get CLI help{Style.RESET_ALL}
  python run.py cli --help

{Fore.YELLOW}Quick Start:{Style.RESET_ALL}
  1. Copy .env.example to .env and add your OpenAI API key
  2. Install dependencies: pip install -r requirements.txt
  3. Run: python run.py check
  4. Run: python run.py example
  4. Run: python run.py cli interactive
  5. Or test directly: python src/cli.py analyze --file examples/example_code.py

{Fore.YELLOW}Need Help?{Style.RESET_ALL}
  - See README.md for detailed documentation
  - Check the examples/ directory for sample code
  - Use interactive mode for guided usage
    """

    print(help_text)
    return 0


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Multi-Agent Developer Productivity System", add_help=False
    )

    parser.add_argument(
        "command",
        nargs="?",
        default="help",
        choices=["check", "example", "cli", "help"],
        help="Command to execute",
    )

    # Parse only the first argument to determine command
    if len(sys.argv) > 1 and sys.argv[1] in ["check", "example", "cli", "help"]:
        args, remaining_args = parser.parse_known_args()
    else:
        args = parser.parse_args(["--help"])
        remaining_args = []

    # Execute command
    if args.command == "check":
        success = check_environment()
        return 0 if success else 1

    elif args.command == "example":
        # First check environment
        if not check_environment():
            return 1
        return run_example()

    elif args.command == "cli":
        # First check environment
        if not check_environment():
            return 1

        # Pass remaining arguments to CLI
        sys.argv = [sys.argv[0]] + remaining_args
        return run_cli()

    elif args.command == "help":
        return show_help()

    else:
        parser.print_help()
        return 0


if __name__ == "__main__":
    try:
        exit_code = main()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}👋 Goodbye!{Style.RESET_ALL}")
        sys.exit(0)
    except Exception as e:
        print(f"{Fore.RED}❌ Unexpected error: {e}{Style.RESET_ALL}")
        sys.exit(1)
