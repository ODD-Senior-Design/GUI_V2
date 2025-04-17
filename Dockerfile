# Use official CirrusLabs Flutter image for version 3.29.3
FROM ghcr.io/cirruslabs/flutter:3.29.3

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Install additional dependencies required for Linux desktop builds
RUN apt-get update && apt-get install -y --no-install-recommends \
    clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Linux desktop support
RUN flutter config --enable-linux-desktop

# Set up working directory
WORKDIR /app

# Copy only pubspec files first for better build caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the source code
COPY . .

# Create a non-root user (UID 1000) and switch to it
RUN useradd -m -u 1000 flutteruser && \
    chown -R flutteruser:flutteruser /app /opt/flutter
USER flutteruser

# Build for Linux (arm64 target supported within this container)
RUN flutter build linux --release

# Optional: expose port if your app uses one
EXPOSE 8080

# Run the compiled Linux binary
CMD ["/app/build/linux/arm64/release/bundle/namer_app"]