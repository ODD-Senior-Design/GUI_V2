# Stage 1: Build the Flutter web app
FROM debian:latest AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl git wget unzip \
    libxi6 libgtk-3-0 libxrender1 libxtst6 libxslt1.1 \
    libglu1-mesa fonts-droid-fallback lib32stdc++6 python3 \
    && apt-get clean

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter

# Set Flutter path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Verify Flutter installation and update
RUN flutter doctor -v

# Create app directory and copy project
WORKDIR /app
COPY . /app/

# Install project dependencies
RUN flutter pub get

# Build the web app with environment variables
RUN flutter build web --release \
    --dart-define=CAPTURE_API_URL=http://192.168.157.225:3000/capture \
    --dart-define=SOCKET_IO_URL=http://192.168.157.225:3000/stream \
    --dart-define=API_BASE_URL=https://api.ranga-family.com \
    --dart-define=DEBUG_MODE=true

# Stage 2: Serve with Nginx
FROM nginx:1.21.1-alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80