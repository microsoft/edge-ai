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
        tar \
        gzip \
    && tdnf clean all \
    && groupadd -r appuser \
    && useradd -r -g appuser appuser

# Install static FFmpeg binary
RUN curl -fsSL "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz" \
    -o /tmp/ffmpeg.tar.xz \
    && tar -xf /tmp/ffmpeg.tar.xz -C /tmp \
    && cp /tmp/ffmpeg-*-amd64-static/ffmpeg /usr/local/bin/ffmpeg \
    && chmod +x /usr/local/bin/ffmpeg \
    && rm -rf /tmp/ffmpeg*

# Install MediaMTX RTSP server
ARG MEDIAMTX_VERSION=1.12.2
RUN curl -fsSL "https://github.com/bluenviron/mediamtx/releases/download/v${MEDIAMTX_VERSION}/mediamtx_v${MEDIAMTX_VERSION}_linux_amd64.tar.gz" \
    | tar -xz -C /usr/local/bin mediamtx \
    && chmod +x /usr/local/bin/mediamtx

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code and configuration
COPY src/ /app/src/
COPY static/ /app/static/
COPY mediamtx.yml /app/mediamtx.yml

# Copy default media and create upload directory
COPY media/pipe.jpg /data/pipe.jpg
COPY media/leaking-pipe.mp4 /data/leaking-pipe.mp4
RUN mkdir -p /app/uploads \
    && chown -R appuser:appuser /app /data

USER appuser

EXPOSE 8080 8554 8189/udp 8189/tcp

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health')" || exit 1

CMD ["python3", "-m", "src.main"]
