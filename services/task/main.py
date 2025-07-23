from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from databases import Database
from models import tasks, metadata
from contextlib import asynccontextmanager
import sqlalchemy

DATABASE_URL = "sqlite:///./task.db"
database = Database(DATABASE_URL)
engine = sqlalchemy.create_engine(DATABASE_URL)
metadata.create_all(engine)

@asynccontextmanager
async def lifespan(app: FastAPI):
    await database.connect()
    yield
    await database.disconnect()

app = FastAPI(lifespan=lifespan)

class TaskIn(BaseModel):
    title: str
    description: str = ""
    user_id: int

@app.get("/health")
@app.get("/healthz")
async def health():
    return {"status": "ok"}

@app.post("/tasks")
async def create_task(task: TaskIn):
    query = tasks.insert().values(
        title=task.title,
        description=task.description,
        user_id=task.user_id,
        completed=False
    )
    task_id = await database.execute(query)
    return {**task.dict(), "id": task_id, "completed": False}

@app.get("/tasks")
async def list_tasks():
    return await database.fetch_all(tasks.select())

@app.get("/tasks/{task_id}")
async def get_task(task_id: int):
    query = tasks.select().where(tasks.c.id == task_id)
    task = await database.fetch_one(query)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task

@app.delete("/tasks/{task_id}")
async def delete_task(task_id: int):
    query = tasks.delete().where(tasks.c.id == task_id)
    await database.execute(query)
    return {"message": "Task deleted"}
