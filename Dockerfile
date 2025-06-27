# Use a specific Ubuntu version for consistency
FROM ubuntu:22.04

# Set non-interactive to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies required for Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    libgconf-2-4 \
    libglu1-mesa \
    libx11-6 \
    && apt-get clean

# Set a working directory
WORKDIR /app

# Download and install a specific version of Flutter SDK
RUN git clone https://github.com/flutter/flutter.git --depth 1 --branch 3.19.6 /opt/flutter

# Add Flutter to the PATH
ENV PATH="/opt/flutter/bin:$PATH"

# Pre-download Flutter dependencies
RUN flutter precache

# Copy the pubspec files first to leverage Docker cache
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the application code
COPY . .

# Run the build command
RUN flutter build web
