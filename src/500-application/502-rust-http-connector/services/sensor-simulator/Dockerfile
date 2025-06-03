# =============================================================================
# Sensor Simulator Dockerfile
#
# This Dockerfile builds a lightweight container for the Flask-based sensor simulator application.
# The application simulates device sensor data and exposes an HTTP endpoint for data retrieval.
# Uses a multi-stage build to optimize the final image size by caching Python dependencies.
# =============================================================================

# STAGE 1: Builder - Builds Python wheels for dependencies
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/cbl-mariner/base/python:3.9 AS builder

WORKDIR /app

# Build Python wheels for faster installation in runtime stage
COPY src/requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# STAGE 2: Runtime - Creates the minimal production image
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/cbl-mariner/base/python:3.9

WORKDIR /app

# Install Python dependencies from pre-built wheels
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links=/wheels/ Flask \
    && rm -rf /wheels

# Copy application source code
COPY src/ .

# Expose Flask application port
EXPOSE 8080

# Run the sensor simulator application
CMD ["python3", "device-sensor.py"]
