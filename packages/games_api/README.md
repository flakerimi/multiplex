# Games API

Flutter package for integrating with games-api.base.al

## Features

- User authentication (register, login, logout)
- Secure token storage
- Game progress sync
- Achievements tracking
- Player statistics
- Leaderboards

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  games_api:
    path: ../packages/games_api
```

## Usage

### Initialize

```dart
import 'package:games_api/games_api.dart';

// Development
final api = GamesApiClient.development();

// Production
final api = GamesApiClient.production();
```

### Authentication

```dart
// Register
final response = await api.auth.register(
  RegisterRequest(
    email: 'player@example.com',
    password: 'securePassword123',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
  ),
);

// Login
final response = await api.auth.login(
  LoginRequest(
    email: 'player@example.com',
    password: 'securePassword123',
  ),
);

// Check authentication
final isAuth = await api.auth.isAuthenticated();

// Get current user
final user = await api.auth.getUser();

// Logout
await api.auth.logout();
```

### User Information

```dart
// Access user data
print(response.user.fullName);
print(response.user.email);

// Access extended JWT data
print(response.achievementCount);
print(response.role);
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user

### Games (Coming Soon)
- `GET /api/games/:slug/progress` - Get progress
- `POST /api/games/:slug/progress` - Save progress
- `GET /api/games/:slug/achievements` - List achievements
- `POST /api/games/:slug/achievements/:slug` - Unlock achievement
- `GET /api/games/:slug/stats` - Get stats
- `POST /api/games/:slug/stats` - Update stats
- `GET /api/games/:slug/leaderboard` - Get leaderboard

## Development

```bash
# From package directory
flutter pub get
flutter analyze
flutter test
```

## License

MIT
