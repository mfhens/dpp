# Agent Rules

## Dependency Management

1.  **Always** use `pyproject.toml` for managing project dependencies.
2.  **Always** use the `.venv` virtual environment for installing packages and running the application.
3.  **Never** install packages globally using `pip install` without activating the virtual environment. Use `uv pip install` or `source .venv/bin/activate && pip install`.
4.  Add all new runtime dependencies to the `dependencies` list in `pyproject.toml`.
5.  Add all development tools (linters, formatters, type checkers, stubs) to the `dev` optional dependencies in `pyproject.toml`.

## Environment Setup

To set up the development environment, always follow these steps:

1.  Check for `uv` installation.
2.  Create a virtual environment: `uv venv .venv`.
3.  Activate the virtual environment: `source .venv/bin/activate` (or `.venv\Scripts\activate` on Windows).
4.  Install dependencies: `uv pip install -e .[dev]`.

## Type Checking

1.  Use `ty` for type checking.
2.  Install missing type stubs if `ty` reports unresolved imports (e.g., `types-requests`, `boto3-stubs`).
3.  Ensure code passes `ty check` before considering a task complete.

## Technical Documentation

All technical documentation should be maintained in the `docs/` folder.

### Documentation Principles

1.  **Update First, Create Second**: Always check if existing documentation covers the topic. Update existing documents rather than creating new ones unless the topic warrants a separate document.
2.  **Task Completion**: A development task is only complete when the relevant documentation has been updated to reflect the changes.
3.  **Keep Documentation Current**: Documentation must accurately reflect the current state of the codebase.

### Documentation Standards

1.  **Format**: Use Markdown (`.md`) for all documentation files.
2.  **Diagrams**: Use Mermaid syntax for all diagrams.
3.  **Architecture Diagrams**: Follow the C4 model methodology (Context, Container, Component, Code).
    -   Use Mermaid flowchart diagrams styled to fit C4 conventions due to Mermaid's layout limitations with C4 diagrams.
    -   Use appropriate styling and grouping to represent C4 levels clearly.
4.  **Structure**: Organize documentation logically with clear headings and a table of contents for longer documents.
5.  **Links**: Use relative links to reference other documentation files or code files in the repository.

### Documentation Workflow

When implementing features or making changes:

1.  **Before coding**: Check existing documentation to understand current architecture and design decisions.
2.  **During implementation**: Note what documentation will need updates.
3.  **After coding**: Update relevant documentation files to reflect changes, including:
    -   Architecture diagrams if components or interactions changed
    -   API documentation if endpoints or interfaces changed
    -   Configuration documentation if settings or environment variables changed
    -   Deployment documentation if infrastructure or deployment processes changed
4.  **Verify**: Ensure all diagrams render correctly and links work.
