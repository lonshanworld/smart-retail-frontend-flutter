# ============================================
# Stage 1: Build Flutter Web Application
# ============================================
FROM ubuntu:22.04 AS flutter-builder

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies: curl, git, unzip, and other required tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Download and install Flutter SDK
# Using stable channel - you can change to beta/dev if needed
ENV FLUTTER_VERSION=3.24.5
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN git clone --branch $FLUTTER_VERSION --depth 1 https://github.com/flutter/flutter.git $FLUTTER_HOME

# Pre-download Flutter dependencies and enable web support
RUN flutter precache --web
RUN flutter config --enable-web

# Verify Flutter installation
RUN flutter doctor -v

# Set working directory for app
WORKDIR /app

# Copy pubspec files first for better Docker layer caching
# This way, dependencies are only re-downloaded when pubspec changes
COPY pubspec.yaml pubspec.lock ./

# Download Flutter dependencies
RUN flutter pub get

# Copy the entire Flutter project
COPY . .

# Create .env file placeholder (you'll provide real values via docker-compose)
RUN touch .env

# Build Flutter web application for production
# --release flag optimizes for production
# --web-renderer canvaskit provides better performance and compatibility
RUN flutter build web --release --web-renderer canvaskit

# ============================================
# Stage 2: Serve with Nginx
# ============================================
FROM nginx:1.25-alpine

# Remove default Nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy built Flutter web files from builder stage
COPY --from=flutter-builder /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration (we'll create this next)
COPY nginx-flutter.conf /etc/nginx/conf.d/default.conf

# Expose port 80 for web traffic
EXPOSE 80

# Nginx will start automatically with the default CMD from the base image
# CMD ["nginx", "-g", "daemon off;"]
