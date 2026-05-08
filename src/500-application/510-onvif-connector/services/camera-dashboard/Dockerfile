FROM mcr.microsoft.com/azurelinux/base/python:3.12@sha256:8798301c18bf675d2a4c6fe45f01aa2fe8ab469f05e571a07579f63f865a4809

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN tdnf upgrade -y && tdnf clean all

RUN tdnf install -y \
        ca-certificates \
        shadow-utils \
    && tdnf clean all \
    && groupadd -r appuser \
    && useradd -r -g appuser -m appuser

COPY requirements.txt .
RUN pip install --no-cache-dir --require-hashes -r requirements.txt

COPY src/ ./src/

RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 5001

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5001/health')"

CMD ["python3", "src/app.py"]
