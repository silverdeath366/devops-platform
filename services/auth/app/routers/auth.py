"""Authentication endpoints."""

from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models import User
from app.schemas import UserRegister, UserLogin, Token, MessageResponse
from app.config import get_settings
import jwt

router = APIRouter(prefix="/auth", tags=["Authentication"])
settings = get_settings()


def create_access_token(data: dict) -> str:
    """Create JWT access token."""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.jwt_expiration_minutes)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode, settings.jwt_secret, algorithm=settings.jwt_algorithm
    )
    return encoded_jwt


def hash_password(password: str) -> str:
    """Hash password (simple version - use bcrypt in production)."""
    # TODO: Replace with proper bcrypt hashing
    return f"hashed_{password}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash."""
    # TODO: Replace with proper bcrypt verification
    return hashed_password == f"hashed_{plain_password}"


@router.post(
    "/register",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register new user",
)
async def register(
    user_data: UserRegister,
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    """Register a new user account."""
    # Check if user already exists
    result = await db.execute(select(User).where(User.username == user_data.username))
    existing_user = result.scalar_one_or_none()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already exists",
        )
    
    # Create new user
    hashed_password = hash_password(user_data.password)
    new_user = User(username=user_data.username, password=hashed_password)
    db.add(new_user)
    await db.commit()
    
    return MessageResponse(message="User registered successfully")


@router.post(
    "/login",
    response_model=Token,
    summary="Login user",
)
async def login(
    credentials: UserLogin,
    db: AsyncSession = Depends(get_db),
) -> Token:
    """Authenticate user and return access token."""
    # Find user
    result = await db.execute(select(User).where(User.username == credentials.username))
    user = result.scalar_one_or_none()
    
    if not user or not verify_password(credentials.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token = create_access_token(data={"sub": user.username, "user_id": user.id})
    
    return Token(access_token=access_token, token_type="bearer")

