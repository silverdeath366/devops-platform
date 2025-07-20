from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Could be used for initializing logs, metrics, etc.
    yield

app = FastAPI(lifespan=lifespan)

class Notification(BaseModel):
    user_id: int
    message: str

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/notify")
def send_notification(notification: Notification):
    # Simulate sending (could be webhook, email, SMS, etc.)
    print(f"📣 Notifying user {notification.user_id}: {notification.message}")
    return {"status": "sent", "user_id": notification.user_id}
# dummy change to test Trivy CI
