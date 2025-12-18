"""
Architecture Advisor Agent for the multi-agent developer system.
"""

import os
from typing import Any, Dict, Optional

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

from .base_agent import BaseAgent


class ArchitectureAdvisor(BaseAgent):
    """Agent specialized in providing architectural advice for software projects."""

    def __init__(self, model: Optional[str] = None):
        """
        Initialize the Architecture Advisor agent.

        Args:
            model: OpenAI model to use (defaults to env variable)
        """
        super().__init__(
            name="Architecture Advisor",
            role="Expert software architect providing architectural guidance, design patterns, and system design recommendations",
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
            "ARCHITECTURE_ADVISOR_PROMPT",
            "You are an expert software architect with 15+ years of experience. "
            "Your task is to provide architectural advice for software projects including:\n"
            "1. System architecture design and patterns\n"
            "2. Scalability and performance considerations\n"
            "3. Technology stack recommendations\n"
            "4. Microservices vs monolith analysis\n"
            "5. Database design and data flow\n"
            "6. Security architecture and best practices\n"
            "7. Deployment and DevOps strategies\n"
            "8. Cost optimization and resource planning\n\n"
            "Provide practical, actionable advice based on industry best practices. "
            "Consider trade-offs between different approaches. "
            "Include diagrams or architecture descriptions when helpful. "
            "Tailor recommendations to the specific context and requirements.",
        )

    def get_system_prompt(self) -> str:
        """
        Get the system prompt for the architecture advisor.

        Returns:
            System prompt string
        """
        return self.system_prompt

    def process(
        self, input_data: Any, context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Provide architectural advice for the provided code or project description.

        Args:
            input_data: Code or project description (string)
            context: Optional context (e.g., project scale, team size, constraints)

        Returns:
            Dictionary with architectural advice
        """
        if not isinstance(input_data, str):
            raise ValueError("Architecture Advisor expects string input")

        # Determine if input is code or project description
        input_type = self._determine_input_type(input_data)

        # Extract project requirements from context
        requirements = self._extract_requirements(context)

        # Determine project scale
        project_scale = self._determine_project_scale(input_data, context)

        # Prepare the prompt
        prompt = ChatPromptTemplate.from_messages(
            [
                SystemMessage(content=self.system_prompt),
                HumanMessage(
                    content=f"Please provide architectural advice for the following {'code' if input_type == 'code' else 'project description'}:\n\n"
                    f"Input:\n{input_data}\n\n"
                    f"Project Scale: {project_scale}\n"
                    f"Requirements: {requirements}\n"
                    f"Additional Context: {context or 'No additional context provided'}\n\n"
                    f"Please provide advice covering:\n"
                    f"1. Recommended architecture pattern\n"
                    f"2. Technology stack suggestions\n"
                    f"3. Scalability considerations\n"
                    f"4. Security recommendations\n"
                    f"5. Deployment strategy\n"
                    f"6. Cost optimization tips\n"
                    f"7. Potential risks and mitigation strategies"
                ),
            ]
        )

        # Generate architectural advice
        messages = prompt.format_messages()
        response = self.llm.invoke(messages)

        advice = response.content

        # Analyze the architecture
        architecture_analysis = self._analyze_architecture(
            advice, input_data, project_scale
        )

        return {
            "agent": self.name,
            "input_type": input_type,
            "project_scale": project_scale,
            "requirements": requirements,
            "architectural_advice": advice,
            "analysis": architecture_analysis,
            "recommended_patterns": self._extract_patterns(advice),
            "technology_suggestions": self._extract_technologies(advice),
            "risk_assessment": self._assess_risks(advice),
        }

    def _determine_input_type(self, input_data: str) -> str:
        """
        Determine if input is code or project description.

        Args:
            input_data: Input string

        Returns:
            "code" or "description"
        """
        # Simple heuristic: if it looks like code (has programming language syntax)
        code_keywords = [
            "def ",
            "class ",
            "function ",
            "import ",
            "export ",
            "public ",
            "private ",
        ]

        if any(keyword in input_data for keyword in code_keywords):
            return "code"
        else:
            return "description"

    def _extract_requirements(self, context: Optional[Dict[str, Any]] = None) -> str:
        """
        Extract project requirements from context.

        Args:
            context: Optional context information

        Returns:
            Requirements string
        """
        if not context:
            return "General software project"

        requirements_parts = []

        if "requirements" in context:
            requirements_parts.append(
                f"Specific requirements: {context['requirements']}"
            )

        if "constraints" in context:
            requirements_parts.append(f"Constraints: {context['constraints']}")

        if "team_size" in context:
            requirements_parts.append(f"Team size: {context['team_size']}")

        if "timeline" in context:
            requirements_parts.append(f"Timeline: {context['timeline']}")

        if "budget" in context:
            requirements_parts.append(f"Budget: {context['budget']}")

        return (
            "; ".join(requirements_parts)
            if requirements_parts
            else "General software project"
        )

    def _determine_project_scale(
        self, input_data: str, context: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Determine the scale of the project.

        Args:
            input_data: Input string
            context: Optional context information

        Returns:
            Project scale (small, medium, large, enterprise)
        """
        if context and "project_scale" in context:
            return context["project_scale"]

        # Heuristic based on input length and complexity
        lines = input_data.split("\n")
        line_count = len(lines)

        # Check for enterprise keywords
        enterprise_keywords = [
            "enterprise",
            "distributed",
            "microservices",
            "kubernetes",
            "scalability",
            "high availability",
            "multi-tenant",
            "global",
        ]

        has_enterprise_keywords = any(
            keyword in input_data.lower() for keyword in enterprise_keywords
        )

        if has_enterprise_keywords:
            return "enterprise"
        elif line_count > 200:
            return "large"
        elif line_count > 50:
            return "medium"
        else:
            return "small"

    def _analyze_architecture(
        self, advice: str, input_data: str, project_scale: str
    ) -> Dict[str, Any]:
        """
        Analyze the architectural advice.

        Args:
            advice: Generated architectural advice
            input_data: Original input
            project_scale: Project scale

        Returns:
            Analysis dictionary
        """
        analysis = {
            "complexity_level": "medium",  # low, medium, high
            "scalability_score": 0.0,  # 0-1 scale
            "maintainability_score": 0.0,  # 0-1 scale
            "cost_efficiency": "medium",  # low, medium, high
            "technology_maturity": "established",  # emerging, established, legacy
            "recommended_approach": "balanced",  # conservative, balanced, innovative
        }

        advice_lower = advice.lower()

        # Analyze complexity
        complexity_keywords = {
            "simple": ["simple", "straightforward", "basic"],
            "complex": ["complex", "sophisticated", "advanced", "distributed"],
        }

        simple_count = sum(
            1 for word in complexity_keywords["simple"] if word in advice_lower
        )
        complex_count = sum(
            1 for word in complexity_keywords["complex"] if word in advice_lower
        )

        if complex_count > simple_count * 2:
            analysis["complexity_level"] = "high"
        elif simple_count > complex_count * 2:
            analysis["complexity_level"] = "low"
        else:
            analysis["complexity_level"] = "medium"

        # Analyze scalability
        scalability_keywords = [
            "scale",
            "scalability",
            "performance",
            "throughput",
            "concurrent",
            "load",
        ]
        scalability_mentions = sum(
            1 for word in scalability_keywords if word in advice_lower
        )

        # Normalize to 0-1 scale
        analysis["scalability_score"] = min(scalability_mentions / 5, 1.0)

        # Analyze maintainability
        maintainability_keywords = [
            "maintain",
            "maintainability",
            "modular",
            "clean",
            "document",
            "test",
        ]
        maintainability_mentions = sum(
            1 for word in maintainability_keywords if word in advice_lower
        )
        analysis["maintainability_score"] = min(maintainability_mentions / 5, 1.0)

        # Analyze cost efficiency
        cost_keywords = {
            "low": ["cost-effective", "budget", "affordable", "cheap"],
            "high": ["expensive", "premium", "enterprise", "commercial"],
        }

        low_cost_count = sum(1 for word in cost_keywords["low"] if word in advice_lower)
        high_cost_count = sum(
            1 for word in cost_keywords["high"] if word in advice_lower
        )

        if high_cost_count > low_cost_count:
            analysis["cost_efficiency"] = "low"
        elif low_cost_count > high_cost_count:
            analysis["cost_efficiency"] = "high"
        else:
            analysis["cost_efficiency"] = "medium"

        # Analyze technology maturity
        tech_maturity_keywords = {
            "emerging": ["new", "emerging", "cutting-edge", "experimental"],
            "established": ["established", "proven", "stable", "mature"],
            "legacy": ["legacy", "deprecated", "old", "traditional"],
        }

        maturity_scores = {}
        for maturity, keywords in tech_maturity_keywords.items():
            maturity_scores[maturity] = sum(
                1 for word in keywords if word in advice_lower
            )

        analysis["technology_maturity"] = max(maturity_scores, key=maturity_scores.get)

        # Determine recommended approach
        approach_keywords = {
            "conservative": ["conservative", "safe", "proven", "traditional"],
            "innovative": ["innovative", "modern", "cutting-edge", "experimental"],
        }

        conservative_count = sum(
            1 for word in approach_keywords["conservative"] if word in advice_lower
        )
        innovative_count = sum(
            1 for word in approach_keywords["innovative"] if word in advice_lower
        )

        if innovative_count > conservative_count:
            analysis["recommended_approach"] = "innovative"
        elif conservative_count > innovative_count:
            analysis["recommended_approach"] = "conservative"
        else:
            analysis["recommended_approach"] = "balanced"

        return analysis

    def _extract_patterns(self, advice: str) -> list:
        """
        Extract architectural patterns from the advice.

        Args:
            advice: Architectural advice

        Returns:
            List of architectural patterns
        """
        patterns = []
        known_patterns = [
            "microservices",
            "monolith",
            "serverless",
            "event-driven",
            "layered",
            "hexagonal",
            "clean architecture",
            "CQRS",
            "event sourcing",
            "service-oriented",
            "client-server",
            "peer-to-peer",
            "publish-subscribe",
            "model-view-controller",
            "repository",
            "factory",
            "strategy",
            "observer",
        ]

        advice_lower = advice.lower()
        for pattern in known_patterns:
            if pattern in advice_lower:
                patterns.append(pattern)

        return patterns

    def _extract_technologies(self, advice: str) -> Dict[str, list]:
        """
        Extract technology suggestions from the advice.

        Args:
            advice: Architectural advice

        Returns:
            Dictionary of technology categories
        """
        technologies = {
            "programming_languages": [],
            "frameworks": [],
            "databases": [],
            "cloud_services": [],
            "tools": [],
        }

        # Common technology keywords (this could be expanded)
        tech_categories = {
            "programming_languages": [
                "python",
                "javascript",
                "typescript",
                "java",
                "go",
                "rust",
                "c#",
                "php",
            ],
            "frameworks": [
                "django",
                "flask",
                "react",
                "angular",
                "vue",
                "spring",
                "express",
                "fastapi",
            ],
            "databases": [
                "postgresql",
                "mysql",
                "mongodb",
                "redis",
                "cassandra",
                "elasticsearch",
                "dynamodb",
            ],
            "cloud_services": [
                "aws",
                "azure",
                "gcp",
                "lambda",
                "ec2",
                "s3",
                "kubernetes",
                "docker",
            ],
            "tools": [
                "git",
                "jenkins",
                "github actions",
                "terraform",
                "ansible",
                "prometheus",
                "grafana",
            ],
        }

        advice_lower = advice.lower()

        for category, tech_list in tech_categories.items():
            for tech in tech_list:
                if tech in advice_lower:
                    technologies[category].append(tech)

        return technologies

    def _assess_risks(self, advice: str) -> Dict[str, str]:
        """
        Assess risks mentioned in the architectural advice.

        Args:
            advice: Architectural advice

        Returns:
            Dictionary of risk assessments
        """
        risks = {
            "technical_debt": "low",
            "scalability_risk": "low",
            "security_risk": "low",
            "vendor_lockin": "low",
            "team_skill_gap": "low",
        }

        advice_lower = advice.lower()

        # Risk indicators
        risk_indicators = {
            "technical_debt": ["technical debt", "legacy", "workaround", "temporary"],
            "scalability_risk": [
                "bottleneck",
                "single point",
                "scale limit",
                "performance issue",
            ],
            "security_risk": ["security risk", "vulnerability", "exposed", "insecure"],
            "vendor_lockin": [
                "vendor lock",
                "proprietary",
                "platform specific",
                "cloud specific",
            ],
            "team_skill_gap": [
                "learning curve",
                "new technology",
                "expertise required",
                "training needed",
            ],
        }

        for risk, indicators in risk_indicators.items():
            indicator_count = sum(
                1 for indicator in indicators if indicator in advice_lower
            )

            if indicator_count >= 3:
                risks[risk] = "high"
            elif indicator_count >= 1:
                risks[risk] = "medium"
            else:
                risks[risk] = "low"

        return risks

    def format_output(self, result: Dict[str, Any]) -> str:
        """
        Format the architectural advice output for display.

        Args:
            result: The architectural advice results

        Returns:
            Formatted string
        """
        output = super().format_output(result["architectural_advice"])

        # Add metadata
        output += f"\n📊 Project Analysis:\n"
        output += f"  Input Type: {result['input_type']}\n"
        output += f"  Project Scale: {result['project_scale'].upper()}\n"
        output += f"  Requirements: {result['requirements']}\n"

        # Add architecture analysis
        analysis = result["analysis"]
        output += f"\n🏗️  Architecture Analysis:\n"
        output += f"  Complexity Level: {analysis['complexity_level'].upper()}\n"
        output += f"  Scalability Score: {analysis['scalability_score']:.1%}\n"
        output += f"  Maintainability Score: {analysis['maintainability_score']:.1%}\n"
        output += f"  Cost Efficiency: {analysis['cost_efficiency'].upper()}\n"
        output += f"  Technology Maturity: {analysis['technology_maturity'].upper()}\n"
        output += (
            f"  Recommended Approach: {analysis['recommended_approach'].upper()}\n"
        )

        # Add recommended patterns
        if result["recommended_patterns"]:
            output += f"\n🎯 Recommended Architectural Patterns:\n"
            for pattern in result["recommended_patterns"]:
                output += f"  • {pattern.title()}\n"

        # Add technology suggestions
        tech_suggestions = result["technology_suggestions"]
        if any(tech_suggestions.values()):
            output += f"\n🛠️  Technology Suggestions:\n"

            for category, techs in tech_suggestions.items():
                if techs:
                    category_name = category.replace("_", " ").title()
                    output += f"  {category_name}:\n"
                    for tech in techs:
                        output += f"    • {tech.title()}\n"

        # Add risk assessment
        risks = result["risk_assessment"]
        output += f"\n⚠️  Risk Assessment:\n"
        for risk, level in risks.items():
            risk_name = risk.replace("_", " ").title()
            level_icon = (
                "🔴" if level == "high" else "🟡" if level == "medium" else "🟢"
            )
            output += f"  {level_icon} {risk_name}: {level.upper()}\n"

        # Add summary
        output += f"\n💡 Key Recommendations:\n"
        # Extract first 3-5 key points from advice
        lines = result["architectural_advice"].split("\n")
        key_points = [
            line.strip() for line in lines if line.strip() and len(line.strip()) > 20
        ]
        for i, point in enumerate(key_points[:5], 1):
            output += f"  {i}. {point}\n"
