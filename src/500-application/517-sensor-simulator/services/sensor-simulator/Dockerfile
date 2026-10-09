# Build from the component root:
#   docker build -f services/sensor-simulator/Dockerfile -t sensor-simulator:0.1.0 .

##############################
# Builder Stage              #
##############################
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/azurelinux/base/python:3.12@sha256:8300706a0e644a7e260b6a464a1ae3967181ee9057a4accceaaf0ecdedb1d4a2 AS builder

WORKDIR /build

RUN tdnf upgrade -y && tdnf clean all

COPY ./services/sensor-simulator/requirements.txt ./requirements.txt

RUN pip wheel --no-cache-dir --require-hashes --wheel-dir /tmp/wheels -r requirements.txt

##############################
# Runtime Stage              #
##############################
FROM --platform=$TARGETPLATFORM mcr.microsoft.com/azurelinux/base/python:3.12@sha256:8300706a0e644a7e260b6a464a1ae3967181ee9057a4accceaaf0ecdedb1d4a2 AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN tdnf upgrade -y \
    && tdnf install -y ca-certificates shadow-utils \
    && tdnf clean all \
    && groupadd --system --gid 1000 appuser \
    && useradd --system --uid 1000 --gid appuser --no-create-home appuser

COPY --from=builder /tmp/wheels /wheels
COPY --from=builder /build/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --no-index --require-hashes \
      --find-links=/wheels -r /tmp/requirements.txt \
    && rm -rf /wheels /tmp/requirements.txt

COPY --chown=root:root --chmod=0444 ./services/sensor-simulator/app.py ./services/sensor-simulator/models.py ./

USER 1000:1000

CMD ["python3", "app.py"]

LABEL org.opencontainers.image.source="https://github.com/microsoft/edge-ai"
LABEL org.opencontainers.image.title="Sensor Simulator"
LABEL org.opencontainers.image.description="Synthetic vibration, acoustic, and temperature MQTT publisher"
LABEL org.opencontainers.image.licenses="MIT"
