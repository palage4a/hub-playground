"""
Documentation Agent for the multi-agent developer system.
"""

import os
from typing import Any, Dict, Optional

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

from .base_agent import BaseAgent


class DocumentationAgent(BaseAgent):
    """Agent specialized in creating documentation for code."""

    def __init__(self, model: Optional[str] = None):
        """
        Initialize the Documentation Agent.

        Args:
            model: OpenAI model to use (defaults to env variable)
        """
        super().__init__(
            name="Documentation Agent",
            role="Expert technical writer creating comprehensive documentation including API docs, usage examples, and tutorials",
            model=model,
        )

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
            "DOCUMENTATION_AGENT_PROMPT",
            "You are an expert technical writer with 10+ years of experience. "
            "Your task is to create comprehensive documentation for code including:\n"
            "1. API documentation with function/method signatures\n"
            "2. Usage examples and code snippets\n"
            "3. Installation and setup instructions\n"
            "4. Tutorials and getting started guides\n"
            "5. Architecture overview and design decisions\n"
            "6. Troubleshooting and FAQ sections\n\n"
            "Create clear, concise, and well-structured documentation. "
            "Use appropriate formatting (Markdown, reStructuredText, etc.). "
            "Include code examples that are complete and runnable. "
            "Explain complex concepts in simple terms.",
        )

    def get_system_prompt(self) -> str:
        """
        Get the system prompt for the documentation agent.

        Returns:
            System prompt string
        """
        return self.system_prompt

    def process(
        self, input_data: Any, context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Create documentation for the provided code.

        Args:
            input_data: Code to document (string)
            context: Optional context (e.g., language, documentation format, target audience)

        Returns:
            Dictionary with documentation results
        """
        if not isinstance(input_data, str):
            raise ValueError("Documentation Agent expects string input (code)")

        # Determine documentation format and language
        doc_format = self._get_documentation_format(context)
        language = self._detect_language(input_data, context)
        audience = context.get("audience", "developers") if context else "developers"

        # Prepare the prompt
        prompt = ChatPromptTemplate.from_messages(
            [
                SystemMessage(content=self.system_prompt),
                HumanMessage(
                    content=f"Please create comprehensive documentation for the following {language} code:\n\n"
                    f"Code:\n{input_data}\n\n"
                    f"Documentation Format: {doc_format}\n"
                    f"Target Audience: {audience}\n"
                    f"Additional Context: {context or 'No additional context provided'}\n\n"
                    f"Requirements:\n"
                    f"1. Create well-structured documentation in {doc_format} format\n"
                    f"2. Include API documentation for all public functions/classes\n"
                    f"3. Provide usage examples with complete code snippets\n"
                    f"4. Add installation and setup instructions if applicable\n"
                    f"5. Explain the purpose and architecture of the code\n"
                    f"6. Make it accessible for {audience} audience"
                ),
            ]
        )

        # Generate documentation
        messages = prompt.format_messages()
        response = self.llm.invoke(messages)

        documentation = response.content

        # Analyze the documentation
        doc_analysis = self._analyze_documentation(documentation, input_data)

        return {
            "agent": self.name,
            "input_type": "code",
            "language": language,
            "documentation_format": doc_format,
            "target_audience": audience,
            "documentation": documentation,
            "analysis": doc_analysis,
            "sections": self._extract_sections(documentation),
            "estimated_reading_time": self._estimate_reading_time(documentation),
        }

    def _get_documentation_format(
        self, context: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Determine the documentation format.

        Args:
            context: Optional context information

        Returns:
            Documentation format (Markdown, reStructuredText, etc.)
        """
        if context and "doc_format" in context:
            return context["doc_format"]

        # Default to Markdown as it's widely used
        return "Markdown"

    def _detect_language(
        self, code: str, context: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Detect the programming language from code or context.

        Args:
            code: The source code
            context: Optional context information

        Returns:
            Detected language
        """
        if context and "language" in context:
            return context["language"]

        # Simple language detection based on code patterns
        code_lower = code.lower()

        if "def " in code_lower and "import " in code_lower:
            return "Python"
        elif "function " in code_lower and (
            "const " in code_lower or "let " in code_lower
        ):
            return "JavaScript"
        elif "public " in code_lower and "class " in code_lower:
            return "Java"
        elif "#include" in code_lower:
            return "C++"
        elif "func " in code_lower and "package " in code_lower:
            return "Go"
        else:
            return "Python"  # Default

    def _analyze_documentation(
        self, documentation: str, source_code: str
    ) -> Dict[str, Any]:
        """
        Analyze the generated documentation.

        Args:
            documentation: Generated documentation
            source_code: Original source code

        Returns:
            Analysis dictionary
        """
        analysis = {
            "completeness_score": 0.0,  # 0-1 scale
            "has_api_docs": False,
            "has_examples": False,
            "has_installation": False,
            "has_tutorial": False,
            "readability_score": "medium",  # low, medium, high
            "estimated_maintenance_level": "low",  # low, medium, high
        }

        doc_lower = documentation.lower()
        source_lower = source_code.lower()

        # Check for API documentation
        api_keywords = ["api", "function", "method", "class", "interface", "signature"]
        analysis["has_api_docs"] = any(keyword in doc_lower for keyword in api_keywords)

        # Check for examples
        example_keywords = ["example", "usage", "snippet", "demo", "how to use"]
        analysis["has_examples"] = any(
            keyword in doc_lower for keyword in example_keywords
        )

        # Check for installation instructions
        install_keywords = [
            "install",
            "setup",
            "prerequisite",
            "requirement",
            "dependency",
        ]
        analysis["has_installation"] = any(
            keyword in doc_lower for keyword in install_keywords
        )

        # Check for tutorial content
        tutorial_keywords = ["tutorial", "getting started", "guide", "walkthrough"]
        analysis["has_tutorial"] = any(
            keyword in doc_lower for keyword in tutorial_keywords
        )

        # Calculate completeness score
        features = [
            analysis["has_api_docs"],
            analysis["has_examples"],
            analysis["has_installation"],
            analysis["has_tutorial"],
        ]
        analysis["completeness_score"] = sum(features) / len(features)

        # Estimate readability based on structure and length
        lines = documentation.split("\n")
        headings = sum(1 for line in lines if line.strip().startswith("#"))
        code_blocks = documentation.count("```")

        if headings >= 3 and code_blocks >= 2:
            analysis["readability_score"] = "high"
        elif headings >= 2:
            analysis["readability_score"] = "medium"
        else:
            analysis["readability_score"] = "low"

        # Estimate maintenance level
        doc_length = len(documentation)
        if doc_length > 5000:
            analysis["estimated_maintenance_level"] = "high"
        elif doc_length > 2000:
            analysis["estimated_maintenance_level"] = "medium"
        else:
            analysis["estimated_maintenance_level"] = "low"

        return analysis

    def _extract_sections(self, documentation: str) -> Dict[str, str]:
        """
        Extract sections from the documentation.

        Args:
            documentation: Generated documentation

        Returns:
            Dictionary of sections
        """
        sections = {}
        current_section = "introduction"
        current_content = []

        lines = documentation.split("\n")

        for line in lines:
            line_stripped = line.strip()

            # Check for section headers
            if line_stripped.startswith("# "):
                if current_content:
                    sections[current_section] = "\n".join(current_content)
                current_section = "introduction"
                current_content = [line]
            elif line_stripped.startswith("## "):
                if current_content:
                    sections[current_section] = "\n".join(current_content)
                # Extract section name from header
                section_name = line_stripped[3:].lower().replace(" ", "_")
                current_section = section_name
                current_content = [line]
            elif line_stripped.startswith("### "):
                if current_content:
                    sections[current_section] = "\n".join(current_content)
                section_name = line_stripped[4:].lower().replace(" ", "_")
                current_section = section_name
                current_content = [line]
            else:
                current_content.append(line)

        # Add the last section
        if current_content:
            sections[current_section] = "\n".join(current_content)

        return sections

    def _estimate_reading_time(self, documentation: str) -> str:
        """
        Estimate reading time for the documentation.

        Args:
            documentation: Generated documentation

        Returns:
            Estimated reading time string
        """
        # Average reading speed: 200 words per minute
        words = len(documentation.split())
        minutes = words / 200

        if minutes < 1:
            return "Less than 1 minute"
        elif minutes < 5:
            return f"About {int(minutes)} minute{'s' if minutes > 1 else ''}"
        else:
            return f"About {int(minutes)} minutes"

    def format_output(self, result: Dict[str, Any]) -> str:
        """
        Format the documentation output for display.

        Args:
            result: The documentation results

        Returns:
            Formatted string
        """
        output = super().format_output(result["documentation"])

        # Add metadata
        output += f"\n📊 Documentation Analysis:\n"
        output += f"  Language: {result['language']}\n"
        output += f"  Format: {result['documentation_format']}\n"
        output += f"  Target Audience: {result['target_audience']}\n"
        output += f"  Estimated Reading Time: {result['estimated_reading_time']}\n"

        # Add analysis details
        analysis = result["analysis"]
        output += f"\n✅ Documentation Quality:\n"
        output += f"  Completeness Score: {analysis['completeness_score']:.1%}\n"
        output += f"  Readability: {analysis['readability_score'].upper()}\n"
        output += (
            f"  Maintenance Level: {analysis['estimated_maintenance_level'].upper()}\n"
        )

        # Add feature checklist
        output += f"\n📋 Features Included:\n"
        output += f"  API Documentation: {'✓' if analysis['has_api_docs'] else '✗'}\n"
        output += f"  Usage Examples: {'✓' if analysis['has_examples'] else '✗'}\n"
        output += (
            f"  Installation Guide: {'✓' if analysis['has_installation'] else '✗'}\n"
        )
        output += f"  Tutorial/Guide: {'✓' if analysis['has_tutorial'] else '✗'}\n"

        # Add sections overview
        if result["sections"]:
            output += f"\n📑 Sections Created:\n"
            for section_name, section_content in result["sections"].items():
                # Show first 50 chars of each section
                preview = section_content[:50].replace("\n", " ")
                if len(section_content) > 50:
                    preview += "..."
                output += f"  • {section_name}: {preview}\n"

        return output
