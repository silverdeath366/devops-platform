"""Pydantic schemas for request/response validation."""

from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class TaskCreate(BaseModel):
    """Schema for creating a new task."""
    
    title: str = Field(..., min_length=1, max_length=200, description="Task title")
    description: str = Field(default="", max_length=5000, description="Task description")
    user_id: int = Field(..., gt=0, description="User ID who owns the task")


class TaskUpdate(BaseModel):
    """Schema for updating a task."""
    
    title: str | None = Field(None, min_length=1, max_length=200)
    description: str | None = Field(None, max_length=5000)
    completed: bool | None = None


class TaskResponse(BaseModel):
    """Schema for task response."""
    
    id: int
    title: str
    description: str
    user_id: int
    completed: bool
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

