#!/bin/bash
# ============================================================================ #
# MariaDB Initialization Script                                                #
# This script initializes the MariaDB database and creates users               #
# ============================================================================ #

set -e  # Exit immediately if a command fails

# ============================================================================ #
# VARIABLES                                                                    #
# ============================================================================ #

# Path where MariaDB stores its data
DATA_DIR="/var/lib/mysql"

# MariaDB initialization marker file
# If this file exists, database is already initialized
INIT_MARKER="$DATA_DIR/.init_done"

# Secrets paths (mounted by Docker)
DB_ROOT_PASSWORD_FILE="/run/secrets/db_root_password"
DB_PASSWORD_FILE="/run/secrets/db_password"

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

# Read secret from file
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

log "Starting MariaDB initialization script..."

# Check if database is already initialized
if [ -f "$INIT_MARKER" ]; then
    log "Database already initialized. Skipping initialization."
    log "Starting MariaDB..."
    exec "$@"
fi

log "First run detected. Initializing database..."

# ============================================================================ #
# STEP 1: Install MariaDB database system tables                              #
# ============================================================================ #

log "Installing MariaDB system tables..."

# mysql_install_db creates the system database with initial privilege tables
# --user=mysql: run as mysql user (not root)
# --datadir: where to create the database files
mysql_install_db --user=mysql --datadir="$DATA_DIR" > /dev/null

if [ $? -ne 0 ]; then
    error "Failed to install MariaDB system tables"
fi

log "System tables installed successfully"

# ============================================================================ #
# STEP 2: Start MariaDB temporarily in background                             #
# ============================================================================ #

log "Starting MariaDB temporarily for configuration..."

# Start MariaDB in background without networking
# --skip-networking: don't listen on TCP port (security during init)
# --socket: use Unix socket for local connections
# & : run in background
mysqld --user=mysql --datadir="$DATA_DIR" --skip-networking --socket=/tmp/mysql.sock &

# Store the PID of the background process
MYSQL_PID=$!

log "Waiting for MariaDB to be ready..."

# Wait for MariaDB to be ready to accept connections
# Try for up to 30 seconds
for i in {1..30}; do
    if mysqladmin --socket=/tmp/mysql.sock ping &>/dev/null; then
        log "MariaDB is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        error "MariaDB failed to start within 30 seconds"
    fi
    sleep 1
done

# ============================================================================ #
# STEP 3: Read secrets                                                         #
# ============================================================================ #

log "Reading secrets..."

# Read root password from secret file
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    MYSQL_ROOT_PASSWORD=$(read_secret "$DB_ROOT_PASSWORD_FILE")
    log "Root password loaded from secret"
fi

# Read user password from secret file
if [ -z "$MYSQL_PASSWORD" ]; then
    MYSQL_PASSWORD=$(read_secret "$DB_PASSWORD_FILE")
    log "User password loaded from secret"
fi

# Validate that required environment variables are set
if [ -z "$MYSQL_DATABASE" ]; then
    error "MYSQL_DATABASE environment variable is not set"
fi

if [ -z "$MYSQL_USER" ]; then
    error "MYSQL_USER environment variable is not set"
fi

log "All secrets and environment variables loaded"

# ============================================================================ #
# STEP 4: Execute SQL commands to configure database                          #
# ============================================================================ #

log "Configuring database, creating users, and setting permissions..."

# Execute SQL commands using mysql client
# --socket: connect via Unix socket
# <<-EOF ... EOF: here-document (multi-line SQL commands)
mysql --socket=/tmp/mysql.sock <<-EOF
    -- Secure the root account
    -- Set root password
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    
    -- Remove anonymous users (security)
    DELETE FROM mysql.user WHERE User='';
    
    -- Disallow root login remotely (security)
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    
    -- Remove test database (not needed)
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    
    -- Create the WordPress database
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
    
    -- Create WordPress user with access from any host (%)
    -- % is needed because WordPress container has a different IP
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    
    -- Grant all privileges on WordPress database to WordPress user
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    
    -- Apply changes immediately
    FLUSH PRIVILEGES;
EOF

if [ $? -ne 0 ]; then
    error "Failed to execute SQL configuration commands"
fi

log "Database configured successfully"

# ============================================================================ #
# STEP 5: Stop temporary MariaDB instance                                     #
# ============================================================================ #

log "Stopping temporary MariaDB instance..."

# Send shutdown command to MariaDB
mysqladmin --socket=/tmp/mysql.sock shutdown

# Wait for the background process to finish
wait $MYSQL_PID

log "Temporary instance stopped"

# ============================================================================ #
# STEP 6: Create initialization marker                                        #
# ============================================================================ #

# Create marker file to indicate initialization is complete
touch "$INIT_MARKER"
log "Initialization marker created"

log "MariaDB initialization completed successfully!"

# ============================================================================ #
# STEP 7: Start MariaDB in foreground (main process)                          #
# ============================================================================ #

log "Starting MariaDB as main process..."

# exec replaces the current process with mysqld
# This makes mysqld PID 1 (required for Docker)
# "$@" passes all arguments from CMD in Dockerfile (mysqld_safe)
exec "$@"
