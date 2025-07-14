from fastapi import FastAPI
import os

SERVICE_NAME = os.getenv("SERVICE_NAME", "user")

app = FastAPI(title=f"{SERVICE_NAME} Service")

@app.get("/health")
def health_check():
    return {"status": "ok", "service": SERVICE_NAME}

@app.get("/")
def root():
    return {"message": f"Hello from {SERVICE_NAME}!"}
