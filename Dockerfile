# Stage 1: Prepare base Flutter image with web SDK enabled
FROM ghcr.io/cirruslabs/flutter:3.29.3 AS flutter-web-sdk

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable web support and pre-cache it (only run once unless flutter version changes)
RUN flutter config --enable-web && \
    flutter precache --web

# Stage 2: Restore dependencies using only pubspec files
FROM flutter-web-sdk AS deps

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Stage 3: Copy full source and build release
FROM deps AS builder

COPY . .
RUN flutter build web --release

# Stage 4: Serve with Caddy
FROM caddy:alpine

# Copy built web app from builder
COPY --from=builder /app/build/web /usr/share/caddy

EXPOSE 80