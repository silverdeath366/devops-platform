# Contributing to DevOps Microservices Platform

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## 🤝 Code of Conduct

By participating in this project, you agree to maintain a respectful and collaborative environment.

## 🚀 Getting Started

1. **Fork the repository**
2. **Clone your fork:**
   ```bash
   git clone https://github.com/yourusername/devops-platform.git
   cd devops-platform
   ```
3. **Set up development environment:**
   ```bash
   make setup
   ```

## 🔧 Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bugfix-name
```

### 2. Make Your Changes

- Follow the existing code style
- Add tests for new features
- Update documentation as needed
- Keep commits atomic and well-described

### 3. Test Your Changes

```bash
# Format code
make format

# Run linters
make lint

# Run tests
make test

# Test specific service
make test-service SERVICE=auth
```

### 4. Commit Your Changes

Follow [Conventional Commits](https://www.conventionalcommits.org/) format:

```bash
git commit -m "feat(auth): add password reset functionality"
git commit -m "fix(user): resolve email validation bug"
git commit -m "docs: update deployment instructions"
```

**Commit Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes
- `perf`: Performance improvements
- `ci`: CI/CD changes

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## 📋 Pull Request Guidelines

### PR Title

Use conventional commit format:
```
feat(auth): add OAuth2 support
fix(user): resolve duplicate email handling
```

### PR Description

Include:
- **What** changed
- **Why** it changed
- **How** to test it
- **Related issues** (if any)

Example:
```markdown
## Description
Adds OAuth2 authentication support for Google and GitHub providers.

## Changes
- Added OAuth2 configuration
- Implemented provider callbacks
- Added integration tests

## Testing
1. Set up OAuth credentials
2. Run `make test-service SERVICE=auth`
3. Test login flow manually

## Related Issues
Closes #123
```

## 🧪 Testing Requirements

- All new features must include tests
- Tests must pass locally before submitting PR
- Aim for >80% code coverage
- Include both unit and integration tests where applicable

## 📝 Code Style

### Python

- Follow PEP 8 guidelines
- Use type hints
- Maximum line length: 100 characters
- Use Black for formatting
- Use Ruff for linting

```python
# Good
async def get_user(user_id: int, db: AsyncSession) -> User:
    """Get user by ID."""
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()

# Bad
def get_user(user_id,db):
    result=db.execute(select(User).where(User.id==user_id))
    return result.scalar_one_or_none()
```

### Documentation

- Use docstrings for all functions/classes
- Update README.md when adding features
- Include inline comments for complex logic

## 🏗️ Architecture Guidelines

### Microservice Structure

Each service should follow this structure:
```
services/service-name/
├── app/
│   ├── __init__.py
│   ├── main.py          # FastAPI app
│   ├── config.py        # Configuration
│   ├── database.py      # Database setup
│   ├── models.py        # SQLAlchemy models
│   ├── schemas.py       # Pydantic schemas
│   └── routers/         # API endpoints
├── tests/
├── Dockerfile
└── requirements.txt
```

### API Design

- Use RESTful conventions
- Return appropriate HTTP status codes
- Include pagination for list endpoints
- Provide comprehensive error messages
- Version your APIs (`/api/v1/...`)

### Database

- Use async SQLAlchemy sessions
- Always use database transactions
- Add indexes for frequently queried fields
- Include database migrations (Alembic)

## 🔍 Review Process

1. **Automated Checks:** CI/CD pipeline must pass
2. **Code Review:** At least one maintainer approval required
3. **Testing:** All tests must pass
4. **Documentation:** Must be updated if needed

## 🐛 Bug Reports

When filing a bug report, include:

1. **Description:** Clear description of the bug
2. **Steps to Reproduce:**
   ```
   1. Start service with `make docker-up`
   2. Call endpoint: `curl http://localhost:8001/endpoint`
   3. Observe error
   ```
3. **Expected Behavior:** What should happen
4. **Actual Behavior:** What actually happens
5. **Environment:**
   - OS: Ubuntu 22.04
   - Python: 3.12
   - Docker: 24.0.0
6. **Logs/Screenshots:** If applicable

## 💡 Feature Requests

When requesting a feature:

1. **Use Case:** Explain why this feature is needed
2. **Proposed Solution:** How you envision it working
3. **Alternatives:** Other solutions you've considered
4. **Additional Context:** Any other relevant information

## 📞 Questions?

- Open an issue with the `question` label
- Join our discussions
- Contact maintainers

## 🎉 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in relevant documentation

Thank you for contributing! 🚀

