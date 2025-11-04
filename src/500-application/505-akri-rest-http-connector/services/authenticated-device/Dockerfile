FROM python:3.11-slim

WORKDIR /app

# Install curl for health checks and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends curl=7.88.1-10+deb12u7 && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Expose port
EXPOSE 8082

# Health check with authentication
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f -u deviceuser:devicepass123 http://localhost:8082/health || exit 1

# Run the application
CMD ["python", "app.py"]
