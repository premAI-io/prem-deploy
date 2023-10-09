# Deployment tools for Prem microservices

Facilitate deployments of Prem microservices with utility scripts and an HTTP server designed to safely handle updates, either manually or automatically via third-party services like GitHub Actions.

## Description

This solution provides a two-fold deployment strategy tailored for the Prem microservices:

1. **Utility Scripts**: Simplifies the manual management (start, stop, build, and update) of Dockerized Prem microservices directly on your machine.

2. **HTTP Deployment Server**: Offers a secure, automated deployment pipeline, allowing third parties (like CI/CD tools or authorized developers) to trigger updates remotely by interfacing with a dedicated HTTP endpoint.

## Prerequisites

- Docker & Docker Compose
- Golang (for HTTP server)
- Git

## Usage

### For Direct Management of Prem Microservices

Utilize the provided scripts for hands-on management of your microservices:

Pull and build Docker image for specified USER, REPO, and BRANCH:
```bash
./pull_and_build.sh {USER} {REPO} {BRANCH}
```

Bulk pull and build for 'prem-gateway', 'prem_app', and 'prem-daemon' with specified USER and REPO.
Note that if arguments are not provided, the default values are 'premAI-io' and 'main':
```bash
./pull_and_build_all.sh {PREM-GATEWAY-USER} {PREM-GATEWAY-BRANCH} {PREM-APP-USER} {PREM-APP-BRANCH} {PREM-DAEMON-USER} {PREM-DAEMON-BRANCH}
```

Boot up all Prem microservices:
```bash
./start.sh
```

Stop and clean all Prem microservices:
```bash
./stop.sh
```

### For Deployments via the HTTP Server

Build:
```bash
make build
```

Run:
```bash
make run USER=admin PASS=admin
```

Deploy all:
```bash
curl -X POST -u admin:admin http://localhost:9000/deploy
```

Deploy Specific Repo:
```bash
curl -X POST -u admin:admin http://localhost:9000/deploy?repo=REPO_NAME&user=USER_NAME&branch=BRANCH_NAME
```