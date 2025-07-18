from fastapi import FastAPI
import logging
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

SERVICE_NAME = os.getenv("SERVICE_NAME", "notification")

app = FastAPI(title=f"{SERVICE_NAME} Service")

@app.get("/")
def root():
    logger.info("Root endpoint called")
    return {"message": f"Hello from {SERVICE_NAME}!"}

@app.get("/health")
def health():
    return {"status": "ok"}
