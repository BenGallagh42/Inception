*This project has been created as part of the 42 curriculum by bboulmie.*

# Inception

Docker infrastructure project - WordPress site with NGINX and MariaDB.

## Description

This project sets up a complete web stack using Docker containers. The goal is to learn containerization and system administration by building a WordPress website infrastructure from scratch.

The stack consists of:
- **NGINX** - handles HTTPS on port 443
- **WordPress + PHP-FPM** - the website itself
- **MariaDB** - database

Each service runs in its own container with custom Dockerfiles (no pre-built images from DockerHub).

## Instructions

### Build and Start
```bash
make
```

This will:
- Create volume directories in `/home/login/data/`
- Build all Docker images
- Start all containers

### Available Commands
```bash
make          # Build and start everything
make down     # Stop and remove containers
make clean    # Remove containers, images, and volumes
make fclean   # Full clean including data directories
make re       # Rebuild everything from scratch
make ps       # Show container status
make logs     # Show logs from all containers
```

### Access

Open your browser and go to `https://bboulmie.42.fr`

WordPress admin panel: `https://bboulmie.42.fr/wp-admin`

## Project Design

### Architecture
```
User → NGINX (443) → WordPress (9000) → MariaDB (3306)
```

Only NGINX is exposed to the outside. WordPress and MariaDB communicate through a private Docker network.

Data persists in `/home/login/data/` using Docker volumes.

### Technical Choices

**Virtual Machines vs Docker**

I used Docker instead of VMs because:
- Much lighter (containers share the host kernel)
- Faster to start and stop
- Easier to rebuild if something breaks
- Better for this kind of multi-service architecture

VMs would be overkill here - each would need its own full OS.

**Secrets vs Environment Variables**

Passwords are stored as Docker secrets (files in `/run/secrets/`) instead of environment variables because:
- More secure - not visible in `docker inspect`
- Read-only access
- Not exposed in process environment

The `.env` file is for non-sensitive config (domain name, database name, etc).

**Docker Network vs Host Network**

I created a custom bridge network so containers can talk to each other by service name (e.g. `wordpress:9000`). 

Host network would expose everything directly to the host machine - bad for security. The subject also forbids it.

**Docker Volumes vs Bind Mounts**

I used Docker-managed volumes with bind mounts to `/home/login/data/`. This way:
- Docker handles the volume lifecycle
- Data is still accessible on the host (required by subject)
- Persists even when containers are deleted

Pure bind mounts would work but Docker volumes are the recommended approach.

## Resources

- [Docker docs](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/)
- [NGINX docs](https://nginx.org/en/docs/)
- [WordPress Codex](https://wordpress.org/documentation/)
- [MariaDB KB](https://mariadb.com/kb/)
<<<<<<< HEAD
- Various Stack Overflow threads when debugging
=======
>>>>>>> 3173b6539153facea6e6d23371219c7b05fc61d3

### AI Usage

I used AI as a learning tool to:
- Understand Docker concepts I wasn't familiar with (networks, volumes, secrets)
- Explain configuration file syntax (NGINX, PHP-FPM, MariaDB)
- Debug error messages and troubleshoot issues
- Learn bash scripting for the initialization scripts

---

*Project completed January 2025*
