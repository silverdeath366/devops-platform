from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from databases import Database
from models import users, metadata
import sqlalchemy

DATABASE_URL = "sqlite:///./auth.db"
database = Database(DATABASE_URL)
engine = sqlalchemy.create_engine(DATABASE_URL)
metadata.create_all(engine)

app = FastAPI()

class User(BaseModel):
    username: str
    password: str

@app.on_event("startup")
async def startup():
    await database.connect()

@app.on_event("shutdown")
async def shutdown():
    await database.disconnect()

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.post("/register")
async def register(user: User):
    query = users.insert().values(username=user.username, password=user.password)
    try:
        await database.execute(query)
        return {"message": "User registered"}
    except Exception:
        raise HTTPException(status_code=400, detail="Username already exists")

@app.post("/login")
async def login(user: User):
    query = users.select().where(users.c.username == user.username)
    db_user = await database.fetch_one(query)
    if db_user and db_user["password"] == user.password:
        return {"message": "Login successful"}
    raise HTTPException(status_code=401, detail="Invalid credentials")
