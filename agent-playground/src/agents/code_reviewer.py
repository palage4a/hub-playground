"""
Code Reviewer Agent for the multi-agent developer system.
"""

import os
from typing import Any, Dict, Optional

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

from .base_agent import BaseAgent


class CodeReviewer(BaseAgent):
    """Agent specialized in code review and analysis."""

    def __init__(self, model: Optional[str] = None):
        """
        Initialize the Code Reviewer agent.

        Args:
            model: OpenAI model to use (defaults to env variable)
        """
        super().__init__(
            name="Code Reviewer",
            role="Expert code reviewer analyzing code for bugs, style issues, performance problems, and security vulnerabilities",
            model=model,
        )

        # Initialize the LLM
        # Initialize the LLM with optional custom base URL
        llm_kwargs = {
            "model": self.model,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
            "openai_api_key": self.api_key,
        }

        if self.api_base_url:
            llm_kwargs["base_url"] = self.api_base_url

        self.llm = ChatOpenAI(**llm_kwargs)

        # Get custom prompt from environment or use default
        self.system_prompt = os.getenv(
            "CODE_REVIEWER_PROMPT",
            "You are an expert code reviewer with 10+ years of experience. "
            "Your task is to analyze code for:\n"
            "1. Bugs and logical errors\n"
            "2. Code style and best practices violations\n"
            "3. Performance issues and optimization opportunities\n"
            "4. Security vulnerabilities\n"
            "5. Maintainability and readability concerns\n"
            "6. Test coverage gaps\n\n"
            "Provide specific, actionable feedback with code examples when possible. "
            "Be constructive and focus on helping the developer improve their code.",
        )

    def get_system_prompt(self) -> str:
        """
        Get the system prompt for the code reviewer.

        Returns:
            System prompt string
        """
        return self.system_prompt

    def process(
        self, input_data: Any, context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Review and analyze code.

        Args:
            input_data: Code to review (string)
            context: Optional context (e.g., language, framework)

        Returns:
            Dictionary with review results
        """
        if not isinstance(input_data, str):
            raise ValueError("Code Reviewer expects string input (code)")

        # Prepare the prompt
        prompt = ChatPromptTemplate.from_messages(
            [
                SystemMessage(content=self.system_prompt),
                HumanMessage(
                    content=f"Please review the following code:\n\n{input_data}\n\n"
                    f"Context: {context or 'No additional context provided'}"
                ),
            ]
        )

        # Generate review
        messages = prompt.format_messages()
        response = self.llm.invoke(messages)

        # Parse and structure the response
        review_text = response.content

        # Extract key sections (this is a simple heuristic - could be enhanced)
        sections = self._parse_review_sections(review_text)

        return {
            "agent": self.name,
            "input_type": "code",
            "review": review_text,
            "sections": sections,
            "summary": self._generate_summary(sections),
            "severity_level": self._assess_severity(sections),
        }

    def _parse_review_sections(self, review_text: str) -> Dict[str, str]:
        """
        Parse the review text into structured sections.

        Args:
            review_text: The full review text

        Returns:
            Dictionary of sections
        """
        sections = {
            "bugs": "",
            "style": "",
            "performance": "",
            "security": "",
            "maintainability": "",
            "tests": "",
            "general": "",
        }

        # Simple keyword-based parsing (could be enhanced with more sophisticated NLP)
        text_lower = review_text.lower()

        # Look for sections in the text
        lines = review_text.split("\n")
        current_section = "general"

        for line in lines:
            line_lower = line.lower().strip()

            # Check for section headers
            if any(
                keyword in line_lower
                for keyword in ["bug", "error", "issue", "problem"]
            ):
                if "bug" in line_lower or "error" in line_lower:
                    current_section = "bugs"
            elif any(
                keyword in line_lower
                for keyword in ["style", "format", "convention", "best practice"]
            ):
                current_section = "style"
            elif any(
                keyword in line_lower
                for keyword in ["performance", "optimization", "speed", "efficiency"]
            ):
                current_section = "performance"
            elif any(
                keyword in line_lower
                for keyword in ["security", "vulnerability", "secure", "attack"]
            ):
                current_section = "security"
            elif any(
                keyword in line_lower
                for keyword in ["maintain", "readability", "clean", "refactor"]
            ):
                current_section = "maintainability"
            elif any(
                keyword in line_lower
                for keyword in ["test", "coverage", "unit", "integration"]
            ):
                current_section = "tests"
            elif line_lower.startswith("#") or line_lower.startswith("##"):
                # Reset to general for new major sections
                current_section = "general"

            # Add line to current section
            if sections[current_section]:
                sections[current_section] += "\n" + line
            else:
                sections[current_section] = line

        # Clean up empty sections
        return {k: v for k, v in sections.items() if v.strip()}

    def _generate_summary(self, sections: Dict[str, str]) -> str:
        """
        Generate a summary from the parsed sections.

        Args:
            sections: Parsed review sections

        Returns:
            Summary string
        """
        if not sections:
            return "No issues found in the code review."

        issue_count = len([v for v in sections.values() if v])
        critical_sections = ["bugs", "security"]

        has_critical = any(section in sections for section in critical_sections)

        summary = f"Code review completed. Found {issue_count} categories of issues.\n"

        if has_critical:
            summary += "⚠️  Critical issues found that require immediate attention.\n"

        # List the sections that have content
        if sections:
            summary += "\nAreas addressed:\n"
            for section, content in sections.items():
                if content:
                    summary += f"  • {section.capitalize()}\n"

        return summary

    def _assess_severity(self, sections: Dict[str, str]) -> str:
        """
        Assess the overall severity of issues found.

        Args:
            sections: Parsed review sections

        Returns:
            Severity level (low, medium, high, critical)
        """
        if not sections:
            return "low"

        # Check for critical sections
        critical_sections = ["bugs", "security"]
        has_critical = any(section in sections for section in critical_sections)

        if has_critical:
            return "critical"

        # Count non-empty sections
        issue_count = len([v for v in sections.values() if v])

        if issue_count >= 4:
            return "high"
        elif issue_count >= 2:
            return "medium"
        else:
            return "low"

    def format_output(self, result: Dict[str, Any]) -> str:
        """
        Format the code review output for display.

        Args:
            result: The review results

        Returns:
            Formatted string
        """
        output = super().format_output(result["review"])

        # Add structured information
        output += f"\n📊 Summary: {result['summary']}\n"
        output += f"⚠️  Severity Level: {result['severity_level'].upper()}\n"

        if result.get("sections"):
            output += "\n📋 Detailed Sections:\n"
            for section, content in result["sections"].items():
                if content:
                    output += f"\n--- {section.upper()} ---\n{content}\n"

        return output
