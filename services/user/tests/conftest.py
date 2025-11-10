"""Pytest configuration for user service tests."""

import pytest


@pytest.fixture(scope="session")
def anyio_backend():
    """Configure async backend for tests."""
    return "asyncio"

