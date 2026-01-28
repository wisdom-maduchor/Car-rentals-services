# Stage 1: Build Frontend (Node.js)
FROM node:20-alpine AS frontend-builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Build Backend (PHP + Nginx)
# Using serversideup for a simplified production-ready PHP+Nginx image
FROM serversideup/php:8.2-fpm-nginx-alpine
WORKDIR /var/www/html

# Switch to root to install dependencies
USER root
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    oniguruma-dev

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Copy application code
COPY --chown=www-data:www-data . .

# Copy built frontend assets from Stage 1
COPY --from=frontend-builder --chown=www-data:www-data /app/public/build ./public/build

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Set entrypoint to use serversideup's optimized runner
# This handles both Nginx and PHP-FPM
USER www-data
