"""
Base Agent class for the multi-agent developer system.
"""

import os
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional

from dotenv import load_dotenv

# Load environment variables
load_dotenv()


class BaseAgent(ABC):
    """Base class for all agents in the system."""

    def __init__(self, name: str, role: str, model: Optional[str] = None):
        """
        Initialize the base agent.

        Args:
            name: Name of the agent
            role: Role description of the agent
            model: OpenAI model to use (defaults to env variable)
        """
        self.name = name
        self.role = role
        self.model = model or os.getenv("OPENAI_MODEL", "gpt-4-turbo-preview")
        self.temperature = float(os.getenv("OPENAI_TEMPERATURE", "0.7"))
        self.max_tokens = int(os.getenv("MAX_TOKENS", "2000"))
        self.verbose = os.getenv("VERBOSE", "True").lower() == "true"

        # Get API key from environment
        self.api_key = os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OPENAI_API_KEY not found in environment variables")

        # Get custom API base URL (optional)
        self.api_base_url = os.getenv("OPENAI_API_BASE_URL")

    @abstractmethod
    def get_system_prompt(self) -> str:
        """
        Get the system prompt for this agent.

        Returns:
            System prompt string
        """
        pass

    @abstractmethod
    def process(
        self, input_data: Any, context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Process input data and return results.

        Args:
            input_data: The input to process (could be code, text, etc.)
            context: Optional context information

        Returns:
            Dictionary with processing results
        """
        pass

    def format_output(self, result: Any) -> str:
        """
        Format the agent's output for display.

        Args:
            result: The result to format

        Returns:
            Formatted string
        """
        return f"=== {self.name} ({self.role}) ===\n\n{result}\n"

    def __str__(self) -> str:
        """String representation of the agent."""
        return f"{self.name} - {self.role}"

    def __repr__(self) -> str:
        """Representation of the agent."""
        return f"BaseAgent(name={self.name}, role={self.role})"
