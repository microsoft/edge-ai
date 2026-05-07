FROM mcr.microsoft.com/azurelinux/base/python:3.12

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install runtime dependencies and create application user
# Security: Upgrade base packages to pick up latest CVE fixes; run as non-root user
RUN rpm --import /etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY \
    && tdnf upgrade -y \
    && tdnf install -y ca-certificates shadow-utils \
    && tdnf clean all \
    && groupadd -r appuser \
    && useradd -r -g appuser appuser

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --require-hashes -r requirements.txt

# Copy application code
COPY connector_client.py .

RUN chown -R appuser:appuser /app

USER appuser

CMD ["python3", "connector_client.py"]
