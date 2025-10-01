###################################################################################################
# ROS2 Connector Service                                                                          #
# Uses Microsoft Container Registry Ubuntu base, installs ROS2 Jazzy                              #
# Multi-stage: builder (interfaces) -> runtime (minimal).                                         #
###################################################################################################

ARG TARGETPLATFORM=linux/amd64

# Stage 1: Builder - full toolchain for interface generation
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04@sha256:ad92cae7c25cafb1e7bb5aa7520b81be85fac022ea92e404b94a11127631fae3 AS builder
ENV DEBIAN_FRONTEND=noninteractive \
        PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1

SHELL ["/bin/bash","-o","pipefail","-c"]
RUN set -euo pipefail \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        curl=8.5.0-2ubuntu10.6 \
        gnupg=2.4.4-2ubuntu17.3 \
        lsb-release=12.0-2 \
        ca-certificates=20240203 \
    && mkdir -p /usr/share/keyrings \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && UBUNTU_CODENAME="$(. /etc/os-release && printf '%s' "$UBUNTU_CODENAME")" \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu ${UBUNTU_CODENAME} main" > /etc/apt/sources.list.d/ros2.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential=12.10ubuntu1 \
        git=1:2.43.0-1ubuntu7.3 \
        python3-pip=24.0+dfsg-1ubuntu1.3 \
        ros-jazzy-ros-base=0.11.0-1noble.20250915.233203 \
        ros-jazzy-geometry-msgs=5.3.6-1noble.20250824.000124 \
        ros-jazzy-sensor-msgs=5.3.6-1noble.20250824.003044 \
        ros-jazzy-nav-msgs=5.3.6-1noble.20250824.002357 \
        ros-jazzy-std-msgs=5.3.6-1noble.20250823.231150 \
        ros-jazzy-diagnostic-msgs=5.3.6-1noble.20250824.002016 \
        ros-jazzy-rmw-cyclonedds-cpp=2.2.3-1noble.20250823.225558 \
        ros-jazzy-rosidl-default-generators=1.6.0-3noble.20250823.224231 \
        ros-jazzy-ament-cmake=2.5.4-1noble.20250424.104545 \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --break-system-packages --ignore-installed --no-cache-dir colcon-common-extensions==0.3.0

WORKDIR /workspace
COPY resources/ros-interfaces/edge-ros-interface/ /workspace/edge-ros-interface/
# hadolint ignore=SC1091 (ROS setup script provided by base image)
RUN source /opt/ros/jazzy/setup.bash && colcon build --packages-select edge_ros_interface

# Stage 2: Runtime - minimal runtime + built interfaces
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04@sha256:ad92cae7c25cafb1e7bb5aa7520b81be85fac022ea92e404b94a11127631fae3 AS runtime
ENV DEBIAN_FRONTEND=noninteractive \
        PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
SHELL ["/bin/bash","-o","pipefail","-c"]
RUN set -euo pipefail \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        curl=8.5.0-2ubuntu10.6 \
        gnupg=2.4.4-2ubuntu17.3 \
        lsb-release=12.0-2 \
        ca-certificates=20240203 \
        python3-pip=24.0+dfsg-1ubuntu1.3 \
    && mkdir -p /usr/share/keyrings \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && UBUNTU_CODENAME="$(. /etc/os-release && printf '%s' "$UBUNTU_CODENAME")" \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu ${UBUNTU_CODENAME} main" > /etc/apt/sources.list.d/ros2.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ros-jazzy-ros-base=0.11.0-1noble.20250915.233203 \
        ros-jazzy-geometry-msgs=5.3.6-1noble.20250824.000124 \
        ros-jazzy-sensor-msgs=5.3.6-1noble.20250824.003044 \
        ros-jazzy-nav-msgs=5.3.6-1noble.20250824.002357 \
        ros-jazzy-std-msgs=5.3.6-1noble.20250823.231150 \
        ros-jazzy-diagnostic-msgs=5.3.6-1noble.20250824.002016 \
        ros-jazzy-rmw-cyclonedds-cpp=2.2.3-1noble.20250823.225558 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built interface artifacts
COPY --from=builder /workspace/install/edge_ros_interface/share/edge_ros_interface /opt/ros/jazzy/share/edge_ros_interface
COPY --from=builder /workspace/install/edge_ros_interface/lib/ /opt/ros/jazzy/lib/
COPY --from=builder /workspace/install/edge_ros_interface/lib/python3.12/site-packages/ /opt/ros/jazzy/lib/python3.12/site-packages/

# Python deps
COPY services/requirements.txt requirements.base.txt
RUN pip3 install --break-system-packages --ignore-installed --no-cache-dir -r requirements.base.txt
COPY services/ros2-connector/requirements.txt requirements.connector.txt
RUN if [ -s requirements.connector.txt ]; then pip3 install --break-system-packages --ignore-installed --no-cache-dir -r requirements.connector.txt; fi

# App source
COPY services/ros2-connector/src/ ./src/

# Non-root user
RUN chown -R 1000:1000 /app
USER 1000

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 CMD curl -f http://localhost:8080/health || exit 1
EXPOSE 8080
# hadolint ignore=SC1091 (ROS setup script provided by base image)
CMD ["bash","-c","source /opt/ros/jazzy/setup.bash && exec python3 /app/src/ros2_connector.py"]
