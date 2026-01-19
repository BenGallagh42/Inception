# Developer Documentation

## Setup from scratch

**Prerequisites:**
- Virtual Machine
- Docker + Docker Compose installed

**Install Docker:**
```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-compose-plugin
sudo usermod -aG docker $USER
```

**Clone and configure:**
```bash
git clone [repo_url]
cd Inception
```

**Create secrets:**
```bash
mkdir -p secrets
echo "password" > secrets/db_password.txt
echo "rootpass" > secrets/db_root_password.txt
cat > secrets/credentials.txt << EOF
WP_ADMIN_USER=inception
WP_ADMIN_PASSWORD=pass
WP_ADMIN_EMAIL=admin@local
WP_USER=regular_user
WP_USER_PASSWORD=pass
WP_USER_EMAIL=user@local
EOF
chmod 600 secrets/*.txt
```

**Create .env:**
```bash
cd srcs
cat > .env << EOF
DOMAIN_NAME=bboulmie.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress_user
EOF
```

## Build and launch
```bash
make
```

**What it does:**
1. Creates `/home/bboulmie/data/wordpress` and `/home/bboulmie/data/mariadb`
2. Builds images
3. Starts containers

## Manage containers
```bash
docker ps                    # List containers
docker logs nginx            # View logs
docker exec -it mariadb bash # Enter container
docker restart wordpress     # Restart
```

## Manage volumes
```bash
docker volume ls              # List volumes
docker volume inspect [name]  # View details
```

## Data location
```
/home/bboulmie/data/
├── wordpress/   # WordPress files
└── mariadb/     # Database files
```

Bind mounts link host directories to containers. Changes visible in both locations.