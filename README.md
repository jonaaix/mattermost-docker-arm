# Mattermost Docker ARM

A minimal Docker Compose setup to run [Mattermost](https://mattermost.com/) on ARM architecture.

## Getting Started

1. Clone this repository:
   ```bash
   git clone https://github.com/jonaaix/mattermost-docker-arm.git
   cd mattermost-docker-arm
   ```

2. Copy the example files:
   ```bash
   cp .env.example .env
   cp compose.example.yaml compose.yaml
   ```

3. Configure your environment:
   Edit the `.env` file to set values such as the database password and site URL.

4. Start the services:
   ```bash
   docker compose build
   docker compose up -d
   ```

5. Open Mattermost in your browser:
   [http://localhost:8065](http://localhost:8065)

## Update
To update, edit the Dockerfile and upgrade the Mattermost version in:
```Dockerfile
ARG MM_PACKAGE="https://releases.mattermost.com/11.2.1/mattermost-team-11.2.1-linux-amd64.tar.gz"
```
**Note: Downgrade is not supported!**

Then rebuild and restart the containers:
```bash
docker compose build
docker compose up -d
```

---

For advanced configurations or production setup, refer to the [official Mattermost documentation](https://docs.mattermost.com/).
