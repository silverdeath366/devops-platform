import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from databases import Database
from .models import users, metadata
from contextlib import asynccontextmanager
import sqlalchemy

TESTING = os.getenv("TESTING") == "1"
DATABASE_URL = "sqlite:///./test_user.db" if TESTING else "sqlite:///./user.db"

database = Database(DATABASE_URL)
engine = sqlalchemy.create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False}
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    metadata.create_all(engine)
    await database.connect()
    yield
    await database.disconnect()

app = FastAPI(lifespan=lifespan)

class UserIn(BaseModel):
    name: str
    username: str
    email: str
    password: str

@app.get("/health")
@app.get("/healthz")
async def health():
    return {"status": "ok"}

@app.get("/users")
async def get_users():
    query = users.select()
    return await database.fetch_all(query)

@app.post("/users")
async def create_user(user: UserIn):
    query = users.insert().values(
        name=user.name,
        username=user.username,
        email=user.email,
        password=user.password,
    )
    try:
        user_id = await database.execute(query)
        return {**user.dict(), "id": user_id}
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=400, detail=f"User creation failed: {e}")

@app.get("/users/{user_id}")
async def get_user(user_id: int):
    query = users.select().where(users.c.id == user_id)
    user = await database.fetch_one(query)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.delete("/users/{user_id}")
async def delete_user(user_id: int):
    query = users.delete().where(users.c.id == user_id)
    await database.execute(query)
    return {"message": "User deleted"}
