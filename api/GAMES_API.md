# Games API - Centralized Gaming Platform

## Overview

A centralized API system for managing games, user progress, achievements, and statistics across multiple games. Built with the Base Framework (Go), designed to be deployed at `games-api.base.al`.

## Architecture

```
games-api.base.al
├── /api/auth              - Authentication (register, login)
├── /api/multiplex         - Multiplex game endpoints
│   ├── /progress          - Save/load game state
│   ├── /achievements      - List and unlock achievements
│   ├── /stats             - Player statistics
│   └── /leaderboard       - Top players
└── /api/[future-games]    - Extensible for more games
```

## Features

- **Centralized Authentication** - Single login for all games
- **Game Progress Sync** - Cloud save/load game state
- **Achievement System** - Unlock and track achievements across games
- **Player Statistics** - Track scores, playtime, wins, etc.
- **Leaderboards** - Compare players globally
- **Multi-game Support** - Easily add new games
- **Bearer Token Auth** - Secure JWT-based authentication

## Database Schema

### Games
- Stores game metadata (slug, title, description, icon)
- Active flag for enabling/disabling games

### Achievements
- Game-specific achievements
- Points, icons, criteria (JSON)
- Linked to games via foreign key

### User Achievements
- Tracks unlocked achievements per user
- Progress tracking for partial completion
- Unlock timestamps

### Game Progress
- User's game state (JSON blob)
- Last synced timestamp
- Flexible schema for any game data

### Player Stats
- User statistics per game (JSON blob)
- Scores, playtime, wins, losses, etc.
- Updated in real-time

## API Endpoints

### Authentication
Base Framework provides built-in authentication:

```bash
# Register
POST /api/auth/register
{
  "email": "player@example.com",
  "password": "secure_password",
  "first_name": "John",
  "last_name": "Doe",
  "username": "johndoe"
}

# Login
POST /api/auth/login
{
  "email": "player@example.com",
  "password": "secure_password"
}

# Response includes:
{
  "token": "eyJhbGc...",
  "user": {...},
  "extend": {
    "user_id": 1,
    "role": {...},
    "achievement_count": 5
  }
}
```

### Multiplex Game Endpoints

All game endpoints require Bearer token authentication:
```
Authorization: Bearer <token>
```

#### Get Progress
```bash
GET /api/multiplex/progress

Response:
{
  "progress": {
    "id": 1,
    "user_id": 1,
    "game_id": 1,
    "data": "{\"level\": 5, \"score\": 1000}",
    "last_synced_at": "2025-01-16T12:00:00Z"
  }
}
```

#### Save Progress
```bash
POST /api/multiplex/progress
{
  "level": 10,
  "score": 5000,
  "lives": 3,
  "inventory": ["item1", "item2"]
}

Response:
{
  "progress": {...},
  "message": "Progress saved successfully"
}
```

#### List Achievements
```bash
GET /api/multiplex/achievements

Response:
{
  "achievements": [
    {
      "id": 1,
      "slug": "first-steps",
      "title": "First Steps",
      "description": "Complete your first level",
      "points": 10,
      "icon": "/static/icons/achievements/first-steps.png"
    }
  ],
  "user_achievements": [
    {
      "id": 1,
      "achievement_id": 1,
      "unlocked_at": "2025-01-16T12:00:00Z"
    }
  ]
}
```

#### Unlock Achievement
```bash
POST /api/multiplex/achievements/first-steps

Response:
{
  "achievement": {
    "id": 1,
    "user_id": 1,
    "achievement_id": 1,
    "unlocked_at": "2025-01-16T12:00:00Z",
    "achievement": {...}
  },
  "message": "Achievement unlocked successfully"
}
```

#### Get Player Stats
```bash
GET /api/multiplex/stats

Response:
{
  "stats": {
    "id": 1,
    "user_id": 1,
    "game_id": 1,
    "stats": "{\"score\": 10000, \"playtime\": 3600, \"wins\": 10}"
  }
}
```

#### Update Stats
```bash
POST /api/multiplex/stats
{
  "score": 15000,
  "playtime": 7200,
  "wins": 15,
  "losses": 2
}

Response:
{
  "stats": {...},
  "message": "Stats updated successfully"
}
```

#### Get Leaderboard
```bash
GET /api/multiplex/leaderboard?limit=10

Response:
{
  "leaderboard": [
    {
      "id": 1,
      "user_id": 1,
      "game_id": 1,
      "stats": "{\"score\": 50000}",
      "user": {
        "id": 1,
        "username": "player1",
        "email": "player1@example.com"
      }
    }
  ]
}
```

## Getting Started

### 1. Start the Server

```bash
# Using Docker Compose (recommended)
docker-compose up -d

# Or run locally with Go
go run main.go
```

### 2. Seed the Database

```bash
# Seed initial game data and achievements
go run main.go seed
```

This creates:
- Multiplex game entry
- 10 predefined achievements (First Steps, Speed Demon, etc.)

### 3. Test the API

```bash
# Health check
curl http://localhost:8100/health

# Register a user
curl -X POST http://localhost:8100/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "first_name": "Test",
    "last_name": "User",
    "username": "testuser"
  }'

# Login and get token
curl -X POST http://localhost:8100/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Use the token in subsequent requests
export TOKEN="<token_from_login>"

# Get progress
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8100/api/multiplex/progress
```

## Adding New Games

To add a new game to the platform:

### 1. Create Game Entry

Run the seed command or manually add to database:
```sql
INSERT INTO games (slug, title, description, icon, active)
VALUES ('new-game', 'New Game', 'Description', '/static/icons/new-game.png', true);
```

### 2. Create Game Module

```bash
mkdir -p app/newgame
```

### 3. Implement Module Structure

- `service.go` - Business logic for progress, achievements, stats
- `controller.go` - HTTP handlers
- `module.go` - Module registration

See `app/multiplex/` for reference implementation.

### 4. Register Module

Add to `app/init.go`:
```go
modules["newgame"] = newgame.NewModule(deps)
```

### 5. Create Achievements

Add achievements for your game in the seeder or via API.

## JWT Token Structure

The JWT token includes extended user context:

```json
{
  "user_id": 1,
  "role": {
    "id": 2,
    "name": "Member"
  },
  "achievement_count": 5,
  "exp": 1737101234,
  "iat": 1737014834
}
```

## CORS Configuration

Configured to allow game clients from:
- https://multiplex.base.al
- https://games.base.al
- http://localhost:3000 (development)

Update `.env`:
```
CORS_ALLOWED_ORIGINS=https://your-game.com,https://another-game.com
```

## Deployment

See [deployment.md](deployment.md) for full deployment guide.

### Quick Deploy

```bash
# 1. Clone repository
git clone <your-repo>
cd api

# 2. Configure environment
cp .env.production .env
# Edit .env with production values

# 3. Deploy with Docker Compose
docker-compose up -d --build

# 4. Seed database
docker exec games-api go run main.go seed
```

## Environment Variables

Key configuration in `.env`:

```bash
# Server
SERVER_PORT=8100
APPHOST=https://games-api.base.al

# Database
DB_DRIVER=mysql
DB_HOST=localhost
DB_PORT=3306
DB_USER=base_games
DB_PASSWORD=secure_password
DB_NAME=base_games

# Security
JWT_SECRET=your_super_secure_secret
API_KEY=your_secure_api_key

# Features
MIDDLEWARE_AUTH_ENABLED=true
MIDDLEWARE_CORS_ENABLED=true
```

## Technologies

- **Framework**: Base Framework (Go)
- **Database**: MySQL 8.0
- **Authentication**: JWT Bearer Tokens
- **ORM**: GORM
- **Deployment**: Docker + Docker Compose
- **Reverse Proxy**: Nginx (recommended)

## API Documentation

Swagger documentation available at:
```
http://localhost:8100/docs/index.html
```

## Security

- JWT-based authentication
- Password hashing with bcrypt
- CORS protection
- Rate limiting
- SQL injection protection (GORM)
- Input validation

## Performance

- Database indexing on user_id, game_id
- JSON fields for flexible data storage
- Connection pooling
- Caching headers for static assets

## Future Enhancements

- [ ] Real-time multiplayer with WebSockets
- [ ] Achievement notifications
- [ ] Friend system
- [ ] Social features (share achievements)
- [ ] Cross-game achievements
- [ ] Seasonal events
- [ ] Admin dashboard
- [ ] Analytics and insights

## Support

For issues or questions:
- GitHub Issues: <repository-url>
- Email: support@base.al
- Documentation: https://base.al/docs

## License

MIT License
