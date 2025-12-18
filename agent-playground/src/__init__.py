"""
Multi-Agent Developer Productivity System.

This package provides a modular system of AI agents to assist with software development tasks.
"""

from .agents import (
    ArchitectureAdvisor,
    BaseAgent,
    CodeReviewer,
    DocumentationAgent,
    TestWriter,
)
from .cli import SimpleCLI
from .multi_agent_orchestrator import SimpleMultiAgentOrchestrator, TaskResult, TaskType

__all__ = [
    "BaseAgent",
    "CodeReviewer",
    "TestWriter",
    "DocumentationAgent",
    "ArchitectureAdvisor",
    "SimpleMultiAgentOrchestrator",
    "TaskType",
    "TaskResult",
    "SimpleCLI",
]

__version__ = "1.0.0"
