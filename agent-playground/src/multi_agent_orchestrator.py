"""
Simplified Multi-Agent Orchestrator for Developer Productivity System.
Compatible with LangChain 1.x.
"""

import json
import os
from dataclasses import asdict, dataclass
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional, Union

from .agents.architecture_advisor import ArchitectureAdvisor
from .agents.base_agent import BaseAgent
from .agents.code_reviewer import CodeReviewer
from .agents.documentation_agent import DocumentationAgent
from .agents.test_writer import TestWriter


class TaskType(Enum):
    """Types of tasks that can be performed by the multi-agent system."""

    CODE_REVIEW = "code_review"
    TEST_GENERATION = "test_generation"
    DOCUMENTATION = "documentation"
    ARCHITECTURE_ADVICE = "architecture_advice"
    FULL_ANALYSIS = "full_analysis"


@dataclass
class TaskResult:
    """Result of a task performed by an agent."""

    agent_name: str
    task_type: TaskType
    input_data: str
    output: Dict[str, Any]
    timestamp: datetime
    execution_time: float
    success: bool
    error_message: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        result = asdict(self)
        result["task_type"] = self.task_type.value
        result["timestamp"] = self.timestamp.isoformat()
        return result


class SimpleMultiAgentOrchestrator:
    """
    Simplified orchestrator that manages multiple specialized agents for developer tasks.
    Compatible with LangChain 1.x.
    """

    def __init__(self, verbose: bool = True):
        """
        Initialize the multi-agent orchestrator.

        Args:
            verbose: Whether to print verbose output
        """
        self.verbose = verbose
        self.agents: Dict[str, BaseAgent] = {}
        self.task_history: List[TaskResult] = []
        self._initialize_agents()

        if self.verbose:
            print("🚀 Simple Multi-Agent Developer System Initialized")
            print("Available Agents:")
            for agent_name, agent in self.agents.items():
                print(f"  • {agent_name}: {agent.role}")

    def _initialize_agents(self) -> None:
        """Initialize all available agents."""
        # Initialize all real agents
        self.agents["code_reviewer"] = CodeReviewer()
        self.agents["test_writer"] = TestWriter()
        self.agents["documentation_agent"] = DocumentationAgent()
        self.agents["architecture_advisor"] = ArchitectureAdvisor()

    def get_agent(self, agent_name: str) -> BaseAgent:
        """
        Get an agent by name.

        Args:
            agent_name: Name of the agent

        Returns:
            The agent instance

        Raises:
            ValueError: If agent not found
        """
        if agent_name not in self.agents:
            raise ValueError(
                f"Agent '{agent_name}' not found. Available agents: {list(self.agents.keys())}"
            )
        return self.agents[agent_name]

    def execute_task(
        self,
        task_type: Union[TaskType, str],
        input_data: str,
        context: Optional[Dict[str, Any]] = None,
        agent_name: Optional[str] = None,
    ) -> TaskResult:
        """
        Execute a task using the appropriate agent.

        Args:
            task_type: Type of task to execute
            input_data: Input data for the task (e.g., code to review)
            context: Optional context information
            agent_name: Specific agent to use (if None, auto-selects based on task)

        Returns:
            TaskResult with execution details
        """
        # Convert string task_type to enum if needed
        if isinstance(task_type, str):
            try:
                task_type = TaskType(task_type)
            except ValueError:
                raise ValueError(
                    f"Invalid task type: {task_type}. Valid types: {[t.value for t in TaskType]}"
                )

        start_time = datetime.now()

        try:
            # Select agent
            if agent_name:
                agent = self.get_agent(agent_name)
            else:
                agent = self._select_agent_for_task(task_type)

            if self.verbose:
                print(f"🤖 Executing task with {agent.name}...")

            # Execute task
            output = agent.process(input_data, context)
            execution_time = (datetime.now() - start_time).total_seconds()

            # Create result
            result = TaskResult(
                agent_name=agent.name,
                task_type=task_type,
                input_data=input_data[:500] + "..."
                if len(input_data) > 500
                else input_data,
                output=output,
                timestamp=datetime.now(),
                execution_time=execution_time,
                success=True,
            )

            # Add to history
            self.task_history.append(result)

            if self.verbose:
                self._print_task_result(result)

            return result

        except Exception as e:
            execution_time = (datetime.now() - start_time).total_seconds()
            result = TaskResult(
                agent_name=agent_name or "unknown",
                task_type=task_type,
                input_data=input_data[:500] + "..."
                if len(input_data) > 500
                else input_data,
                output={},
                timestamp=datetime.now(),
                execution_time=execution_time,
                success=False,
                error_message=str(e),
            )
            self.task_history.append(result)

            if self.verbose:
                print(f"❌ Task failed: {e}")

            return result

    def _select_agent_for_task(self, task_type: TaskType) -> BaseAgent:
        """
        Select the appropriate agent for a given task type.

        Args:
            task_type: Type of task

        Returns:
            Selected agent

        Raises:
            ValueError: If no agent found for task type
        """
        agent_map = {
            TaskType.CODE_REVIEW: self.agents["code_reviewer"],
            TaskType.TEST_GENERATION: self.agents["test_writer"],
            TaskType.DOCUMENTATION: self.agents["documentation_agent"],
            TaskType.ARCHITECTURE_ADVICE: self.agents["architecture_advisor"],
        }

        if task_type in agent_map:
            return agent_map[task_type]
        else:
            raise ValueError(f"No agent configured for task type: {task_type}")

    def execute_full_analysis(
        self, code: str, context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, TaskResult]:
        """
        Execute a full analysis using all agents.

        Args:
            code: Code to analyze
            context: Optional context information

        Returns:
            Dictionary of task results by agent name
        """
        if self.verbose:
            print(f"🔍 Starting full analysis of code...")
            print(f"Code length: {len(code)} characters")

        results = {}

        # Execute code review (only real agent for now)
        if self.verbose:
            print(f"\n1. Running Code Review...")
        results["code_review"] = self.execute_task(TaskType.CODE_REVIEW, code, context)

        # Execute other analyses (dummy agents)
        tasks = [
            ("test_generation", "2. Generating Tests..."),
            ("documentation", "3. Creating Documentation..."),
            ("architecture_advice", "4. Providing Architecture Advice..."),
        ]

        for task_name, message in tasks:
            if self.verbose:
                print(f"\n{message}")
            results[task_name] = self.execute_task(TaskType(task_name), code, context)

        if self.verbose:
            self._print_full_analysis_summary(results)

        return results

    def _print_task_result(self, result: TaskResult) -> None:
        """Print the result of a task."""
        print(f"\n✅ Task completed successfully!")
        print(f"Agent: {result.agent_name}")
        print(f"Execution Time: {result.execution_time:.2f}s")

        # Format and print agent output
        if hasattr(
            self.get_agent(result.agent_name.lower().replace(" ", "_")), "format_output"
        ):
            try:
                agent = self.get_agent(result.agent_name.lower().replace(" ", "_"))
                formatted_output = agent.format_output(result.output)
                print(f"\n{formatted_output}")
            except:
                # If formatting fails, just print the raw output
                print(f"\nOutput: {result.output}")

    def _print_full_analysis_summary(self, results: Dict[str, TaskResult]) -> None:
        """Print a summary of full analysis results."""
        print(f"\n🎉 Full Analysis Complete!")
        print(f"=" * 60)

        successful_tasks = sum(1 for r in results.values() if r.success)
        total_tasks = len(results)
        total_time = sum(r.execution_time for r in results.values())

        print(f"Summary:")
        print(f"  Tasks Completed: {successful_tasks}/{total_tasks}")
        print(f"  Total Execution Time: {total_time:.2f}s")
        print(f"  Average Time per Task: {total_time / total_tasks:.2f}s")

        print(f"\nDetailed Results:")
        for task_name, result in results.items():
            status = "✅" if result.success else "❌"
            print(
                f"  {status} {task_name.replace('_', ' ').title()}: {result.execution_time:.2f}s"
            )

        # Check if we have real results from code review
        if results.get("code_review") and results["code_review"].success:
            review_output = results["code_review"].output
            if not review_output.get("dummy", False):
                print(f"\n📊 Code Review Insights:")
                severity = review_output.get("severity_level", "unknown")
                print(f"  • Severity: {severity.upper()}")

        print(f"=" * 60)

    def get_task_history(self, limit: Optional[int] = None) -> List[TaskResult]:
        """
        Get task execution history.

        Args:
            limit: Maximum number of history items to return

        Returns:
            List of task results
        """
        if limit:
            return self.task_history[-limit:]
        return self.task_history

    def clear_history(self) -> None:
        """Clear task execution history."""
        self.task_history.clear()
        if self.verbose:
            print(f"🗑️  Task history cleared")

    def save_history(self, filepath: str) -> None:
        """
        Save task history to a JSON file.

        Args:
            filepath: Path to save the history file
        """
        history_data = [result.to_dict() for result in self.task_history]

        with open(filepath, "w") as f:
            json.dump(history_data, f, indent=2)

        if self.verbose:
            print(f"💾 History saved to {filepath}")

    def load_history(self, filepath: str) -> None:
        """
        Load task history from a JSON file.

        Args:
            filepath: Path to load the history file from
        """
        try:
            with open(filepath, "r") as f:
                history_data = json.load(f)

            # Convert back to TaskResult objects
            self.task_history = []
            for item in history_data:
                result = TaskResult(
                    agent_name=item["agent_name"],
                    task_type=TaskType(item["task_type"]),
                    input_data=item["input_data"],
                    output=item["output"],
                    timestamp=datetime.fromisoformat(item["timestamp"]),
                    execution_time=item["execution_time"],
                    success=item["success"],
                    error_message=item.get("error_message"),
                )
                self.task_history.append(result)

            if self.verbose:
                print(f"📂 History loaded from {filepath}")
                print(f"  Loaded {len(self.task_history)} task records")

        except FileNotFoundError:
            if self.verbose:
                print(f"⚠️  History file not found: {filepath}")
        except Exception as e:
            if self.verbose:
                print(f"❌ Failed to load history: {e}")

    def get_system_status(self) -> Dict[str, Any]:
        """
        Get the current status of the multi-agent system.

        Returns:
            Dictionary with system status information
        """
        return {
            "total_agents": len(self.agents),
            "agents_available": list(self.agents.keys()),
            "total_tasks_executed": len(self.task_history),
            "successful_tasks": sum(1 for r in self.task_history if r.success),
            "failed_tasks": sum(1 for r in self.task_history if not r.success),
            "average_execution_time": (
                sum(r.execution_time for r in self.task_history)
                / len(self.task_history)
                if self.task_history
                else 0
            ),
            "last_execution": (
                self.task_history[-1].timestamp.isoformat()
                if self.task_history
                else None
            ),
        }

    def print_system_status(self) -> None:
        """Print the current system status."""
        status = self.get_system_status()

        print(f"\n🤖 Multi-Agent System Status")
        print(f"=" * 40)
        print(f"Agents: {status['total_agents']} available")
        for agent_name in status["agents_available"]:
            print(f"  • {agent_name}")

        print(f"\nTask Statistics:")
        print(f"  Total Tasks: {status['total_tasks_executed']}")
        print(f"  Successful: {status['successful_tasks']}")
        print(f"  Failed: {status['failed_tasks']}")
        print(
            f"  Success Rate: {status['successful_tasks'] / max(status['total_tasks_executed'], 1):.1%}"
        )
        print(f"  Avg. Execution Time: {status['average_execution_time']:.2f}s")

        if status["last_execution"]:
            print(f"\nLast Execution:")
            print(f"  {status['last_execution']}")

        print(f"=" * 40)
