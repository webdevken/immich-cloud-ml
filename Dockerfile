FROM ghcr.io/immich-app/immich-machine-learning:release-cuda

# Switch to root to install packages and run supervisor
USER root

# Install Supervisor, curl, and required certificates
RUN apt-get update && apt-get install -y supervisor curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Tailscale directly from their official script
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Create necessary directories for logging and storage fallbacks
RUN mkdir -p /workspace/ollama_models /workspace/immich_cache /var/log/supervisor

# Copy the supervisor configuration into the container
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose ports (Ollama: 11434, Immich ML: 3003)
EXPOSE 11434 3003

# Override the default Immich entrypoint to start Supervisor instead
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]