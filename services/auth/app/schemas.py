"""Pydantic schemas for request/response validation."""

from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class UserRegister(BaseModel):
    """Schema for user registration."""
    
    username: str = Field(..., min_length=3, max_length=100, description="Username")
    password: str = Field(..., min_length=6, max_length=256, description="Password")


class UserLogin(BaseModel):
    """Schema for user login."""
    
    username: str = Field(..., description="Username")
    password: str = Field(..., description="Password")


class Token(BaseModel):
    """Schema for authentication token response."""
    
    access_token: str = Field(..., description="JWT access token")
    token_type: str = Field(default="bearer", description="Token type")


class UserResponse(BaseModel):
    """Schema for user response."""
    
    id: int
    username: str
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

