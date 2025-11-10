"""Pydantic schemas for request/response validation."""

from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field, EmailStr


class UserCreate(BaseModel):
    """Schema for creating a new user."""
    
    name: str = Field(..., min_length=1, max_length=200, description="Full name")
    username: str = Field(..., min_length=3, max_length=100, description="Username")
    email: EmailStr = Field(..., description="Email address")
    password: str = Field(..., min_length=6, max_length=256, description="Password")


class UserUpdate(BaseModel):
    """Schema for updating user information."""
    
    name: str | None = Field(None, min_length=1, max_length=200)
    email: EmailStr | None = None


class UserResponse(BaseModel):
    """Schema for user response."""
    
    id: int
    name: str
    username: str
    email: str
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


class HealthResponse(BaseModel):
    """Schema for health check response."""
    
    status: str = Field(default="ok", description="Service status")
    service: str = Field(..., description="Service name")
    version: str = Field(..., description="Service version")
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class MessageResponse(BaseModel):
    """Generic message response schema."""
    
    message: str = Field(..., description="Response message")

