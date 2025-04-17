# Use a newer Ubuntu base image for ARM64 (Raspberry Pi 4, 64-bit OS)
FROM arm64v8/ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
ENV FLUTTER_VERSION=3.29.3  

# Install dependencies for Flutter and Linux desktop builds
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip libglu1-mesa openjdk-11-jdk \
    build-essential clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
WORKDIR /opt
RUN git clone --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git
RUN flutter config --enable-linux-desktop
RUN flutter doctor

# Set up working directory for the Flutter app
WORKDIR /app

# Copy only pubspec files first to leverage caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the app
COPY . .

# Create a non-root user for security
RUN useradd -m -u 1000 flutteruser && chown -R flutteruser:flutteruser /app /opt/flutter
USER flutteruser

# Build the Flutter app for Linux
RUN flutter build linux --release

# Expose port for debugging (optional, if the app includes a web server)
EXPOSE 8080

# Run the Flutter app
CMD ["/app/build/linux/arm64/release/bundle/namer_app"]