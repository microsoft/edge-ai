FROM mcr.microsoft.com/azurelinux/base/python:3.12@sha256:8300706a0e644a7e260b6a464a1ae3967181ee9057a4accceaaf0ecdedb1d4a2

WORKDIR /app

# Upgrade base image packages to latest patched versions to clear CVEs
RUN tdnf upgrade -y && tdnf clean all

# Install curl for health checks and dependencies
RUN tdnf install -y curl ca-certificates && tdnf clean all
COPY requirements.txt .
RUN pip install --no-cache-dir --require-hashes -r requirements.txt

# Copy application code
COPY app.py .

# Expose port
EXPOSE 8082

# Health check with authentication
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f -u device_user:device_pass_123 http://localhost:8082/health || exit 1

# Run the application
CMD ["python3", "app.py"]
