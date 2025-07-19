from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from databases import Database
from models import users, metadata
import sqlalchemy

DATABASE_URL = "sqlite:///./user.db"
database = Database(DATABASE_URL)
engine = sqlalchemy.create_engine(DATABASE_URL)
metadata.create_all(engine)

app = FastAPI()

class UserIn(BaseModel):
    name: str
    email: str

@app.on_event("startup")
async def startup():
    await database.connect()

@app.on_event("shutdown")
async def shutdown():
    await database.disconnect()

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.get("/users")
async def get_users():
    query = users.select()
    return await database.fetch_all(query)

@app.post("/users")
async def create_user(user: UserIn):
    query = users.insert().values(name=user.name, email=user.email)
    try:
        user_id = await database.execute(query)
        return {**user.dict(), "id": user_id}
    except Exception:
        raise HTTPException(status_code=400, detail="Email already exists")

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
