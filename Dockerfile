# syntax=docker/dockerfile:1.4

#######################################
# STAGE 0: Base with Flutter web SDK
#######################################
FROM ghcr.io/cirruslabs/flutter:3.29.3 AS flutter-web-sdk

# noninteractive front‐end for any apt installs (if you ever add any)
ENV DEBIAN_FRONTEND=noninteractive

# ensure Flutter & Dart are on PATH
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable web support once per image
RUN flutter config --enable-web \
    && flutter precache --web

#######################################
# STAGE 1: Get dependencies (cached)
#######################################
FROM flutter-web-sdk AS deps

WORKDIR /app

# Only copy pubspec files so this layer is invalidated ONLY
# when you add/remove/update dependencies.
COPY pubspec.yaml pubspec.lock ./

# Cache your Pub packages between builds
RUN --mount=type=cache,target=/home/flutter/.pub-cache \
    flutter pub get

#######################################
# STAGE 2: Build the web output
#######################################
FROM deps AS builder

WORKDIR /app

# Copy everything else
COPY . .

# Build release web app, reusing the same pub-cache
RUN --mount=type=cache,target=/home/flutter/.pub-cache \
    flutter build web --release

#######################################
# STAGE 3: Serve with Caddy
#######################################
FROM caddy:alpine

# Copy only the compiled web assets
COPY --from=builder /app/build/web /usr/share/caddy

# Expose default HTTP port
EXPOSE 80

# By default, Caddy will serve /usr/share/caddy
