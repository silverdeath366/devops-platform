from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from contextlib import asynccontextmanager

# Lifespan context – placeholder for future startup/shutdown hooks
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Init logging, metrics, connections, etc. here if needed
    yield

# Create FastAPI app
app = FastAPI(lifespan=lifespan)

# Notification payload model
class Notification(BaseModel):
    user_id: int
    message: str

# Health check endpoints
@app.get("/health")
@app.get("/healthz")
def health():
    return {"status": "ok"}

@app.post("/notify")
def send_notification(notification: Notification):
    print(f"📣 Notifying user {notification.user_id}: {notification.message}")
    return {"status": "sent", "user_id": notification.user_id}
