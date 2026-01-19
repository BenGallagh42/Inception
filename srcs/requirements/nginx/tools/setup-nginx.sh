#!/bin/bash
# ============================================================================ #
# NGINX Setup Script                                                           #
# This script generates a self-signed SSL certificate for HTTPS                #
# ============================================================================ #

set -e  # Exit on error

# ============================================================================ #
# VARIABLES                                                                    #
# ============================================================================ #

SSL_DIR="/etc/nginx/ssl"
SSL_CERT="$SSL_DIR/nginx.crt"
SSL_KEY="$SSL_DIR/nginx.key"

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

# ============================================================================ #
# MAIN SCRIPT                                                                  #
# ============================================================================ #

log "Starting NGINX setup..."

# Check if certificates already exist
if [ -f "$SSL_CERT" ] && [ -f "$SSL_KEY" ]; then
    log "SSL certificates already exist. Skipping generation."
else
    log "Generating self-signed SSL certificate..."
    
    # Generate self-signed certificate
    # This creates both the certificate (.crt) and private key (.key)
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_KEY" \
        -out "$SSL_CERT" \
        -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=${DOMAIN_NAME}"
    
    if [ $? -ne 0 ]; then
        error "Failed to generate SSL certificate"
    fi
    
    log "SSL certificate generated successfully"
fi

# Set proper permissions on SSL files
chmod 600 "$SSL_KEY"
chmod 644 "$SSL_CERT"

log "SSL certificate permissions set"

# Substitute environment variables in nginx.conf
# This replaces ${DOMAIN_NAME} with the actual domain
log "Configuring NGINX with domain: $DOMAIN_NAME"

envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf > /etc/nginx/nginx.conf.tmp
mv /etc/nginx/nginx.conf.tmp /etc/nginx/nginx.conf

# Test NGINX configuration
log "Testing NGINX configuration..."
nginx -t

if [ $? -ne 0 ]; then
    error "NGINX configuration test failed"
fi

log "NGINX configuration is valid"

log "NGINX setup completed successfully!"

# Start NGINX (exec replaces this process)
log "Starting NGINX..."
exec "$@"
