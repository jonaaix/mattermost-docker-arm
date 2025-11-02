FROM debian:bookworm-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Build args for user and package version
ARG PUID=2000
ARG PGID=2000
ARG MM_PACKAGE="https://releases.mattermost.com/11.0.4/mattermost-11.0.4-linux-arm64.tar.gz"

# Environment
ENV PATH="/mattermost/bin:${PATH}" \
    TZ="Etc/UTC"

# Install only essentials
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
     ca-certificates \
     curl \
     tar \
     tzdata \
     media-types \
     unrtf \
     wv \
     poppler-utils \
     tidy \
  && rm -rf /var/lib/apt/lists/*

# Create user and directories
RUN mkdir -p /mattermost /mattermost/data /mattermost/plugins /mattermost/client/plugins \
  && groupadd -g "${PGID}" mattermost \
  && useradd -u "${PUID}" -g "${PGID}" -d /mattermost -s /usr/sbin/nologin mattermost

# Download and extract Mattermost
RUN curl -L "$MM_PACKAGE" | tar -xvz -C /mattermost --strip-components=1 \
  && chown -R mattermost:mattermost /mattermost

USER mattermost

# Healthcheck to verify service availability
HEALTHCHECK --interval=30s --timeout=10s \
  CMD curl -fsS http://localhost:8065/api/v4/system/ping || exit 1

WORKDIR /mattermost
ENTRYPOINT ["mattermost"]

EXPOSE 8065 8067 8074 8075

VOLUME ["/mattermost/data", "/mattermost/logs", "/mattermost/config", "/mattermost/plugins", "/mattermost/client/plugins"]
