"""
Test Writer Agent for the multi-agent developer system.
"""

import os
from typing import Any, Dict, Optional

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

from .base_agent import BaseAgent


class TestWriter(BaseAgent):
    """Agent specialized in writing tests for code."""

    def __init__(self, model: Optional[str] = None):
        """
        Initialize the Test Writer agent.

        Args:
            model: OpenAI model to use (defaults to env variable)
        """
        super().__init__(
            name="Test Writer",
            role="Expert test writer creating comprehensive unit tests, integration tests, and test documentation",
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
            "TEST_WRITER_PROMPT",
            "You are an expert test writer with 10+ years of experience in software testing. "
            "Your task is to create comprehensive tests for code including:\n"
            "1. Unit tests for individual functions/methods\n"
            "2. Integration tests for component interactions\n"
            "3. Edge case and boundary condition tests\n"
            "4. Error handling and exception tests\n"
            "5. Performance tests when applicable\n"
            "6. Test documentation and setup instructions\n\n"
            "Provide complete, runnable test code with clear assertions. "
            "Include comments explaining what each test verifies. "
            "Follow best practices for the specific programming language and testing framework.",
        )

    def get_system_prompt(self) -> str:
        """
        Get the system prompt for the test writer.

        Returns:
            System prompt string
        """
        return self.system_prompt

    def process(
        self, input_data: Any, context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Write tests for the provided code.

        Args:
            input_data: Code to test (string)
            context: Optional context (e.g., language, framework, testing library)

        Returns:
            Dictionary with test generation results
        """
        if not isinstance(input_data, str):
            raise ValueError("Test Writer expects string input (code)")

        # Extract language/framework from context or infer from code
        language = self._detect_language(input_data, context)
        test_framework = self._get_test_framework(language, context)

        # Prepare the prompt with language-specific instructions
        prompt = ChatPromptTemplate.from_messages(
            [
                SystemMessage(content=self.system_prompt),
                HumanMessage(
                    content=f"Please write comprehensive tests for the following {language} code:\n\n"
                    f"Code:\n{input_data}\n\n"
                    f"Testing Framework: {test_framework}\n"
                    f"Additional Context: {context or 'No additional context provided'}\n\n"
                    f"Requirements:\n"
                    f"1. Write complete, runnable test code\n"
                    f"2. Cover all functions/methods in the code\n"
                    f"3. Include edge cases and error conditions\n"
                    f"4. Add comments explaining each test\n"
                    f"5. Include setup/teardown if needed\n"
                    f"6. Follow {language} and {test_framework} best practices"
                ),
            ]
        )

        # Generate tests
        messages = prompt.format_messages()
        response = self.llm.invoke(messages)

        test_code = response.content

        # Analyze test coverage
        coverage_analysis = self._analyze_test_coverage(input_data, test_code)

        return {
            "agent": self.name,
            "input_type": "code",
            "language": language,
            "test_framework": test_framework,
            "test_code": test_code,
            "coverage_analysis": coverage_analysis,
            "test_count": self._count_tests(test_code),
            "setup_instructions": self._extract_setup_instructions(test_code),
        }

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

        if (
            "def " in code_lower
            and "import " in code_lower
            and ("numpy" in code_lower or "pandas" in code_lower)
        ):
            return "Python"
        elif "def " in code_lower and "import " in code_lower:
            return "Python"
        elif "function " in code_lower and (
            "const " in code_lower or "let " in code_lower
        ):
            return "JavaScript"
        elif (
            "public " in code_lower
            and "class " in code_lower
            and ("void " in code_lower or "int " in code_lower)
        ):
            return "Java"
        elif "#include" in code_lower or "using namespace" in code_lower:
            return "C++"
        elif "func " in code_lower and "package " in code_lower:
            return "Go"
        elif "fn " in code_lower and "use " in code_lower:
            return "Rust"
        else:
            # Default to Python if can't detect
            return "Python"

    def _get_test_framework(
        self, language: str, context: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Get the appropriate test framework for the language.

        Args:
            language: Programming language
            context: Optional context information

        Returns:
            Test framework name
        """
        if context and "test_framework" in context:
            return context["test_framework"]

        # Map languages to default test frameworks
        framework_map = {
            "Python": "pytest",
            "JavaScript": "Jest",
            "TypeScript": "Jest",
            "Java": "JUnit",
            "C++": "Google Test",
            "Go": "testing",
            "Rust": "cargo test",
        }

        return framework_map.get(language, "pytest")

    def _analyze_test_coverage(
        self, source_code: str, test_code: str
    ) -> Dict[str, Any]:
        """
        Analyze test coverage of the source code.

        Args:
            source_code: Original source code
            test_code: Generated test code

        Returns:
            Coverage analysis dictionary
        """
        # Simple heuristic-based coverage analysis
        analysis = {
            "estimated_coverage": "medium",  # low, medium, high
            "functions_tested": [],
            "edge_cases_covered": False,
            "error_handling_tested": False,
            "performance_tests": False,
        }

        # Count functions in source code
        source_lines = source_code.split("\n")
        function_count = sum(
            1
            for line in source_lines
            if any(
                keyword in line
                for keyword in ["def ", "function ", "fn ", "public ", "private "]
            )
        )

        # Count test functions in test code
        test_lines = test_code.split("\n")
        test_function_count = sum(
            1
            for line in test_lines
            if any(
                keyword in line.lower()
                for keyword in ["test_", "it(", "describe(", "@test"]
            )
        )

        # Simple coverage estimation
        if function_count > 0:
            coverage_ratio = test_function_count / function_count
            if coverage_ratio >= 1.5:
                analysis["estimated_coverage"] = "high"
            elif coverage_ratio >= 0.5:
                analysis["estimated_coverage"] = "medium"
            else:
                analysis["estimated_coverage"] = "low"

        # Check for edge cases
        edge_case_keywords = ["edge", "boundary", "corner", "extreme", "max", "min"]
        analysis["edge_cases_covered"] = any(
            keyword in test_code.lower() for keyword in edge_case_keywords
        )

        # Check for error handling
        error_keywords = ["error", "exception", "throw", "catch", "try", "fail"]
        analysis["error_handling_tested"] = any(
            keyword in test_code.lower() for keyword in error_keywords
        )

        # Check for performance tests
        perf_keywords = ["performance", "benchmark", "speed", "time", "memory"]
        analysis["performance_tests"] = any(
            keyword in test_code.lower() for keyword in perf_keywords
        )

        return analysis

    def _count_tests(self, test_code: str) -> int:
        """
        Count the number of tests in the test code.

        Args:
            test_code: Generated test code

        Returns:
            Number of tests
        """
        lines = test_code.split("\n")
        test_count = 0

        for line in lines:
            line_lower = line.lower().strip()
            # Look for test function declarations
            if any(
                line_lower.startswith(prefix)
                for prefix in ["def test_", "test(", "it(", "describe("]
            ) or any(
                keyword in line_lower
                for keyword in ["@test", "@pytest.mark", "@unittest"]
            ):
                test_count += 1

        return max(test_count, 1)  # At least 1

    def _extract_setup_instructions(self, test_code: str) -> str:
        """
        Extract setup/installation instructions from test code.

        Args:
            test_code: Generated test code

        Returns:
            Setup instructions
        """
        instructions = []

        # Look for import statements to infer dependencies
        lines = test_code.split("\n")
        imports = [
            line
            for line in lines
            if "import " in line or "require(" in line or "include " in line
        ]

        if imports:
            instructions.append("Dependencies needed:")
            for imp in imports[:5]:  # Limit to first 5 imports
                instructions.append(f"  - {imp.strip()}")

        # Add framework-specific setup
        if "pytest" in test_code.lower():
            instructions.append("\nSetup:")
            instructions.append("  1. Install pytest: pip install pytest")
            instructions.append("  2. Run tests: pytest test_file.py")
        elif "jest" in test_code.lower():
            instructions.append("\nSetup:")
            instructions.append("  1. Install Jest: npm install --save-dev jest")
            instructions.append(
                '  2. Add to package.json: {"scripts": {"test": "jest"}}'
            )
            instructions.append("  3. Run tests: npm test")
        elif "junit" in test_code.lower():
            instructions.append("\nSetup:")
            instructions.append(
                "  1. Add JUnit dependency to your build.gradle or pom.xml"
            )
            instructions.append(
                "  2. Run tests with your build tool (gradle test / mvn test)"
            )

        return "\n".join(instructions)

    def format_output(self, result: Dict[str, Any]) -> str:
        """
        Format the test writing output for display.

        Args:
            result: The test generation results

        Returns:
            Formatted string
        """
        output = super().format_output(result["test_code"])

        # Add metadata
        output += f"\n📊 Test Statistics:\n"
        output += f"  Language: {result['language']}\n"
        output += f"  Framework: {result['test_framework']}\n"
        output += f"  Number of tests: {result['test_count']}\n"
        output += f"  Estimated coverage: {result['coverage_analysis']['estimated_coverage'].upper()}\n"

        # Add coverage analysis
        analysis = result["coverage_analysis"]
        output += f"\n✅ Coverage Analysis:\n"
        output += (
            f"  Edge cases covered: {'✓' if analysis['edge_cases_covered'] else '✗'}\n"
        )
        output += f"  Error handling tested: {'✓' if analysis['error_handling_tested'] else '✗'}\n"
        output += (
            f"  Performance tests: {'✓' if analysis['performance_tests'] else '✗'}\n"
        )

        # Add setup instructions
        if result["setup_instructions"]:
            output += f"\n🔧 Setup Instructions:\n{result['setup_instructions']}\n"

        return output
