#!/usr/bin/env bash
# Build the Docker image and push to Docker Hub.
# Usage: ./deploy.sh 1.0.1
set -euo pipefail

VERSION="${1:-latest}"
IMAGE="bloodisblue/bidirectional-translations:${VERSION}"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Building Docker image: ${IMAGE} (amd64 for droplet)"
docker build --platform linux/amd64 -t "${IMAGE}" "${PROJECT_DIR}"

echo "==> Pushing to Docker Hub"
docker push "${IMAGE}"

echo ""
echo "==> Done. Now SSH to your droplet and run:"
echo ""
echo "    cd ~/blog-server"
echo "    docker compose pull bidirectional-translations"
echo "    docker compose up -d bidirectional-translations"
echo "    docker compose exec bidirectional-translations /app/bin/migrate"
