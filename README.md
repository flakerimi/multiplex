# Multiplexed - Monorepo

A unified repository containing the Multiplex game ecosystem.

## Repository Structure

```
Multiplexed/
├── api/                  # Go backend API (Base Framework)
├── multiplex/            # Flutter game client
├── packages/             # Shared packages
│   └── games_api/        # Dart API client library
├── progress.md           # Development progress tracking
└── README.md            # This file
```

## Projects

### 🎮 Multiplex (Flutter Game)
**Location**: `multiplex/`

The main game client built with Flutter and Flame game engine. Features:
- Factory automation puzzle game
- Conveyor belts, operators, and number processing
- Achievement system and leaderboards
- Cross-platform (macOS, iOS, Android, Web)

**Tech Stack**: Flutter, Flame, GetX

**Run Game**:
```bash
cd multiplex
flutter run -d macos
```

### 🚀 API (Go Backend)
**Location**: `api/`

RESTful API built with Base Framework. Provides:
- User authentication and authorization
- Game progress persistence
- Player statistics and achievements
- Leaderboard system

**Tech Stack**: Go, Base Framework, PostgreSQL

**Run API**:
```bash
cd api
./base-api serve
```

### 📦 Packages
**Location**: `packages/`

Shared packages used across projects:
- `games_api/` - Dart client library for API communication

## Development Workflow

### Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd Multiplexed

# Setup API
cd api
cp .env.sample .env
# Edit .env with your database credentials
./base-api migrate
./base-api seed

# Setup Multiplex
cd ../multiplex
flutter pub get
flutter run -d macos
```

### Working on Multiple Projects

This monorepo structure allows you to:
- Make cross-project changes in a single commit
- Share code via packages directory
- Maintain consistent versioning
- Track related changes together

### Git Workflow

```bash
# Work from root directory
cd /Users/flakerimismani/Games/Multiplexed

# See all changes across projects
git status

# Commit changes affecting multiple projects
git add api/core/app/games/ multiplex/lib/controllers/
git commit -m "Add new achievement system to API and game"

# Push all changes
git push origin main
```

## Recent Changes

See [progress.md](./progress.md) for detailed development progress.

Latest updates:
- Monorepo restructure (moved .git to root)
- Operator system improvements with 3-tile layout
- Rotation support for operators
- Color-coded operator types
- Cursor preview positioning fixes

## Documentation

- **API Documentation**: `api/README.md`
- **Game Documentation**: `multiplex/README.md`
- **Progress Tracking**: `progress.md`
- **API Integration**: `api/GAMES_API.md`

## Building for Production

### API
```bash
cd api
docker build -t multiplex-api .
docker run -p 8080:8080 multiplex-api
```

### Game
```bash
cd multiplex
flutter build macos
flutter build web
flutter build apk
```

## Contributing

When making changes:
1. Work from the root directory for cross-project changes
2. Update relevant documentation in project directories
3. Run tests before committing
4. Update progress.md for significant features

## License

[Add license information]

## Contact

[Add contact information]
