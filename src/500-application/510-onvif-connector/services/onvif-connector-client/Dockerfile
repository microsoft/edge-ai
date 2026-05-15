FROM mcr.microsoft.com/azurelinux/base/python:3.12@sha256:8798301c18bf675d2a4c6fe45f01aa2fe8ab469f05e571a07579f63f865a4809

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Upgrade base image packages to latest patched versions to clear CVEs
RUN tdnf upgrade -y && tdnf clean all

# Install runtime dependencies and create application user
RUN tdnf install -y \
        ca-certificates \
        shadow-utils \
    && tdnf clean all \
    && groupadd -r appuser \
    && useradd -r -g appuser appuser

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --require-hashes -r requirements.txt

# Copy application code
COPY onvif_connector.py .

RUN chown -R appuser:appuser /app

USER appuser

CMD ["python3", "onvif_connector.py"]
