from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    func,
    MetaData,
    Table
)

metadata = MetaData()

users = Table(
    "users",
    metadata,
    Column("id", Integer, primary_key=True),
    Column("username", String(100), unique=True, nullable=False, index=True),
    Column("password", String(256), nullable=False),  # intended for hashed password
    Column("created_at", DateTime, server_default=func.now(), nullable=False),
    Column("updated_at", DateTime, onupdate=func.now(), server_default=func.now(), nullable=False),
)
