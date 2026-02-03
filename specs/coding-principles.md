# Python Coding Principles

## 1. Code Style and Formatting

### General Style
- Follow PEP 8 for Python code style conventions
- Maximum line length: 100 characters (as configured in project)
- Use 4 spaces for indentation (never tabs)
- Use descriptive variable and function names in snake_case
- Use PascalCase for class names
- Use UPPER_CASE for constants

### Formatting Tools
- Use `black` for automatic code formatting
- Use `ruff` for linting and style enforcement
- Run formatters before committing code

### Import Organization
```python
# Standard library imports
import os
import sys

# Third-party imports
from fastapi import FastAPI
from pydantic import BaseModel

# Local application imports
from kb_rag.models import Document
from kb_rag.storage import VectorStore
```

## 2. Type Hints and Type Safety

### Mandatory Type Hints
- All function signatures must include type hints for parameters and return values
- Use type hints for class attributes
- Use `typing` module for complex types

```python
from typing import Optional, List, Dict, Any

def retrieve_documents(
    query: str,
    limit: int = 10,
    filters: Optional[Dict[str, Any]] = None
) -> List[Document]:
    """Retrieve documents matching the query."""
    pass
```

### Type Checking
- Run `ty check` before committing
- Aim for zero type errors in production code
- Use `# type: ignore` sparingly and only with explanatory comments

## 3. Documentation Standards

### Docstrings
- Use docstrings for all public modules, classes, and functions
- Follow Google-style docstring format
- Include purpose, parameters, return values, and exceptions

```python
def calculate_confidence(
    predicted: float,
    actual: float,
    historical_accuracy: float
) -> float:
    """Calculate calibrated confidence score.

    Args:
        predicted: Predicted confidence value (0.0-1.0)
        actual: Actual outcome value (0.0-1.0)
        historical_accuracy: Historical accuracy rate (0.0-1.0)

    Returns:
        Calibrated confidence score between 0.0 and 1.0

    Raises:
        ValueError: If inputs are outside valid ranges
    """
    if not (0.0 <= predicted <= 1.0):
        raise ValueError("Predicted must be between 0.0 and 1.0")
    return predicted * historical_accuracy
```

### Comments
- Write self-documenting code; minimize inline comments
- Use comments only to explain "why", not "what"
- Keep comments up-to-date with code changes
- Document complex algorithms or non-obvious logic

## 4. Error Handling

### Exception Handling
- Use specific exception types, not bare `except:`
- Handle exceptions at the appropriate level
- Always provide context in error messages
- Log exceptions with appropriate severity

```python
from fastapi import HTTPException
import logging

logger = logging.getLogger(__name__)

async def get_document(doc_id: str) -> Document:
    try:
        doc = await storage.fetch(doc_id)
    except DocumentNotFoundError as e:
        logger.warning(f"Document {doc_id} not found: {e}")
        raise HTTPException(status_code=404, detail=f"Document {doc_id} not found")
    except StorageConnectionError as e:
        logger.error(f"Storage connection failed: {e}")
        raise HTTPException(status_code=503, detail="Storage service unavailable")

    return doc
```

### Validation
- Validate inputs at API boundaries using Pydantic models
- Fail fast with clear error messages
- Never trust external data

## 5. Testing Standards

### Test Coverage
- Write tests for all business logic
- Aim for >80% code coverage
- Test both happy paths and edge cases
- Write tests before or alongside implementation (TDD preferred)

### Test Organization
```python
import pytest
from httpx import AsyncClient

class TestDocumentRetrieval:
    """Tests for document retrieval functionality."""

    async def test_retrieve_existing_document(self, client: AsyncClient):
        """Should return document when ID exists."""
        response = await client.get("/documents/doc-123")
        assert response.status_code == 200
        assert response.json()["id"] == "doc-123"

    async def test_retrieve_nonexistent_document(self, client: AsyncClient):
        """Should return 404 when document doesn't exist."""
        response = await client.get("/documents/nonexistent")
        assert response.status_code == 404
```

### Test Naming
- Use descriptive test names that explain the scenario
- Format: `test_<action>_<condition>_<expected_result>`
- Use docstrings to provide additional context

## 6. Security Best Practices

### Sensitive Data
- Never hardcode credentials, API keys, or secrets
- Use environment variables or secure vaults
- Redact sensitive data in logs
- Never commit `.env` files

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    api_key: str

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
```

### Input Validation
- Validate and sanitize all user inputs
- Use Pydantic models for request validation
- Implement rate limiting for APIs
- Use parameterized queries to prevent SQL injection

### Dependencies
- Keep dependencies up-to-date
- Review security advisories regularly
- Use tools like `pip-audit` for vulnerability scanning

## 7. Code Organization and Structure

### Module Structure
```
service_name/
├── src/
│   └── service_name/
│       ├── __init__.py
│       ├── main.py          # FastAPI app and routes
│       ├── config.py        # Configuration and settings
│       ├── models.py        # Pydantic models
│       ├── storage.py       # Data access layer
│       └── security.py      # Security utilities
└── tests/
    ├── __init__.py
    ├── conftest.py          # Pytest fixtures
    └── test_*.py            # Test modules
```

### Separation of Concerns
- Keep business logic separate from API routes
- Use dependency injection for testability
- Separate data models from business logic
- One class/function should have one responsibility

### Dependency Management
- Use `pyproject.toml` for dependency declaration
- Pin exact versions for production dependencies
- Keep dev dependencies separate
- Document why specific versions are required

## 8. Asynchronous Programming

### Async/Await
- Use `async`/`await` for I/O-bound operations
- Don't block the event loop with CPU-intensive work
- Use proper async libraries (httpx, asyncpg, etc.)

```python
from httpx import AsyncClient

async def fetch_external_data(url: str) -> dict:
    """Fetch data from external API asynchronously."""
    async with AsyncClient() as client:
        response = await client.get(url)
        response.raise_for_status()
        return response.json()
```

### Context Managers
- Always use context managers for resource management
- Clean up resources properly in async code

## 9. Performance Considerations

### Database Queries
- Use connection pooling
- Avoid N+1 query problems
- Index frequently queried fields
- Use batch operations when possible

### Caching
- Cache expensive computations
- Set appropriate cache TTLs
- Invalidate caches when data changes

### Resource Management
- Close connections and file handles explicitly
- Use connection pools for databases
- Monitor memory usage in long-running processes

## 10. Logging and Observability

### Structured Logging
```python
import logging

logger = logging.getLogger(__name__)

def process_request(request_id: str, user_id: str):
    logger.info(
        "Processing request",
        extra={
            "request_id": request_id,
            "user_id": user_id,
            "action": "process_request"
        }
    )
```

### Log Levels
- **DEBUG**: Detailed diagnostic information
- **INFO**: General informational messages
- **WARNING**: Something unexpected but handled
- **ERROR**: Error that needs attention
- **CRITICAL**: Severe error that may cause failure

### What to Log
- API requests and responses (excluding sensitive data)
- Error conditions and exceptions
- Performance metrics (latency, throughput)
- Business events (document indexed, analysis completed)

## 11. Code Review and Quality Gates

### Pre-commit Checks
- Run type checker (`ty check`)
- Run linter (`ruff check`)
- Run formatter (`black`)
- Run tests (`pytest`)
- Ensure no secrets in code

### Code Review Guidelines
- Keep changes focused and atomic
- Write clear commit messages
- Update documentation with code changes
- Ensure tests cover new functionality
- Verify no breaking changes in APIs

### Continuous Integration
- All checks must pass before merge
- Maintain test coverage thresholds
- Run security scans automatically
- Block commits with type errors or linting issues

## 12. Minimality and Simplicity

### YAGNI (You Aren't Gonna Need It)
- Don't add functionality until it's needed
- Avoid speculative generalization
- Write code for current requirements, not imagined future ones

### Code That Justifies Itself
- Every line of code must serve a requirement or test
- Remove unused imports, functions, and classes
- Prefer simple solutions over clever ones
- Refactor when complexity grows

### Dependencies
- Add dependencies only when necessary
- Evaluate alternatives before adding new packages
- Prefer standard library when sufficient
- Document why each dependency is needed

## 13. Version Control Practices

### Commit Messages
```
<type>: <short summary>

<optional detailed description>

<optional footer with references>
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

### Git Workflow
- Keep commits atomic and focused
- Squash fixup commits before merge
- Never commit broken code
- Review diffs before committing

## 14. API Design Principles

### RESTful Conventions
- Use appropriate HTTP methods (GET, POST, PUT, DELETE)
- Return proper status codes (200, 201, 400, 404, 500)
- Version APIs (`/api/v1/...`)
- Use plural nouns for resources (`/documents`, `/analyses`)

### Response Consistency
```python
from pydantic import BaseModel
from typing import Generic, TypeVar, Optional

T = TypeVar('T')

class APIResponse(BaseModel, Generic[T]):
    """Standard API response wrapper."""
    success: bool
    data: Optional[T] = None
    error: Optional[str] = None
    message: Optional[str] = None
```

### Backward Compatibility
- Don't break existing APIs without versioning
- Deprecate features before removing them
- Provide migration paths for breaking changes

## 15. Environment and Configuration

### Environment Variables
- Use `.env.example` to document required variables
- Never commit `.env` files
- Validate configuration at startup
- Provide sensible defaults where appropriate

### Configuration Management
```python
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    app_name: str = "AIM Service"
    debug: bool = False
    database_url: str
    vector_store_url: str
    log_level: str = "INFO"

    class Config:
        env_file = ".env"

@lru_cache()
def get_settings() -> Settings:
    return Settings()
```

## Summary

These principles ensure that AIM platform code remains:
- **Readable**: Clear, well-documented, and consistent
- **Reliable**: Well-tested, type-safe, and error-resistant
- **Maintainable**: Simple, modular, and evolvable
- **Secure**: Safe from common vulnerabilities
- **Performant**: Efficient and scalable

All code must pass type checking (`ty check`), linting (`ruff check`), and tests (`pytest`) before being committed. When in doubt, favor simplicity, clarity, and evidence-based decisions over cleverness or speculation.
