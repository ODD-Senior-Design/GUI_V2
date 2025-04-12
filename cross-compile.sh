#!/bin/bash

set -e

IMAGE_NAME=flutter-arm64-base
CONTAINER_NAME=temp_flutter_run
OUTPUT_DIR=build-arm64-output
DOCKERFILE=Dockerfile
PLATFORM=linux/arm64
PROJECT_DIR=$(pwd)

echo "📦 Building Flutter project for ARM64 (mounted build)"

# Step 1: Enable QEMU
echo "🔧 Enabling QEMU emulation..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Step 2: Create and use Buildx builder if needed
if ! docker buildx inspect builder > /dev/null 2>&1; then
    echo "🚀 Creating buildx builder..."
    docker buildx create --name builder --use
else
    echo "✅ Using existing buildx builder."
    docker buildx use builder
fi

# Step 3: Build the base image (if not already built)
echo "🔨 Building Flutter base image from $DOCKERFILE..."
docker buildx build \
  --platform "$PLATFORM" \
  -f "$DOCKERFILE" \
  -t "$IMAGE_NAME" \
  --load .

# Step 4: Run the build inside container with mounted volume
echo "🛠️ Running flutter build inside container..."
docker run --rm --platform "$PLATFORM" \
  -v "$PROJECT_DIR":/app \
  -w /app \
  "$IMAGE_NAME" \
  bash -c "flutter build linux --release --tree-shake-icons"

# Step 5: Copy output locally
echo "📁 Copying build output..."
rm -rf "$OUTPUT_DIR"
cp -r build/linux/arm64/release/bundle "$OUTPUT_DIR"

echo "✅ Done! ARM64 build is ready at: $OUTPUT_DIR"
