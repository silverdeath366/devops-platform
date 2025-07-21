FROM python:3.12-slim

WORKDIR /app

# Copy all service files first
COPY ./services/notification /app

# Install deps
RUN pip install --no-cache-dir -r requirements.txt

# Set PYTHONPATH to allow absolute imports (for tests and app)
ENV PYTHONPATH=/app

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
