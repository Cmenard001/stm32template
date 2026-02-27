#!/bin/bash

# Download cubeclt on lfs
git lfs fetch --all
git lfs checkout

#if docker works
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running."
    echo "Hint: are you in a devcontainer?"
    exit 1
fi

# Check if docker is logged in to ghcr.io
if ! docker info | grep -q "ghcr.io"; then
    echo "Docker is not logged in to ghcr.io."
    docker login ghcr.io
fi

# Create or use existing multiarch builder
if ! docker buildx ls | grep -q stm32-multiarch; then
    docker buildx create --name stm32-multiarch --driver docker-container --platform linux/amd64,linux/arm64 --use
else
    docker buildx use stm32-multiarch
fi

# Build the image
docker buildx build --target dev --platform linux/amd64,linux/arm64 --builder stm32-multiarch -t ghcr.io/cmenard001/stm32template:dev . --push $1
if [ $? -ne 0 ]; then
    echo "Docker build failed."
    exit 1
fi

echo "To cleanup your repo lfs files; you can run:"
echo "git lfs prune"
