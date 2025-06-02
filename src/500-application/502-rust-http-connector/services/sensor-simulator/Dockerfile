# Dockerfile for building and running the device-sensor.py Flask sensor simulator.
# Uses a multi-stage build to create a minimal Python runtime image with pre-built dependencies.

# Stage 1: Build stage
FROM python:3.9-slim AS builder

WORKDIR /app

# Install build dependencies with pinned version
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential=12.9 \
    && rm -rf /var/lib/apt/lists/*

# Copy and install requirements
COPY src/requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# Stage 2: Runtime stage
FROM python:3.9-slim

WORKDIR /app

# Copy wheels from builder stage and install dependencies
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links=/wheels/ Flask \
    && rm -rf /wheels

# Copy application code
COPY src/ .

# Expose port
EXPOSE 8080

# Run the application
CMD ["python", "device-sensor.py"]
