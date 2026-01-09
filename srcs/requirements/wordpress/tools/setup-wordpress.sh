#!/bin/bash
# ============================================================================ #
# WordPress Setup Script                                                       #
# This script downloads, configures, and installs WordPress                    #
# ============================================================================ #

set -e  # Exit on error

# ============================================================================ #
# VARIABLES                                                                    #
# ============================================================================ #

# WordPress installation directory
WP_PATH="/var/www/html"

# WordPress configuration marker
INSTALL_MARKER="$WP_PATH/.wp_installed"

# Secrets paths
DB_PASSWORD_FILE="/run/secrets/db_password"
CREDENTIALS_FILE="/run/secrets/credentials"

# ============================================================================ #
# FUNCTIONS                                                                    #
# ============================================================================ #

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
    exit 1
}

read_secret() {
    local secret_file=$1
    if [ ! -f "$secret_file" ]; then
        error "Secret file not found: $secret_file"
    fi
    cat "$secret_file"
}

# ============================================================================ #
# MAIN SCRIPT                                                                  #
# ============================================================================ #

log "Starting WordPress setup..."

# Check if WordPress is already installed
if [ -f "$INSTALL_MARKER" ]; then
    log "WordPress already installed. Skipping setup."
    log "Starting PHP-FPM..."
    exec "$@"
fi

log "First run detected. Installing WordPress..."

# ============================================================================ #
# STEP 1: Wait for MariaDB to be ready                                         #
# ============================================================================ #

log "Waiting for MariaDB to be ready..."

# Wait for MariaDB container to be accessible
# Try for up to 60 seconds
for i in {1..60}; do
    if nc -z mariadb 3306 2>/dev/null; then
        log "MariaDB is ready!"
        break
    fi
    if [ $i -eq 60 ]; then
        error "MariaDB did not become ready within 60 seconds"
    fi
    sleep 1
done

# ============================================================================ #
# STEP 2: Download WordPress                                                   #
# ============================================================================ #

log "Downloading WordPress..."

# Change to WordPress directory
cd "$WP_PATH"

# Download WordPress core files
# --allow-root: required when running as root in Docker
wp core download --allow-root --locale=en_US

if [ $? -ne 0 ]; then
    error "Failed to download WordPress"
fi

log "WordPress downloaded successfully"

# ============================================================================ #
# STEP 3: Configure WordPress (wp-config.php)                                  #
# ============================================================================ #

log "Configuring WordPress..."

# Read database password from secret
MYSQL_PASSWORD=$(read_secret "$DB_PASSWORD_FILE")

# Create wp-config.php with database connection settings
wp config create \
    --dbname="$MYSQL_DATABASE" \
    --dbuser="$MYSQL_USER" \
    --dbpass="$MYSQL_PASSWORD" \
    --dbhost="mariadb:3306" \
    --allow-root

if [ $? -ne 0 ]; then
    error "Failed to create wp-config.php"
fi

log "WordPress configured successfully"

# ============================================================================ #
# STEP 4: Install WordPress                                                    #
# ============================================================================ #

log "Installing WordPress..."

# Source credentials from secret file
# This sets WP_ADMIN_USER, WP_ADMIN_PASSWORD, etc.
source "$CREDENTIALS_FILE"

# Install WordPress with initial settings
wp core install \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email \
    --allow-root

if [ $? -ne 0 ]; then
    error "Failed to install WordPress"
fi

log "WordPress installed successfully"

# ============================================================================ #
# STEP 5: Create additional WordPress user                                     #
# ============================================================================ #

log "Creating additional WordPress user..."

# Create a regular user (not administrator)
wp user create \
    "$WP_USER" \
    "$WP_USER_EMAIL" \
    --user_pass="$WP_USER_PASSWORD" \
    --role=author \
    --allow-root

if [ $? -ne 0 ]; then
    error "Failed to create WordPress user"
fi

log "WordPress user created successfully"

# ============================================================================ #
# STEP 6: Set proper permissions                                               #
# ============================================================================ #

log "Setting file permissions..."

# Set ownership to www-data (web server user)
chown -R www-data:www-data "$WP_PATH"

# Set directory permissions: 755 (rwxr-xr-x)
find "$WP_PATH" -type d -exec chmod 755 {} \;

# Set file permissions: 644 (rw-r--r--)
find "$WP_PATH" -type f -exec chmod 644 {} \;

log "Permissions set successfully"

# ============================================================================ #
# STEP 7: Create installation marker                                           #
# ============================================================================ #

touch "$INSTALL_MARKER"
log "Installation marker created"

log "WordPress setup completed successfully!"

# ============================================================================ #
# STEP 8: Start PHP-FPM                                                        #
# ============================================================================ #

log "Starting PHP-FPM..."

# exec replaces this script with PHP-FPM
# PHP-FPM becomes PID 1 (required for Docker)
exec "$@"
