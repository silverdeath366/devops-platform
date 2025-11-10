"""Pydantic schemas for request/response validation."""

from datetime import datetime
from pydantic import BaseModel, Field
from typing import Literal


class NotificationCreate(BaseModel):
    """Schema for creating a notification."""
    
    user_id: int = Field(..., gt=0, description="User ID to notify")
    message: str = Field(..., min_length=1, max_length=1000, description="Notification message")
    notification_type: Literal["email", "sms", "push", "in-app"] = Field(
        default="in-app", description="Type of notification"
    )


class NotificationResponse(BaseModel):
    """Schema for notification response."""
    
    status: str = Field(..., description="Notification status")
    user_id: int = Field(..., description="User ID")
    message: str = Field(..., description="Notification message")
    notification_type: str = Field(..., description="Type of notification")
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class HealthResponse(BaseModel):
    """Schema for health check response."""
    
    status: str = Field(default="ok", description="Service status")
    service: str = Field(..., description="Service name")
    version: str = Field(..., description="Service version")
    timestamp: datetime = Field(default_factory=datetime.utcnow)

