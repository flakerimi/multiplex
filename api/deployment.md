># Games API Deployment Guide

## Overview

This document describes how to deploy the Games API to `games-api.base.al`.

## Architecture

```
games-api.base.al
├── API Server (Port 8100)
├── MySQL Database
└── Storage (local or S3)
```

## Prerequisites

- Docker and Docker Compose
- MySQL 8.0+ (or use Docker Compose)
- SSL Certificate for HTTPS
- Domain: games-api.base.al

## Local Development

### 1. Start the application

```bash
# Start with Docker Compose
docker-compose up -d

# Or run directly with Go
go run main.go
```

### 2. Seed the database

```bash
# If running with Docker
docker exec games-api go run main.go seed

# If running locally
go run main.go seed
```

### 3. Test the API

```bash
# Health check
curl http://localhost:8100/health

# Register a user
curl -X POST http://localhost:8100/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "player@example.com",
    "password": "secure_password",
    "name": "Test Player"
  }'

# Login
curl -X POST http://localhost:8100/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "player@example.com",
    "password": "secure_password"
  }'
```

## Production Deployment

### 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Configure Environment

```bash
# Copy production environment
cp .env.production .env

# Edit and set secure values
nano .env

# Important: Change these values!
# - JWT_SECRET
# - API_KEY
# - DB_PASSWORD
# - MYSQL_ROOT_PASSWORD
```

### 3. Deploy with Docker Compose

```bash
# Clone repository
git clone <your-repo>
cd api

# Build and start
docker-compose up -d --build

# Check logs
docker-compose logs -f api

# Run migrations (automatic on startup)
# Seed database
docker exec games-api go run main.go seed
```

### 4. Set up Reverse Proxy (Nginx)

```nginx
# /etc/nginx/sites-available/games-api.base.al

server {
    listen 80;
    server_name games-api.base.al;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name games-api.base.al;

    ssl_certificate /etc/letsencrypt/live/games-api.base.al/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/games-api.base.al/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req zone=api_limit burst=20 nodelay;

    location / {
        proxy_pass http://localhost:8100;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Static files with caching
    location /static/ {
        proxy_pass http://localhost:8100/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/games-api.base.al /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5. SSL Certificate with Let's Encrypt

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get certificate
sudo certbot --nginx -d games-api.base.al

# Auto-renewal (already set up by certbot)
sudo certbot renew --dry-run
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user

### Multiplex Game
- `GET /api/multiplex/progress` - Get user's game progress
- `POST /api/multiplex/progress` - Save game progress
- `GET /api/multiplex/achievements` - List all achievements
- `POST /api/multiplex/achievements/:slug` - Unlock achievement
- `GET /api/multiplex/stats` - Get player stats
- `POST /api/multiplex/stats` - Update player stats
- `GET /api/multiplex/leaderboard` - Get leaderboard

All game endpoints require Bearer token authentication:
```bash
curl -H "Authorization: Bearer <token>" https://games-api.base.al/api/multiplex/progress
```

## Monitoring

### Health Check

```bash
curl https://games-api.base.al/health
```

### Logs

```bash
# View API logs
docker-compose logs -f api

# View database logs
docker-compose logs -f db

# View nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Database Backup

```bash
# Backup
docker exec games-db mysqldump -u base_games -p base_games > backup_$(date +%Y%m%d).sql

# Restore
docker exec -i games-db mysql -u base_games -p base_games < backup_20250101.sql
```

## Scaling

### Horizontal Scaling

```yaml
# docker-compose.yml for multiple API instances
services:
  api:
    deploy:
      replicas: 3
    # ... rest of config
```

### Database Optimization

```sql
-- Add indexes for common queries
CREATE INDEX idx_game_progress_user_game ON game_progress(user_id, game_id);
CREATE INDEX idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX idx_player_stats_user_game ON player_stats(user_id, game_id);
```

## Troubleshooting

### Container won't start
```bash
docker-compose logs api
# Check .env file
# Verify database connection
```

### Database connection failed
```bash
# Check MySQL is running
docker-compose ps
# Test connection
docker exec games-api mysql -h db -u base_games -p
```

### High memory usage
```bash
# Check container stats
docker stats games-api
# Adjust resource limits in docker-compose.yml
```

## Security Checklist

- [ ] Change JWT_SECRET to secure random value
- [ ] Change API_KEY to secure random value
- [ ] Change all database passwords
- [ ] Enable HTTPS with valid SSL certificate
- [ ] Configure firewall (UFW)
- [ ] Set up fail2ban for SSH protection
- [ ] Enable rate limiting
- [ ] Regular security updates
- [ ] Database backups scheduled
- [ ] Monitoring and alerting configured

## Maintenance

```bash
# Update application
git pull
docker-compose build
docker-compose up -d

# Restart services
docker-compose restart

# Clean up
docker system prune -a
```

## Support

For issues and questions:
- GitHub Issues: <your-repo-url>
- Email: support@base.al
