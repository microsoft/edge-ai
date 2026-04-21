##############################
# Builder Stage              #
##############################
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/azurelinux/base/python:3.12@sha256:8798301c18bf675d2a4c6fe45f01aa2fe8ab469f05e571a07579f63f865a4809 AS builder

WORKDIR /build

COPY ./services/sensor-simulator/requirements.txt ./requirements.txt

# Build dependency wheels for reproducible installs in runtime stage
RUN pip wheel --no-cache-dir --require-hashes --wheel-dir /tmp/wheels -r requirements.txt

##############################
# Runtime Stage              #
##############################
FROM --platform=$TARGETPLATFORM mcr.microsoft.com/azurelinux/base/python:3.12@sha256:8798301c18bf675d2a4c6fe45f01aa2fe8ab469f05e571a07579f63f865a4809 AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FIELD_CONFIG_PATH=/app/field_sources.json

WORKDIR /app

# Install runtime dependencies and create application user
# Security: Run as non-root user to minimize attack surface
RUN tdnf install -y \
        ca-certificates-3.0.0-13.azl3 \
        shadow-utils-4.14.3-2.azl3 \
    && tdnf clean all \
    && groupadd -r appuser \
    && useradd -r -g appuser appuser

# Install Python dependencies from pre-built wheels
COPY --from=builder /tmp/wheels /wheels
COPY --from=builder /build/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --no-index --find-links=/wheels -r /tmp/requirements.txt \
    && rm -rf /wheels /tmp/requirements.txt

# Copy application source and default configuration
COPY ./services/sensor-simulator/app.py ./app.py
COPY ./services/sensor-simulator/models.py ./models.py
COPY ./resources/field_sources.json ./field_sources.json

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8081/health')" || exit 1

CMD ["python3", "app.py"]
