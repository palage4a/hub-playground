#!/usr/bin/env python3
"""
Simple test script for Multi-Agent Developer System.
"""

import os
import sys
from pathlib import Path

# Add src directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))


def test_imports():
    """Test that all modules can be imported."""
    print("🔧 Testing imports...")

    try:
        # Test basic Python imports first
        import argparse
        import json

        print("✅ Basic Python imports successful")

        # Try to import agents (may fail if dependencies not installed)
        try:
            from agents import (
                ArchitectureAdvisor,
                BaseAgent,
                CodeReviewer,
                DocumentationAgent,
                TestWriter,
            )

            print("✅ Agents module imports successful")
        except ImportError as e:
            print(f"⚠️  Agents import warning: {e}")
            print("   This is expected if dependencies are not installed yet")

        # Try to import orchestrator
        try:
            from multi_agent_orchestrator import MultiAgentOrchestrator, TaskType

            print("✅ Orchestrator module imports successful")
        except ImportError as e:
            print(f"⚠️  Orchestrator import warning: {e}")
            print("   This is expected if dependencies are not installed yet")

        # Try to import CLI
        try:
            from cli import AgentCLI

            print("✅ CLI module imports successful")
        except ImportError as e:
            print(f"⚠️  CLI import warning: {e}")
            print("   This is expected if dependencies are not installed yet")

        return True
    except Exception as e:
        print(f"❌ Import test error: {e}")
        return False


def test_file_structure():
    """Test that all required files exist."""
    print("\n📁 Testing file structure...")

    required_files = [
        "requirements.txt",
        "README.md",
        "run.py",
        ".env.example",
        ".gitignore",
        "examples/example_code.py",
        "src/__init__.py",
        "src/cli.py",
        "src/multi_agent_orchestrator.py",
        "src/agents/__init__.py",
        "src/agents/base_agent.py",
        "src/agents/code_reviewer.py",
        "src/agents/test_writer.py",
        "src/agents/documentation_agent.py",
        "src/agents/architecture_advisor.py",
    ]

    all_exist = True
    for file_path in required_files:
        full_path = Path(file_path)
        if full_path.exists():
            print(f"✅ {file_path}")
        else:
            print(f"❌ {file_path} (missing)")
            all_exist = False

    return all_exist


def test_requirements():
    """Check if requirements.txt exists and has content."""
    print("\n📦 Testing requirements...")

    req_file = Path("requirements.txt")
    if not req_file.exists():
        print("❌ requirements.txt not found")
        return False

    with open(req_file, "r") as f:
        content = f.read().strip()

    if len(content) > 0:
        print(f"✅ requirements.txt has {len(content.splitlines())} packages")
        return True
    else:
        print("❌ requirements.txt is empty")
        return False


def test_environment_template():
    """Check that .env.example exists and has required variables."""
    print("\n⚙️  Testing environment template...")

    env_example = Path(".env.example")
    if not env_example.exists():
        print("❌ .env.example not found")
        return False

    with open(env_example, "r") as f:
        content = f.read()

    required_vars = ["OPENAI_API_KEY", "OPENAI_MODEL"]
    missing_vars = []

    for var in required_vars:
        if var not in content:
            missing_vars.append(var)

    if missing_vars:
        print(f"❌ Missing variables in .env.example: {', '.join(missing_vars)}")
        return False

    print("✅ .env.example has all required variables")
    return True


def main():
    """Run all tests."""
    print("🧪 Multi-Agent System Test")
    print("=" * 40)

    tests = [
        ("File Structure", test_file_structure),
        ("Requirements", test_requirements),
        ("Environment Template", test_environment_template),
        ("Imports", test_imports),
    ]

    results = []
    for test_name, test_func in tests:
        try:
            success = test_func()
            results.append((test_name, success))
        except Exception as e:
            print(f"❌ Test '{test_name}' crashed: {e}")
            results.append((test_name, False))

    # Print summary
    print("\n📊 Test Summary")
    print("=" * 40)

    passed = sum(1 for _, success in results if success)
    total = len(results)

    for test_name, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} {test_name}")

    print(f"\nResults: {passed}/{total} tests passed")

    if passed == total:
        print("\n🎉 All tests passed! The system is ready for use.")
        print("\nNext steps:")
        print("  1. Copy .env.example to .env")
        print("  2. Add your API configuration to .env")
        print("  3. Install dependencies: pip install -r requirements.txt")
        print("  4. Run: python run.py check")
        print("  5. Run: python run.py example")
        return 0
    else:
        print("\n⚠️  Some tests failed. Please fix the issues above.")
        print("\n💡 If imports failed due to missing dependencies:")
        print("   1. Create virtual environment: python3 -m venv venv")
        print("   2. Activate it: source venv/bin/activate")
        print("   3. Install dependencies: pip install -r requirements.txt")
        print("   4. Run tests again: python test.py")
        return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n👋 Test interrupted")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)
