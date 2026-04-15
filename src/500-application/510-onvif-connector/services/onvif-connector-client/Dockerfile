FROM mcr.microsoft.com/azurelinux/base/python:3.12@sha256:8798301c18bf675d2a4c6fe45f01aa2fe8ab469f05e571a07579f63f865a4809

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install runtime dependencies and create application user
RUN tdnf install -y \
        ca-certificates-3.0.0-13.azl3 \
        shadow-utils-4.14.3-2.azl3 \
    && tdnf clean all \
    && groupadd -r appuser \
    && useradd -r -g appuser appuser

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY onvif_connector.py .

RUN chown -R appuser:appuser /app

USER appuser

CMD ["python3", "onvif_connector.py"]
