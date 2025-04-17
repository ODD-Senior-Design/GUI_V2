# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:3.29.3 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable web support
RUN flutter config --enable-web

# Set working directory and install dependencies
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the Flutter project
COPY . .

# Write a hardcoded env.dart file
# RUN echo "\
# const String capturePictureUrl = 'http://localhost:3000?images';\n\
# const String socketIoUrl = 'http://localhost:3000/stream';\n\
# const String apiBaseUrl = 'https://api.ranga-family.com';\n\
# " > lib/env.dart

# Build Flutter for the web (release mode)
RUN flutter build web --release

# Stage 2: Serve with Caddy (HTTP)
FROM caddy:alpine

# Copy the web build output to Caddy's default web root
COPY --from=builder /app/build/web /usr/share/caddy

# Expose HTTP port
EXPOSE 80

# Start Caddy (default CMD)