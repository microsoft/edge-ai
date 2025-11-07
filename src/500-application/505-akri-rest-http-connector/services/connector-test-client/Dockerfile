FROM mcr.microsoft.com/azurelinux/base/python:3.12@sha256:1b978ce8a21fa7d698ea844d3ad4b2b69452c29be163395aca614d5f2ea44a94

WORKDIR /app

# Install curl for health checks and dependencies
RUN tdnf install -y curl ca-certificates && tdnf clean all

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Run the application
CMD ["python3", "app.py"]
