FROM python:3.11-slim

WORKDIR /app

# Install curl for health checks and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends curl=7.88.1-10+deb12u7 && rm -rf /var/lib/apt/lists/*

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Run the application
CMD ["python", "app.py"]
