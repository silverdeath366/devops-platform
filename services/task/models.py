from sqlalchemy import Table, Column, Integer, String, Boolean, ForeignKey, MetaData

metadata = MetaData()

tasks = Table(
    "tasks",
    metadata,
    Column("id", Integer, primary_key=True),
    Column("title", String, nullable=False),
    Column("description", String),
    Column("completed", Boolean, default=False),
    Column("user_id", Integer, nullable=False)  # FK simulation
)
