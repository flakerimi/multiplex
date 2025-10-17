# Achievement Notification System

## Overview

The achievement notification system displays animated overlay notifications when players unlock achievements. The system is fully integrated with the game controller and achievement tracker.

## Architecture

### Components

1. **AchievementNotification Widget** (`lib/widgets/achievement_notification.dart`)
   - Animated notification card that slides in from the top
   - Shows achievement icon, title, description, and points
   - Gold gradient background with glow effect
   - Auto-dismisses after 4 seconds
   - Tappable to dismiss early

2. **NotificationService** (`lib/services/notification_service.dart`)
   - Singleton service managing notification display
   - Queue system for multiple achievements
   - Overlay-based rendering (appears on top of game)
   - Non-intrusive to gameplay

3. **AchievementTracker** (`lib/services/achievement_tracker.dart`)
   - Tracks player stats against achievement criteria
   - Automatically unlocks achievements via API
   - Triggers notifications when achievements unlock
   - Maintains cache of unlocked achievements

## How It Works

### Flow

1. Player performs action (e.g., places a belt)
2. GameController updates stats via `incrementStatAndCheck()`
3. AchievementTracker checks if stats meet any achievement criteria
4. If criteria met, AchievementTracker calls API to unlock achievement
5. AchievementTracker calls NotificationService to show notification
6. NotificationService displays animated overlay with achievement details
7. Notification auto-dismisses after 4 seconds (or user taps to dismiss)

### Integration Points

The system is already integrated in `GameController`:

```dart
// Example: When player places a belt
await gameController.incrementStatAndCheck('belts_placed', 1);

// Example: When player completes a level
await gameController.updateStatsAndCheck(
  levelsCompleted: gameController.levelsCompleted.value + 1,
  totalScore: gameController.totalScore.value + bonusPoints,
);
```

## Usage

### 1. Initialize in Game Screen

The NotificationService is automatically initialized in `GameScreen`:

```dart
class _GameScreenState extends State<GameScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();

    // Initialize notification service with context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.initialize(context);
    });
  }
}
```

### 2. Initialize Achievements in GameController

```dart
// In your game initialization
final gameController = Get.put(GameController());
await gameController.initializeAchievements();
```

### 3. Track Player Actions

Update stats after player actions:

```dart
// Single stat increment
await gameController.incrementStatAndCheck('tilesProcessed', 1);

// Multiple stats update
await gameController.updateStatsAndCheck(
  currentLevel: 5,
  totalScore: 1000,
  levelsCompleted: 4,
);
```

### 4. Manual Achievement Check

To manually check achievements:

```dart
await gameController.checkAchievements();
```

## Customization

### Modify Notification Appearance

Edit `lib/widgets/achievement_notification.dart`:

- **Colors**: Change gradient in `Container.decoration`
- **Duration**: Modify auto-dismiss timer in `initState()`
- **Animation**: Adjust `_slideController` and `_glowController` parameters
- **Icons**: Update `_buildAchievementIcon()` mapping

### Modify Notification Behavior

Edit `lib/services/notification_service.dart`:

- **Queue Delay**: Change delay between notifications in `_processQueue()`
- **Position**: Update `Positioned` widget in `_showNotification()`
- **Overlay Duration**: Modify timeout in `_showNotification()`

## Animation Details

### Entry Animation
- **Type**: Slide down from top
- **Curve**: Elastic out (spring effect)
- **Duration**: 500ms

### Glow Effect
- **Type**: Continuous pulse
- **Duration**: 1500ms per cycle
- **Effect**: Opacity oscillates between 0.3 and 1.0

### Exit Animation
- **Type**: Slide up and fade
- **Duration**: Automatic (reverse of entry)

## Features

- **Non-intrusive**: Appears as overlay, doesn't block gameplay
- **Queue System**: Multiple achievements show sequentially
- **Smooth Animations**: Spring entrance with glow effect
- **Auto-dismiss**: Automatically removes after 4 seconds
- **Manual Dismiss**: Tap anywhere on notification to dismiss
- **Accessibility**: Screen reader support via Semantic widgets
- **Category Icons**: Different icons for different achievement types

## Achievement Categories

The notification displays different icons based on achievement category:

- **exploration**: Explore icon
- **combat**: Military tech icon
- **social**: People icon
- **collection**: Collections icon
- **mastery**: Star icon
- **progression**: Trending up icon
- **special**: Celebration icon
- **default**: Trophy icon

## Example Achievement Definitions

Achievements in the API should follow this format:

```json
{
  "slug": "first-belt",
  "name": "Getting Started",
  "description": "Place your first conveyor belt",
  "points": 10,
  "category": "tutorial",
  "criteria": {
    "belts_placed": 1
  }
}
```

The AchievementTracker will automatically check if `stats['belts_placed'] >= 1`.

## Debugging

Enable debug output by checking console logs:

```
AchievementTracker: Loaded 15 achievements, 3 unlocked
GameController: Stats synced to API
Achievement unlocked: First Steps (+10 points)
```

## API Integration

The system uses the following API endpoints:

- `GET /games/{gameSlug}/achievements` - Load all achievements
- `POST /games/{gameSlug}/achievements/{slug}/unlock` - Unlock achievement
- `POST /games/{gameSlug}/stats` - Update player stats

## Performance Considerations

- Notifications use overlay system (efficient rendering)
- Achievement checks happen only after stat updates (not every frame)
- Achievements are cached locally to reduce API calls
- Queue system prevents notification spam

## Future Enhancements

Potential improvements:

1. Sound effects when achievement unlocks
2. Confetti particle system
3. Achievement unlock history
4. Notification customization (position, size, style)
5. Achievement progress tracking (show percentage)
6. Secret achievements (hidden until unlocked)

## Troubleshooting

### Notifications Not Showing

1. Check that NotificationService is initialized with context
2. Verify achievement criteria matches stat keys exactly
3. Check console for errors
4. Ensure GameController.initializeAchievements() was called

### Duplicate Notifications

- AchievementTracker prevents duplicates per session
- Check that stats aren't being incremented multiple times

### API Errors

- Verify API client configuration in GameController
- Check network connectivity
- Review API endpoint responses in console
