# # Stage 1: Build Frontend (Node.js)
# FROM node:20-alpine AS frontend-builder
# WORKDIR /app
# COPY package*.json ./
# RUN npm install
# COPY . .
# RUN npm run build

# # Stage 2: Build Backend (PHP + Nginx)
# # Using serversideup for a simplified production-ready PHP+Nginx image
# FROM serversideup/php:8.2-fpm-nginx-alpine
# WORKDIR /var/www/html

# # Switch to root to install dependencies
# USER root
# RUN apk add --no-cache \
#     git \
#     curl \
#     libpng-dev \
#     libxml2-dev \
#     zip \
#     unzip \
#     oniguruma-dev

# # Install PHP extensions
# RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# # Copy application code
# COPY --chown=www-data:www-data . .

# # Copy built frontend assets from Stage 1
# COPY --from=frontend-builder --chown=www-data:www-data /app/public/build ./public/build

# # Install PHP dependencies
# RUN composer install --no-dev --optimize-autoloader

# # Set entrypoint to use serversideup's optimized runner
# # This handles both Nginx and PHP-FPM
# USER www-data

# 1️⃣ Base image with PHP + Composer
FROM php:8.2-fpm

# 2️⃣ Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    zip \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    nodejs \
    npm \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd

# 3️⃣ Set working directory
WORKDIR /var/www

# 4️⃣ Copy PHP project files
COPY . .

# 5️⃣ Install PHP dependencies
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer install --no-dev --optimize-autoloader

# 6️⃣ Install JS dependencies & build Vite AFTER PHP is ready
RUN npm install
RUN npm run build

# 7️⃣ Set permissions for Laravel storage & cache
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# 8️⃣ Expose port
EXPOSE 10000

# 9️⃣ Start Laravel
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=10000"]
