###################################################################################################
# ROS2 Simulator Service                                                                          #
# MCR Ubuntu base + ROS2 Jazzy installation.                                                      #
###################################################################################################

ARG TARGETPLATFORM=linux/amd64

# Stage 1: Builder (ROS toolchain + interface build)
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04@sha256:ad92cae7c25cafb1e7bb5aa7520b81be85fac022ea92e404b94a11127631fae3 AS builder
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1

SHELL ["/bin/bash","-o","pipefail","-c"]
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    curl=8.5.0-2ubuntu10.6 \
    gnupg=2.4.4-2ubuntu17.3 \
    lsb-release=12.0-2 \
    ca-certificates=20240203 \
  && mkdir -p /usr/share/keyrings \
  && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg \
  && arch="$(dpkg --print-architecture)" \
  && codename="$(. /etc/os-release && printf '%s' "$UBUNTU_CODENAME")" \
  && echo "deb [arch=${arch} signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu ${codename} main" > /etc/apt/sources.list.d/ros2.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential=12.10ubuntu1 \
    git=1:2.43.0-1ubuntu7.3 \
    python3-pip=24.0+dfsg-1ubuntu1.3 \
    ros-jazzy-ros-base \
    ros-jazzy-geometry-msgs \
    ros-jazzy-sensor-msgs \
    ros-jazzy-nav-msgs \
    ros-jazzy-std-msgs \
    ros-jazzy-diagnostic-msgs \
    ros-jazzy-rmw-cyclonedds-cpp \
    ros-jazzy-rosidl-default-generators \
    ros-jazzy-ament-cmake \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /workspace
COPY resources/ros-interfaces/edge-ros-interface/ /workspace/edge-ros-interface/
# hadolint ignore=SC1091 (ROS setup script provided by base image)
RUN pip3 install --break-system-packages --ignore-installed --no-cache-dir colcon-common-extensions==0.3.0 \
  && source /opt/ros/jazzy/setup.bash && colcon build --packages-select edge_ros_interface

# Stage 2: Runtime (minimal + bag storage plugin + interfaces)
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04@sha256:ad92cae7c25cafb1e7bb5aa7520b81be85fac022ea92e404b94a11127631fae3 AS runtime
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1

SHELL ["/bin/bash","-o","pipefail","-c"]
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    curl=8.5.0-2ubuntu10.6 \
    gnupg=2.4.4-2ubuntu17.3 \
    lsb-release=12.0-2 \
    ca-certificates=20240203 \
    python3-pip=24.0+dfsg-1ubuntu1.3 \
  && mkdir -p /usr/share/keyrings \
  && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg \
  && arch="$(dpkg --print-architecture)" \
  && codename="$(. /etc/os-release && printf '%s' "$UBUNTU_CODENAME")" \
  && echo "deb [arch=${arch} signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu ${codename} main" > /etc/apt/sources.list.d/ros2.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    ros-jazzy-ros-base \
    ros-jazzy-geometry-msgs \
    ros-jazzy-sensor-msgs \
    ros-jazzy-nav-msgs \
    ros-jazzy-std-msgs \
    ros-jazzy-diagnostic-msgs \
    ros-jazzy-rmw-cyclonedds-cpp \
    ros-jazzy-rosbag2-storage-mcap \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built interface artifacts
COPY --from=builder /workspace/install/edge_ros_interface/share/edge_ros_interface /opt/ros/jazzy/share/edge_ros_interface
COPY --from=builder /workspace/install/edge_ros_interface/lib/ /opt/ros/jazzy/lib/
COPY --from=builder /workspace/install/edge_ros_interface/lib/python3.12/site-packages/edge_ros_interface /opt/ros/jazzy/lib/python3.12/site-packages/edge_ros_interface

# Shared base Python requirements
COPY services/requirements.txt requirements.base.txt
RUN pip3 install --break-system-packages --ignore-installed --no-cache-dir -r requirements.base.txt

# Simulator-specific requirements
COPY services/ros2-simulator/requirements.txt requirements.sim.txt
RUN if [ -s requirements.sim.txt ]; then pip3 install --break-system-packages --ignore-installed --no-cache-dir -r requirements.sim.txt; fi

ENV ROS_PACKAGE_PATH="" \
    PYTHONPATH=""

# Env paths
ENV ROS_PACKAGE_PATH="/opt/ros/jazzy/share:${ROS_PACKAGE_PATH:-}" \
    PYTHONPATH="/opt/ros/jazzy/lib/python3.12/site-packages:${PYTHONPATH:-}"

# Application source
COPY services/ros2-simulator/src/ ./src/

# Non-root
RUN chown -R 1000:1000 /app
USER 1000

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 CMD curl -f http://localhost:8080/health || exit 1
EXPOSE 8080
# hadolint ignore=SC1091 (ROS setup script provided by base image)
CMD ["bash","-c","source /opt/ros/jazzy/setup.bash && exec python3 /app/src/ros2_simulator.py"]
