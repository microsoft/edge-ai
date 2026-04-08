FROM mcr.microsoft.com/azurelinux/base/python:3.12@sha256:8798301c18bf675d2a4c6fe45f01aa2fe8ab469f05e571a07579f63f865a4809

WORKDIR /app

# Install curl for health checks and dependencies
RUN tdnf install -y curl ca-certificates && tdnf clean all
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["python3", "app.py"]
