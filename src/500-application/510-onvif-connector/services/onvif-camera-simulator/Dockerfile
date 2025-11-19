FROM mcr.microsoft.com/azurelinux/base/python:3.12@sha256:1b978ce8a21fa7d698ea844d3ad4b2b69452c29be163395aca614d5f2ea44a94

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install runtime dependencies and create application user
RUN tdnf install -y \
        ca-certificates-3.0.0-13.azl3 \
        shadow-utils-4.14.3-2.azl3 \
        libxml2 \
        libxslt \
    && tdnf clean all \
    && groupadd -r appuser \
    && useradd -r -g appuser appuser

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY onvif_camera.py .

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health')" || exit 1

CMD ["python3", "onvif_camera.py"]
