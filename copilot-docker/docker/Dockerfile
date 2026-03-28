FROM node:20-slim

ARG COPILOT_CLI_VERSION=latest

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Install Copilot CLI via npm
RUN npm install -g @github/copilot@${COPILOT_CLI_VERSION} \
    && npm cache clean --force

# Create non-root user for running Copilot
RUN useradd -m -s /bin/bash copilot

USER copilot
WORKDIR /workspace

# Pre-create config directory
RUN mkdir -p /home/copilot/.copilot

COPY --chown=copilot:copilot entrypoint.sh /home/copilot/entrypoint.sh
RUN chmod +x /home/copilot/entrypoint.sh

ENTRYPOINT ["/home/copilot/entrypoint.sh"]
