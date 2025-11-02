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
   cp compose.example.yml compose.yml
   ```

3. Configure your environment:
   Edit the `.env` file to set values such as the database password and site URL.

4. Start the services:
   ```bash
   docker compose up -d
   ```

5. Open Mattermost in your browser:
   [http://localhost:8065](http://localhost:8065)

---

For advanced configurations or production setup, refer to the [official Mattermost documentation](https://docs.mattermost.com/).
