#!/usr/bin/env python3
"""
Very simple CLI for Multi-Agent Developer System.
"""

import argparse
import os
import sys
from pathlib import Path
from typing import Optional

# Add the src directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

try:
    from colorama import Fore, Style, init

    from .multi_agent_orchestrator import SimpleMultiAgentOrchestrator, TaskType

    init(autoreset=True)
except ImportError as e:
    print(f"Error importing modules: {e}")
    print("Please install dependencies: pip install -r requirements.txt")
    sys.exit(1)


class SimpleCLI:
    """Simple command-line interface for the multi-agent system."""

    def __init__(self):
        self.orchestrator = None

    def run(self):
        """Run the CLI."""
        parser = argparse.ArgumentParser(
            description="Multi-Agent Developer Productivity System",
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog="""
Examples:
  %(prog)s analyze --file examples/example_code.py
%(prog)s review --code "def add(a, b): return a + b"
%(prog)s test --file mycode.py
%(prog)s interactive
%(prog)s analyze --file mycode.py --api-url http://localhost:11434/v1
            """,
        )

        parser.add_argument(
            "command",
            choices=[
                "analyze",
                "review",
                "test",
                "doc",
                "arch",
                "status",
                "interactive",
            ],
            help="Command to execute",
        )

        parser.add_argument("--file", "-f", type=str, help="File containing code")

        parser.add_argument("--code", "-c", type=str, help="Code string")

        parser.add_argument(
            "--quiet", "-q", action="store_true", help="Reduce output verbosity"
        )

        parser.add_argument(
            "--api-url",
            type=str,
            help="Custom API URL (e.g., http://localhost:11434/v1 for local Ollama)",
        )

        args = parser.parse_args()

        # Initialize orchestrator
        try:
            # Set custom API URL if provided
            if args.api_url:
                os.environ["OPENAI_API_BASE_URL"] = args.api_url
                print(
                    f"{Fore.CYAN}🔧 Using custom API URL: {args.api_url}{Style.RESET_ALL}"
                )

            self.orchestrator = SimpleMultiAgentOrchestrator(verbose=not args.quiet)
        except ValueError as e:
            print(f"{Fore.RED}❌ Failed to initialize agents: {e}{Style.RESET_ALL}")
            print(
                f"{Fore.YELLOW}Please check your .env file and OPENAI_API_KEY{Style.RESET_ALL}"
            )
            return 1

        # Get input
        code = self._read_input(args)
        if not code and args.command not in ["interactive", "status"]:
            return 1

        # Execute command
        if args.command == "analyze":
            return self._handle_analyze(code)
        elif args.command == "review":
            return self._handle_review(code)
        elif args.command == "test":
            return self._handle_test(code)
        elif args.command == "doc":
            return self._handle_document(code)
        elif args.command == "arch":
            return self._handle_arch(code)
        elif args.command == "status":
            return self._handle_status()
        elif args.command == "interactive":
            return self._handle_interactive()

        return 0

    def _read_input(self, args) -> Optional[str]:
        """Read input from code argument or file."""
        if args.code:
            return args.code
        elif args.file:
            try:
                with open(args.file, "r") as f:
                    return f.read()
            except FileNotFoundError:
                print(f"{Fore.RED}❌ File not found: {args.file}{Style.RESET_ALL}")
                return None
            except Exception as e:
                print(f"{Fore.RED}❌ Error reading file: {e}{Style.RESET_ALL}")
                return None
        else:
            # For interactive mode, no input needed
            if args.command == "interactive" or args.command == "status":
                return ""
            print(
                f"{Fore.YELLOW}⚠️  No input provided. Use --code or --file{Style.RESET_ALL}"
            )
            return None

    def _handle_analyze(self, code: str) -> int:
        """Handle analyze command."""
        print(f"{Fore.CYAN}🔍 Running full analysis...{Style.RESET_ALL}")
        results = self.orchestrator.execute_full_analysis(code)
        return 0

    def _handle_review(self, code: str) -> int:
        """Handle review command."""
        print(f"{Fore.CYAN}🔍 Running code review...{Style.RESET_ALL}")
        result = self.orchestrator.execute_task(TaskType.CODE_REVIEW, code)
        return 0 if result.success else 1

    def _handle_test(self, code: str) -> int:
        """Handle test command."""
        print(f"{Fore.CYAN}🧪 Generating tests...{Style.RESET_ALL}")
        result = self.orchestrator.execute_task(TaskType.TEST_GENERATION, code)
        return 0 if result.success else 1

    def _handle_document(self, code: str) -> int:
        """Handle document command."""
        print(f"{Fore.CYAN}📝 Generating documentation...{Style.RESET_ALL}")
        result = self.orchestrator.execute_task(TaskType.DOCUMENTATION, code)
        return 0 if result.success else 1

    def _handle_arch(self, code: str) -> int:
        """Handle architecture command."""
        print(f"{Fore.CYAN}🏗️  Getting architecture advice...{Style.RESET_ALL}")
        result = self.orchestrator.execute_task(TaskType.ARCHITECTURE_ADVICE, code)
        return 0 if result.success else 1

    def _handle_status(self) -> int:
        """Handle status command."""
        self.orchestrator.print_system_status()
        return 0

    def _handle_interactive(self) -> int:
        """Handle interactive mode."""
        print(
            f"{Fore.CYAN}🤖 Multi-Agent Developer System - Interactive Mode{Style.RESET_ALL}"
        )
        print(f"{Fore.CYAN}=" * 60 + Style.RESET_ALL)
        print(f"{Fore.YELLOW}Type 'exit' to quit, 'help' for commands{Style.RESET_ALL}")

        while True:
            try:
                command = input(f"\n{Fore.GREEN}agent> {Style.RESET_ALL}").strip()

                if command.lower() in ["exit", "quit", "q"]:
                    print(f"{Fore.YELLOW}👋 Goodbye!{Style.RESET_ALL}")
                    break
                elif command.lower() in ["help", "?"]:
                    self._show_interactive_help()
                elif command.lower() == "status":
                    self.orchestrator.print_system_status()
                elif command.lower().startswith("review"):
                    self._handle_interactive_command("review", command)
                elif command.lower().startswith("test"):
                    self._handle_interactive_command("test", command)
                elif command.lower().startswith("doc"):
                    self._handle_interactive_command("doc", command)
                elif command.lower().startswith("arch"):
                    self._handle_interactive_command("arch", command)
                elif command.lower().startswith("analyze"):
                    self._handle_interactive_command("analyze", command)
                elif command:
                    print(
                        f"{Fore.YELLOW}Unknown command. Type 'help' for available commands.{Style.RESET_ALL}"
                    )

            except KeyboardInterrupt:
                print(f"\n{Fore.YELLOW}👋 Goodbye!{Style.RESET_ALL}")
                break
            except Exception as e:
                print(f"{Fore.RED}❌ Error: {e}{Style.RESET_ALL}")

        return 0

    def _show_interactive_help(self):
        """Show help for interactive mode."""
        help_text = f"""
{Fore.CYAN}Available Commands:{Style.RESET_ALL}
  {Fore.GREEN}review <code or --file filename>{Style.RESET_ALL} - Review code
  {Fore.GREEN}test <code or --file filename>{Style.RESET_ALL}   - Generate tests
  {Fore.GREEN}doc <code or --file filename>{Style.RESET_ALL}    - Generate documentation
  {Fore.GREEN}arch <code or --file filename>{Style.RESET_ALL}   - Get architecture advice
  {Fore.GREEN}analyze <code or --file filename>{Style.RESET_ALL} - Run full analysis
  {Fore.GREEN}status{Style.RESET_ALL}                          - Show system status
  {Fore.GREEN}help{Style.RESET_ALL}                            - Show this help
  {Fore.GREEN}exit{Style.RESET_ALL}                            - Exit interactive mode

{Fore.YELLOW}Examples:{Style.RESET_ALL}
  review "def add(a, b): return a + b"
  test --file examples/example_code.py
  analyze "class Calculator: ..."
        """
        print(help_text)

    def _handle_interactive_command(self, command_type: str, command: str):
        """Handle interactive commands."""
        parts = command.split(maxsplit=1)
        if len(parts) < 2:
            print(
                f"{Fore.YELLOW}Usage: {command_type} <code or --file filename>{Style.RESET_ALL}"
            )
            return

        input_str = parts[1]
        if input_str.startswith("--file "):
            filename = input_str[7:].strip()
            try:
                with open(filename, "r") as f:
                    code = f.read()
            except Exception as e:
                print(f"{Fore.RED}❌ Error reading file: {e}{Style.RESET_ALL}")
                return
        else:
            code = input_str

        # Execute the command
        if command_type == "review":
            self.orchestrator.execute_task(TaskType.CODE_REVIEW, code)
        elif command_type == "test":
            self.orchestrator.execute_task(TaskType.TEST_GENERATION, code)
        elif command_type == "doc":
            self.orchestrator.execute_task(TaskType.DOCUMENTATION, code)
        elif command_type == "arch":
            self.orchestrator.execute_task(TaskType.ARCHITECTURE_ADVICE, code)
        elif command_type == "analyze":
            self.orchestrator.execute_full_analysis(code)


def main():
    """Main entry point."""
    cli = SimpleCLI()
    return cli.run()


if __name__ == "__main__":
    sys.exit(main())
