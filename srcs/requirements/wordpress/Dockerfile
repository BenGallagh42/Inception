# ============================================================================ #
# WordPress + PHP-FPM Dockerfile                                               #
# This creates a WordPress installation with PHP-FPM                           #
# ============================================================================ #

# Use Debian Bullseye as base image
FROM debian:bullseye

# Install PHP-FPM and required PHP extensions
# WordPress requires these specific extensions to function properly
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # PHP-FPM (FastCGI Process Manager)
    php7.4-fpm \
    # PHP extensions required by WordPress
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-mbstring \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    php7.4-intl \
    # Utilities
    curl \
    wget \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install WP-CLI (WordPress Command Line Interface)
# WP-CLI allows us to install and configure WordPress from command line
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp && \
    # Verify installation
    wp --info --allow-root

# Copy PHP-FPM configuration
# This configures how PHP-FPM listens and handles requests
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Copy WordPress setup script
COPY tools/setup-wordpress.sh /usr/local/bin/setup-wordpress.sh

# Make script executable
RUN chmod +x /usr/local/bin/setup-wordpress.sh

# Create directory for WordPress files
# This is where WordPress will be installed
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

# Expose port 9000 (PHP-FPM default port)
# NGINX will connect to this port
EXPOSE 9000

# Use setup script as entrypoint
# This will download and configure WordPress before starting PHP-FPM
ENTRYPOINT ["/usr/local/bin/setup-wordpress.sh"]

# Start PHP-FPM in foreground mode
# -F: run in foreground (required for Docker)
# -R: allow running as root (needed in container context)
CMD ["php-fpm7.4", "-F", "-R"]
