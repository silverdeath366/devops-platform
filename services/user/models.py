from sqlalchemy import Column, Integer, String, MetaData, Table

metadata = MetaData()

users = Table(
    "users",
    metadata,
    Column("id", Integer, primary_key=True),
    Column("name", String, nullable=False),
    Column("username", String, unique=True, nullable=False),
    Column("email", String, unique=True, nullable=False),
    Column("password", String, nullable=False),
)
