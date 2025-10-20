# Games API Implementation Summary

## What We Built

A **custom, dynamic games API** that works for ANY game without code changes.

## Architecture

### Current Structure
```
app/
├── models/           # Data models (Base Framework style)
│   ├── game.go
│   ├── achievement.go
│   ├── user_achievement.go
│   ├── game_progress.go
│   ├── player_stats.go
│   └── migrate.go
├── games/            # Single dynamic module
│   ├── controller.go  # Handles :game_slug routing
│   ├── service.go     # Business logic
│   └── module.go      # Registration
├── init.go           # Module loader
└── seeder.go         # Initial data seeder
```

### API Endpoints

All games use the same endpoints via dynamic `:game_slug`:

```
GET    /api/games/:game_slug/progress
POST   /api/games/:game_slug/progress
GET    /api/games/:game_slug/achievements
POST   /api/games/:game_slug/achievements/:slug
GET    /api/games/:game_slug/stats
POST   /api/games/:game_slug/stats
GET    /api/games/:game_slug/leaderboard
```

### Examples

**Multiplex:**
```bash
GET /api/games/multiplex/progress
GET /api/games/multiplex/achievements
```

**Future games (just add to database):**
```bash
GET /api/games/tetris/progress
GET /api/games/snake/achievements
GET /api/games/pong/stats
```

## Base CLI vs Custom Implementation

### Base CLI Standard Way

If we used `base g`:
```bash
base g game slug:string title:string ...
base g achievement game_id:uint slug:string ...
base g user_achievement user_id:uint achievement_id:uint ...
base g game_progress user_id:uint game_id:uint data:json ...
base g player_stats user_id:uint game_id:uint stats:json ...
```

**Would generate:**
- `/api/game` - List/Create games
- `/api/game/:id` - Get/Update/Delete game
- `/api/achievement` - List/Create achievements
- `/api/achievement/:id` - Get/Update/Delete achievement
- etc.

**Problem:** Not ideal for public game APIs. URL structure like `/api/achievement` doesn't relate achievements to specific games.

### Our Custom Approach

**Benefits:**
1. ✅ **Dynamic** - Add games to DB, no code changes
2. ✅ **RESTful** - `/api/games/multiplex/achievements` is clear
3. ✅ **Scalable** - One module handles all games
4. ✅ **Relational** - Game slug connects all resources
5. ✅ **Follows Base patterns** - Models use GORM, standard structure

**Trade-offs:**
- ❌ No auto-generated CRUD admin UI
- ✅ But better public API design

## Hybrid Solution (Future)

You can add Base CLI modules for admin management:

```bash
# Generate admin CRUD
base g game slug:string title:string description:text icon:string active:boolean
```

Results in:
- **Admin:** `/api/game` (full CRUD for managing games)
- **Public:** `/api/games/:game_slug/*` (game-specific endpoints)

## How to Add a New Game

### 1. Add to Database
```bash
# Via seeder or API
mysql> INSERT INTO games (slug, title, description, icon, active)
       VALUES ('tetris', 'Tetris', 'Classic puzzle game', '/static/tetris.png', true);
```

### 2. Add Achievements
```bash
mysql> INSERT INTO achievements (game_id, slug, title, description, points)
       VALUES (2, 'line-clear', 'Line Clear', 'Clear your first line', 10);
```

### 3. Done!

All endpoints work immediately:
```bash
GET  /api/games/tetris/progress
POST /api/games/tetris/progress
GET  /api/games/tetris/achievements
POST /api/games/tetris/achievements/line-clear
```

## Database Schema

### Games
```sql
CREATE TABLE games (
  id INT PRIMARY KEY AUTO_INCREMENT,
  slug VARCHAR(255) UNIQUE NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  icon VARCHAR(255),
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);
```

### Achievements
```sql
CREATE TABLE achievements (
  id INT PRIMARY KEY AUTO_INCREMENT,
  game_id INT NOT NULL,
  slug VARCHAR(255) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  points INT DEFAULT 0,
  icon VARCHAR(255),
  criteria JSON,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (game_id) REFERENCES games(id),
  INDEX (game_id, slug)
);
```

### User Achievements
```sql
CREATE TABLE user_achievements (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  achievement_id INT NOT NULL,
  progress JSON,
  unlocked_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (achievement_id) REFERENCES achievements(id),
  UNIQUE KEY (user_id, achievement_id)
);
```

### Game Progress
```sql
CREATE TABLE game_progress (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  game_id INT NOT NULL,
  data JSON,
  last_synced_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (game_id) REFERENCES games(id),
  UNIQUE KEY (user_id, game_id)
);
```

### Player Stats
```sql
CREATE TABLE player_stats (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  game_id INT NOT NULL,
  stats JSON,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (game_id) REFERENCES games(id),
  UNIQUE KEY (user_id, game_id)
);
```

## Usage Examples

### Get Progress
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8100/api/games/multiplex/progress
```

### Save Progress
```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"level": 10, "score": 5000}' \
  http://localhost:8100/api/games/multiplex/progress
```

### Unlock Achievement
```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:8100/api/games/multiplex/achievements/first-steps
```

### Update Stats
```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"score": 10000, "wins": 5}' \
  http://localhost:8100/api/games/multiplex/stats
```

## Deployment

See [deployment.md](deployment.md) for:
- Docker deployment
- Nginx configuration
- Production environment setup
- SSL/HTTPS configuration

## Seeding

```bash
# Seed initial data (Multiplex + 10 achievements)
go run main.go seed
```

## Testing

```bash
# Build
go build -o base-api .

# Run
./base-api

# Test endpoints
curl http://localhost:8100/health
curl http://localhost:8100/api/games/multiplex/progress -H "Authorization: Bearer <token>"
```

## Conclusion

Our implementation:
- ✅ Uses Base Framework patterns
- ✅ Follows GORM conventions
- ✅ Proper module structure
- ✅ Custom routing for better UX
- ✅ Scalable and maintainable
- ✅ Production-ready

The "Base way" is about following conventions and patterns, which we do. The custom routing is a **design choice** for better API design, not a deviation from Base principles.
