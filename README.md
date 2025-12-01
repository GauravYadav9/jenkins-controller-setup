# Jenkins Controller Setup

Infrastructure-as-Code (IaC) setup for a Jenkins controller using Docker, Docker Compose, and Jenkins Configuration as Code (JCasC). This produces a fully configured, reproducible Jenkins instance from a single `docker compose up` command.

This setup is intended for single-node Docker-based Jenkins environments and is not designed for distributed or Kubernetes-based execution.

## What Gets Pre-Configured

- All plugins pre-installed from a locked version list
- Admin user with configurable credentials
- Shared pipeline library ([jenkins-pipeline-library](https://github.com/GauravYadav9/jenkins-pipeline-library)) auto-registered
- Email notifications (Mailer + Email-Ext) with SMTP configuration
- Pipeline credentials (Qase API token, email distribution lists)
- Docker-in-Docker (DinD) support for container-based agents

## Quick Start

### 1. Prerequisites

- Docker and Docker Compose installed on your machine

### 2. Environment Setup

This project uses a `.env` file for all secrets and environment-specific configuration. No sensitive data is committed to Git.

```bash
cp .env.example .env
```

Edit the `.env` file and fill in all values:

- **`JENKINS_URL`**: Use your machine's network IP (e.g., `http://192.168.1.100:8086/`), not `localhost` — ensures email links are usable
- **`SMTP_PASSWORD`**: For Gmail, generate an [App Password](https://support.google.com/accounts/answer/185833) — standard login passwords won't work
- **`LIB_GIT_URL`**: Git URL of your shared pipeline library repository
- **`RECIPIENT_EMAILS`**: Production email distribution list (for `main` branch notifications)
- **`DEV_RECIPIENT_EMAILS`**: Development email list (for feature branch notifications)

### 3. Build and Run

```bash
docker compose up -d --build
```

This builds the `jenkins-controller:latest` image and starts the container.

### 4. Access Jenkins

- **URL**: `http://<YOUR_IP>:8086/`
- **Username**: The `ADMIN_USER` from your `.env` file
- **Password**: The `ADMIN_PASS` from your `.env` file

### 5. Stopping the Environment

```bash
# Stop and remove the container
docker compose down

# Full reset (deletes Jenkins volume — clean restart)
docker compose down -v
```

## File Architecture

| File | Purpose |
|---|---|
| `docker-compose.yml` | Service orchestrator — defines the `jenkins` service, maps ports (8086:8080), mounts volumes, and injects all `.env` variables |
| `Dockerfile` | Builds the `jenkins-controller:latest` image — installs Docker CLI, pre-installs plugins from `plugins.txt`, copies `casc.yaml` into the image |
| `casc.yaml` | JCasC configuration — declaratively defines security, admin user, Git tool, credentials, shared library reference, and email-ext settings |
| `plugins.txt` | Locked plugin versions for reproducible builds — includes Pipeline, Docker, Git, JUnit, HTML Publisher, Email-Ext, JCasC, Blue Ocean |
| `.env.example` | Template showing all required environment variables — copy to `.env` and fill in values |
| `.gitignore` | Ensures `.env` (containing secrets) is never committed to Git |

## Docker Compose Configuration

The `docker-compose.yml` defines:

- **Port mapping**: `8086:8080` (Jenkins UI), `50010:50000` (agent communication)
- **JVM tuning**: G1GC with 1g-3g heap, 200ms max GC pause
- **Volume**: `jenkins_home_v2` for persistent Jenkins data
- **DinD**: Docker socket mounted for container-based agent execution
- **Plugin sync**: `PLUGINS_FORCE_UPGRADE=true` ensures `plugins.txt` versions override stale volume plugins

## JCasC Configuration

The `casc.yaml` configures:

- **Security**: Local security realm, no anonymous access, no self-signup
- **Shared Library**: `jenkins-pipeline-library` registered via Git with configurable default branch
- **Email-Ext**: Full SMTP configuration with TLS support, environment-variable driven
- **Credentials**: Qase API token, production and development email distribution lists — all injected from `.env`
- **Git Tool**: Default Git installation registered

All values are parameterized via `${VARIABLE:-default}` syntax — no hardcoded secrets.