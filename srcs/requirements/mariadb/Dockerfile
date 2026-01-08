# ============================================================================ #
# MariaDB Dockerfile                                                           #
# This creates a MariaDB (MySQL) database server                               #
# ============================================================================ #

# Use Debian Bullseye as base image
# Bullseye is Debian 11 (penultimate stable version)
FROM debian:bullseye

# Update package list and install MariaDB server
# --no-install-recommends: only install essential packages (smaller image)
# rm -rf /var/lib/apt/lists/*: clean up to reduce image size
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    mariadb-server \
    mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# Copy custom MariaDB configuration
# This will configure MariaDB to accept network connections
COPY conf/mariadb.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy the initialization script
# This script will create the database and users
COPY tools/init-db.sh /usr/local/bin/init-db.sh

# Make the script executable
RUN chmod +x /usr/local/bin/init-db.sh

# Expose port 3306 (MySQL/MariaDB default port)
# This is informational; actual access is controlled by docker-compose
EXPOSE 3306

# Use the initialization script as entrypoint
# This ensures the database is properly set up before starting
ENTRYPOINT ["/usr/local/bin/init-db.sh"]

# Start MariaDB server
# mysqld_safe is a wrapper that adds safety features (auto-restart, logging)
CMD ["mysqld_safe"]
