#!/usr/bin/env python3
"""
API Connection Test Script for Multi-Agent Developer System.

This script tests connectivity to various AI providers to ensure
the system can connect to the configured API endpoint.
"""

import json
import os
import sys
import time
from pathlib import Path
from typing import Any, Dict, Optional

# Add src directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

try:
    from colorama import Fore, Style, init
    from dotenv import load_dotenv
    from langchain_openai import ChatOpenAI

    init(autoreset=True)
except ImportError as e:
    print(f"Error importing modules: {e}")
    print("Please install dependencies: pip install -r requirements.txt")
    sys.exit(1)


class APITester:
    """Test connectivity to AI providers."""

    def __init__(self):
        load_dotenv()
        self.api_key = os.getenv("OPENAI_API_KEY")
        self.api_base_url = os.getenv("OPENAI_API_BASE_URL")
        self.model = os.getenv("OPENAI_MODEL", "gpt-3.5-turbo")

    def test_connection(self) -> Dict[str, Any]:
        """Test connection to the configured API endpoint."""
        print(f"{Fore.CYAN}🔌 Testing API Connection{Style.RESET_ALL}")
        print(f"{Fore.CYAN}{'=' * 50}{Style.RESET_ALL}")

        results = {
            "success": False,
            "provider": "Unknown",
            "model": self.model,
            "response_time": 0,
            "error": None,
            "details": {},
        }

        # Check configuration
        if not self.api_key:
            results["error"] = "OPENAI_API_KEY not found in environment variables"
            return results

        print(f"📋 Configuration:")
        print(f"  Model: {self.model}")
        print(f"  API Base URL: {self.api_base_url or 'Default (OpenAI)'}")
        print(f"  API Key: {'Set' if self.api_key else 'Not set'}")

        # Determine provider
        if self.api_base_url:
            if "localhost" in self.api_base_url or "127.0.0.1" in self.api_base_url:
                results["provider"] = "Local (Ollama/LM Studio)"
            elif "azure" in self.api_base_url:
                results["provider"] = "Azure OpenAI"
            elif "together" in self.api_base_url:
                results["provider"] = "Together AI"
            elif "anthropic" in self.api_base_url:
                results["provider"] = "Anthropic"
            elif "google" in self.api_base_url:
                results["provider"] = "Google AI"
            else:
                results["provider"] = "Custom Provider"
        else:
            results["provider"] = "OpenAI"

        print(f"  Provider: {results['provider']}")

        # Test connection
        print(f"\n🔍 Testing connection...")

        try:
            # Initialize LLM with configuration
            llm_kwargs = {
                "model": self.model,
                "temperature": 0.1,  # Low temperature for predictable response
                "max_tokens": 100,
                "openai_api_key": self.api_key,
            }

            if self.api_base_url:
                llm_kwargs["base_url"] = self.api_base_url

            llm = ChatOpenAI(**llm_kwargs)

            # Simple test prompt
            test_prompt = "Hello! Please respond with just 'OK' if you can read this."

            start_time = time.time()
            response = llm.invoke(test_prompt)
            end_time = time.time()

            response_time = end_time - start_time
            results["response_time"] = response_time
            results["details"]["response"] = response.content.strip()
            results["details"]["response_length"] = len(response.content)

            # Check response
            if "OK" in response.content.upper():
                results["success"] = True
                print(f"{Fore.GREEN}✅ Connection successful!{Style.RESET_ALL}")
                print(f"  Response: {response.content.strip()}")
                print(f"  Response time: {response_time:.2f}s")
            else:
                results["success"] = True  # Still successful connection
                results["details"]["warning"] = "Unexpected response format"
                print(
                    f"{Fore.YELLOW}⚠️  Connection established but unexpected response{Style.RESET_ALL}"
                )
                print(f"  Response: {response.content.strip()}")
                print(f"  Response time: {response_time:.2f}s")

        except Exception as e:
            results["error"] = str(e)
            print(f"{Fore.RED}❌ Connection failed{Style.RESET_ALL}")
            print(f"  Error: {e}")

        return results

    def test_providers(self) -> Dict[str, Dict[str, Any]]:
        """Test multiple common providers."""
        print(f"{Fore.CYAN}🌐 Testing Common Providers{Style.RESET_ALL}")
        print(f"{Fore.CYAN}{'=' * 50}{Style.RESET_ALL}")

        providers = {
            "OpenAI (Default)": {
                "api_key": self.api_key,
                "base_url": None,
                "model": "gpt-3.5-turbo",
            },
            "Ollama (Local)": {
                "api_key": "ollama",
                "base_url": "http://localhost:11434/v1",
                "model": "llama3.2",
            },
            "LM Studio (Local)": {
                "api_key": "lm-studio",
                "base_url": "http://localhost:1234/v1",
                "model": "local-model",
            },
        }

        results = {}

        for provider_name, config in providers.items():
            print(f"\n🔧 Testing {provider_name}...")

            # Skip if no API key for OpenAI
            if provider_name == "OpenAI (Default)" and not config["api_key"]:
                print(f"{Fore.YELLOW}⚠️  Skipped: No API key{Style.RESET_ALL}")
                continue

            # Test connection
            original_env = os.environ.copy()

            try:
                # Temporarily set environment
                os.environ["OPENAI_API_KEY"] = config["api_key"]
                if config["base_url"]:
                    os.environ["OPENAI_API_BASE_URL"] = config["base_url"]
                os.environ["OPENAI_MODEL"] = config["model"]

                tester = APITester()
                result = tester.test_connection()
                results[provider_name] = result

            except Exception as e:
                print(f"{Fore.RED}❌ Test failed: {e}{Style.RESET_ALL}")
                results[provider_name] = {"success": False, "error": str(e)}
            finally:
                # Restore original environment
                os.environ.clear()
                os.environ.update(original_env)

        return results

    def check_environment(self) -> Dict[str, Any]:
        """Check environment configuration."""
        print(f"{Fore.CYAN}⚙️  Environment Check{Style.RESET_ALL}")
        print(f"{Fore.CYAN}{'=' * 50}{Style.RESET_ALL}")

        env_vars = [
            "OPENAI_API_KEY",
            "OPENAI_API_BASE_URL",
            "OPENAI_MODEL",
            "OPENAI_TEMPERATURE",
            "MAX_TOKENS",
            "VERBOSE",
        ]

        results = {}
        for var in env_vars:
            value = os.getenv(var)
            if value:
                # Mask API key for security
                if var == "OPENAI_API_KEY" and len(value) > 8:
                    masked = value[:4] + "*" * (len(value) - 8) + value[-4:]
                    results[var] = masked
                else:
                    results[var] = value
            else:
                results[var] = None

        # Print results
        for var, value in results.items():
            status = f"{Fore.GREEN}✅" if value else f"{Fore.YELLOW}⚠️"
            value_display = value if value else "Not set"
            print(f"{status} {var}: {value_display}{Style.RESET_ALL}")

        return results


def main():
    """Main entry point."""
    print(f"{Fore.CYAN}🤖 API Connection Test Suite{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'=' * 60}{Style.RESET_ALL}")

    tester = APITester()

    # Check environment
    env_results = tester.check_environment()

    # Test current configuration
    print(f"\n{Fore.CYAN}🔌 Testing Current Configuration{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'=' * 50}{Style.RESET_ALL}")

    connection_result = tester.test_connection()

    # Ask if user wants to test other providers
    print(f"\n{Fore.CYAN}🌐 Test Other Providers?{Style.RESET_ALL}")
    print(
        f"{Fore.YELLOW}This will test common local providers (Ollama, LM Studio){Style.RESET_ALL}"
    )

    try:
        response = (
            input(f"{Fore.GREEN}Test other providers? (y/N): {Style.RESET_ALL}")
            .strip()
            .lower()
        )

        if response in ["y", "yes"]:
            provider_results = tester.test_providers()

            # Print summary
            print(f"\n{Fore.CYAN}📊 Provider Test Summary{Style.RESET_ALL}")
            print(f"{Fore.CYAN}{'=' * 50}{Style.RESET_ALL}")

            for provider, result in provider_results.items():
                status = f"{Fore.GREEN}✅" if result.get("success") else f"{Fore.RED}❌"
                time_str = (
                    f"{result.get('response_time', 0):.2f}s"
                    if result.get("response_time")
                    else "N/A"
                )
                print(f"{status} {provider}: {time_str}")

    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}👋 Test interrupted{Style.RESET_ALL}")

    # Final recommendations
    print(f"\n{Fore.CYAN}💡 Recommendations{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'=' * 50}{Style.RESET_ALL}")

    if connection_result["success"]:
        print(f"{Fore.GREEN}✅ Your current configuration is working!{Style.RESET_ALL}")
        print(f"  Provider: {connection_result['provider']}")
        print(f"  Response time: {connection_result['response_time']:.2f}s")

        if connection_result["response_time"] > 5.0:
            print(
                f"{Fore.YELLOW}⚠️  Slow response time. Consider using a local model.{Style.RESET_ALL}"
            )
    else:
        print(f"{Fore.RED}❌ Current configuration failed.{Style.RESET_ALL}")

        if "localhost" in str(tester.api_base_url) or "127.0.0.1" in str(
            tester.api_base_url
        ):
            print(f"{Fore.YELLOW}💡 For local models:{Style.RESET_ALL}")
            print(f"  1. Ensure your local server is running")
            print(f"  2. Check the API URL is correct")
            print(f"  3. Verify the model name is available")
        elif not tester.api_base_url:
            print(f"{Fore.YELLOW}💡 For OpenAI:{Style.RESET_ALL}")
            print(f"  1. Verify your API key is valid")
            print(f"  2. Check your internet connection")
            print(f"  3. Ensure you have API credits")

    print(f"\n{Fore.CYAN}🔧 Next Steps{Style.RESET_ALL}")
    print("  1. Run: python test.py (system tests)")
    print("  2. Run: python run.py check (environment check)")
    print("  3. Run: python src/cli.py interactive (start using system)")

    return 0 if connection_result["success"] else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}👋 Goodbye!{Style.RESET_ALL}")
        sys.exit(0)
    except Exception as e:
        print(f"{Fore.RED}❌ Unexpected error: {e}{Style.RESET_ALL}")
        sys.exit(1)
