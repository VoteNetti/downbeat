# Dockerfile for testing downbeat installation scripts
FROM ubuntu:22.04

# Prevent interactive prompts during installation (persists for container runtime)
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Preconfigure tzdata to prevent interactive prompts
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    tzdata \
    python3 \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for testing (mimics real user environment)
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Ensure environment variables persist for testuser
RUN echo 'export DEBIAN_FRONTEND=noninteractive' >> /home/testuser/.bashrc && \
    echo 'export TZ=UTC' >> /home/testuser/.bashrc

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Copy the project files
COPY --chown=testuser:testuser . /home/testuser/downbeat

WORKDIR /home/testuser/downbeat

# Default command opens a shell for manual testing
CMD ["/bin/bash"]
