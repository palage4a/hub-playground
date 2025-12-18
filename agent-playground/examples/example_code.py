"""
Example Python code for testing the multi-agent developer system.
This file contains various functions and classes that can be analyzed
by the different agents in the system.
"""

import json
import math
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Optional, Union


def calculate_statistics(numbers: List[float]) -> Dict[str, float]:
    """
    Calculate basic statistics for a list of numbers.

    Args:
        numbers: List of numbers to analyze

    Returns:
        Dictionary containing mean, median, mode, and standard deviation

    Raises:
        ValueError: If the input list is empty
    """
    if not numbers:
        raise ValueError("Cannot calculate statistics for empty list")

    # Calculate mean
    mean = sum(numbers) / len(numbers)

    # Calculate median
    sorted_numbers = sorted(numbers)
    n = len(sorted_numbers)
    if n % 2 == 0:
        median = (sorted_numbers[n // 2 - 1] + sorted_numbers[n // 2]) / 2
    else:
        median = sorted_numbers[n // 2]

    # Calculate mode
    frequency: Dict[float, int] = {}
    for num in numbers:
        frequency[num] = frequency.get(num, 0) + 1

    max_freq = max(frequency.values())
    mode = [num for num, freq in frequency.items() if freq == max_freq]

    # Calculate standard deviation
    variance = sum((x - mean) ** 2 for x in numbers) / len(numbers)
    std_dev = math.sqrt(variance)

    return {
        "mean": mean,
        "median": median,
        "mode": mode[0] if len(mode) == 1 else mode,
        "std_dev": std_dev,
        "count": len(numbers),
        "min": min(numbers),
        "max": max(numbers),
    }


def fibonacci_sequence(n: int) -> List[int]:
    """
    Generate Fibonacci sequence up to n terms.

    Args:
        n: Number of terms to generate

    Returns:
        List containing Fibonacci sequence

    Raises:
        ValueError: If n is less than or equal to 0
    """
    if n <= 0:
        raise ValueError("Number of terms must be positive")

    if n == 1:
        return [0]
    elif n == 2:
        return [0, 1]

    sequence = [0, 1]
    for i in range(2, n):
        sequence.append(sequence[i - 1] + sequence[i - 2])

    return sequence


def is_palindrome(text: str) -> bool:
    """
    Check if a string is a palindrome.

    Args:
        text: String to check

    Returns:
        True if the string is a palindrome, False otherwise
    """
    # Remove non-alphanumeric characters and convert to lowercase
    cleaned = "".join(char.lower() for char in text if char.isalnum())
    return cleaned == cleaned[::-1]


@dataclass
class User:
    """Represents a user in the system."""

    id: int
    username: str
    email: str
    created_at: datetime
    is_active: bool = True

    def to_dict(self) -> Dict[str, Union[int, str, bool]]:
        """Convert user to dictionary for serialization."""
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email,
            "created_at": self.created_at.isoformat(),
            "is_active": self.is_active,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Union[int, str, bool]]) -> "User":
        """Create user from dictionary."""
        return cls(
            id=data["id"],
            username=data["username"],
            email=data["email"],
            created_at=datetime.fromisoformat(data["created_at"]),
            is_active=data.get("is_active", True),
        )


class UserManager:
    """Manages users in the system."""

    def __init__(self):
        self.users: Dict[int, User] = {}
        self.next_id = 1

    def add_user(self, username: str, email: str) -> User:
        """
        Add a new user to the system.

        Args:
            username: User's username
            email: User's email address

        Returns:
            The created User object

        Raises:
            ValueError: If username or email is invalid
        """
        if not username or not username.strip():
            raise ValueError("Username cannot be empty")

        if not email or "@" not in email:
            raise ValueError("Invalid email address")

        # Check if username already exists
        if any(user.username == username for user in self.users.values()):
            raise ValueError(f"Username '{username}' already exists")

        # Check if email already exists
        if any(user.email == email for user in self.users.values()):
            raise ValueError(f"Email '{email}' already registered")

        user = User(
            id=self.next_id, username=username, email=email, created_at=datetime.now()
        )

        self.users[user.id] = user
        self.next_id += 1

        return user

    def get_user(self, user_id: int) -> Optional[User]:
        """
        Get a user by ID.

        Args:
            user_id: ID of the user to retrieve

        Returns:
            User object if found, None otherwise
        """
        return self.users.get(user_id)

    def get_user_by_username(self, username: str) -> Optional[User]:
        """
        Get a user by username.

        Args:
            username: Username to search for

        Returns:
            User object if found, None otherwise
        """
        for user in self.users.values():
            if user.username == username:
                return user
        return None

    def delete_user(self, user_id: int) -> bool:
        """
        Delete a user by ID.

        Args:
            user_id: ID of the user to delete

        Returns:
            True if user was deleted, False if user not found
        """
        if user_id in self.users:
            del self.users[user_id]
            return True
        return False

    def activate_user(self, user_id: int) -> bool:
        """
        Activate a user.

        Args:
            user_id: ID of the user to activate

        Returns:
            True if user was activated, False if user not found
        """
        user = self.get_user(user_id)
        if user:
            user.is_active = True
            return True
        return False

    def deactivate_user(self, user_id: int) -> bool:
        """
        Deactivate a user.

        Args:
            user_id: ID of the user to deactivate

        Returns:
            True if user was deactivated, False if user not found
        """
        user = self.get_user(user_id)
        if user:
            user.is_active = False
            return True
        return False

    def get_active_users(self) -> List[User]:
        """Get all active users."""
        return [user for user in self.users.values() if user.is_active]

    def get_inactive_users(self) -> List[User]:
        """Get all inactive users."""
        return [user for user in self.users.values() if not user.is_active]

    def save_to_file(self, filename: str) -> None:
        """
        Save all users to a JSON file.

        Args:
            filename: Path to the JSON file
        """
        data = {
            "users": [user.to_dict() for user in self.users.values()],
            "next_id": self.next_id,
        }

        with open(filename, "w") as f:
            json.dump(data, f, indent=2)

    def load_from_file(self, filename: str) -> None:
        """
        Load users from a JSON file.

        Args:
            filename: Path to the JSON file

        Raises:
            FileNotFoundError: If the file doesn't exist
            ValueError: If the file contains invalid data
        """
        try:
            with open(filename, "r") as f:
                data = json.load(f)

            self.users.clear()
            for user_data in data.get("users", []):
                user = User.from_dict(user_data)
                self.users[user.id] = user

            self.next_id = data.get("next_id", 1)

        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON file: {e}")
        except KeyError as e:
            raise ValueError(f"Missing required field in user data: {e}")


def process_data(
    data: List[Dict[str, Union[int, float, str]]],
) -> Dict[str, Union[int, float]]:
    """
    Process a list of data dictionaries and calculate aggregates.

    Args:
        data: List of dictionaries containing data

    Returns:
        Dictionary with aggregated statistics

    Example:
        >>> data = [{"value": 10}, {"value": 20}, {"value": 30}]
        >>> process_data(data)
        {"count": 3, "sum": 60, "avg": 20.0}
    """
    if not data:
        return {"count": 0, "sum": 0, "avg": 0.0}

    # Extract numeric values from the data
    values = []
    for item in data:
        for key, value in item.items():
            if isinstance(value, (int, float)):
                values.append(value)

    if not values:
        return {"count": 0, "sum": 0, "avg": 0.0}

    return {
        "count": len(values),
        "sum": sum(values),
        "avg": sum(values) / len(values),
        "min": min(values),
        "max": max(values),
    }


def validate_password(password: str) -> Dict[str, Union[bool, List[str]]]:
    """
    Validate a password against security requirements.

    Args:
        password: Password to validate

    Returns:
        Dictionary with validation result and list of issues
    """
    issues = []

    # Check minimum length
    if len(password) < 8:
        issues.append("Password must be at least 8 characters long")

    # Check for uppercase letters
    if not any(char.isupper() for char in password):
        issues.append("Password must contain at least one uppercase letter")

    # Check for lowercase letters
    if not any(char.islower() for char in password):
        issues.append("Password must contain at least one lowercase letter")

    # Check for digits
    if not any(char.isdigit() for char in password):
        issues.append("Password must contain at least one digit")

    # Check for special characters
    special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    if not any(char in special_chars for char in password):
        issues.append("Password must contain at least one special character")

    # Check for common passwords (simplified)
    common_passwords = ["password", "123456", "qwerty", "admin", "letmein"]
    if password.lower() in common_passwords:
        issues.append("Password is too common")

    return {
        "is_valid": len(issues) == 0,
        "issues": issues,
        "strength": "strong" if len(issues) == 0 else "weak",
    }


if __name__ == "__main__":
    # Example usage of the functions and classes
    print("Example Code Demo")
    print("=" * 50)

    # Test statistics calculation
    numbers = [1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10]
    stats = calculate_statistics(numbers)
    print(f"Statistics for {numbers}:")
    for key, value in stats.items():
        print(f"  {key}: {value}")

    print()

    # Test Fibonacci sequence
    fib = fibonacci_sequence(10)
    print(f"First 10 Fibonacci numbers: {fib}")

    print()

    # Test palindrome checker
    test_strings = ["racecar", "hello", "A man, a plan, a canal: Panama"]
    for test in test_strings:
        result = is_palindrome(test)
        print(f"'{test}' is palindrome: {result}")

    print()

    # Test UserManager
    manager = UserManager()
    try:
        user1 = manager.add_user("john_doe", "john@example.com")
        user2 = manager.add_user("jane_doe", "jane@example.com")
        print(f"Added users: {user1.username}, {user2.username}")

        # Deactivate a user
        manager.deactivate_user(user1.id)
        active_users_count = len(manager.get_active_users())
        print(f"Active users: {active_users_count}")

    except ValueError as e:
        print(f"Error: {e}")

    print()

    # Test password validation
    passwords = ["weak", "Strong123!", "Password123", "SuperSecure!@#123"]
    for pwd in passwords:
        validation = validate_password(pwd)
        status = "✅" if validation["is_valid"] else "❌"
        print(f"{status} Password '{pwd}': {validation['strength']}")
        if validation["issues"]:
            for issue in validation["issues"]:
                print(f"  - {issue}")
