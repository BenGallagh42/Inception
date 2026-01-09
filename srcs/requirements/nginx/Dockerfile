# ============================================================================ #
# NGINX Dockerfile                                                             #
# This creates an NGINX web server with TLS/SSL support                        #
# ============================================================================ #

# Use Debian Bullseye as base image
FROM debian:bullseye

# Install NGINX and OpenSSL
# OpenSSL is needed to generate self-signed SSL certificates
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    gettext-base && \
    rm -rf /var/lib/apt/lists/*

# Copy NGINX configuration file
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy SSL certificate generation script
COPY tools/setup-nginx.sh /usr/local/bin/setup-nginx.sh

# Make script executable
RUN chmod +x /usr/local/bin/setup-nginx.sh

# Create directory for SSL certificates
RUN mkdir -p /etc/nginx/ssl

# Expose port 443 (HTTPS)
# This is the only port exposed to the outside world
EXPOSE 443

# Use setup script as entrypoint
# This will generate SSL certificates before starting NGINX
ENTRYPOINT ["/usr/local/bin/setup-nginx.sh"]

# Start NGINX in foreground mode
# -g "daemon off;": run in foreground (required for Docker)
CMD ["nginx", "-g", "daemon off;"]
