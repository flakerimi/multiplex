# Achievement Integration Summary

## Overview
Successfully integrated the achievement unlock system with game events in the Multiplex game. The system automatically tracks player statistics, checks achievement criteria, and unlocks achievements during gameplay with visual notifications.

## Files Created

### 1. AchievementTracker Service
**Location:** `/Users/flakerimismani/Games/Multiplexed/multiplex/lib/services/achievement_tracker.dart`

**Purpose:** Core service class to track and unlock achievements based on player stats.

**Key Features:**
- **Achievement Loading**: Loads all achievements and unlocked status from API
- **Criteria Checking**: Compares player stats against achievement criteria
- **Achievement Unlocking**: Calls API to unlock achievements when criteria are met
- **Event Emission**: Broadcasts achievement unlock events via Stream
- **Local Caching**: Maintains cache of achievements to avoid redundant API calls
- **Session Tracking**: Prevents duplicate unlocks in the same session
- **Batch Operations**: Supports unlocking multiple achievements efficiently

**Key Methods:**
```dart
Future<void> loadAchievements() // Load achievements from API
Future<List<Achievement>> checkAchievements(Map<String, dynamic> stats) // Check and unlock eligible achievements
Future<UserAchievement> unlockAchievement(String slug) // Unlock specific achievement
bool isUnlocked(int achievementId) // Check unlock status
```

## Files Modified

### 2. GameController Integration
**Location:** `/Users/flakerimismani/Games/Multiplexed/multiplex/lib/controllers/game_controller.dart`

**Changes:**
- Added `AchievementTracker` instance
- Added `initializeAchievements()` method to load achievements on startup
- Added `getCurrentStats()` method to export stats in API format
- Added `checkAchievements()` method called after stat updates
- Added `syncStatsToAPI()` method to sync stats to backend
- Added `updateStatsAndCheck()` convenience method that updates stats and checks achievements in one call
- Added `incrementStatAndCheck()` convenience method for incremental updates

**Stats Format:**
```dart
{
  'total_score': int,
  'tiles_processed': int,
  'belts_placed': int,
  'operators_placed': int,
  'extractors_placed': int,
  'levels_completed': int,
  'total_playtime_seconds': int,
  'max_level': int,
}
```

### 3. GameScreen Integration
**Location:** `/Users/flakerimismani/Games/Multiplexed/multiplex/lib/screens/game_screen.dart`

**Changes:**
- Added `GameController` instance
- Added `_initializeGame()` method to initialize achievements on screen load
- Added `_syncGameStatsToController()` method to sync Multiplex game stats to GameController
- Hooked up `onStatsChanged` callback from Multiplex game to trigger achievement checks
- Integrated auto-save functionality
- Updated save/load progress to use GameController

### 4. LevelManager Update
**Location:** `/Users/flakerimismani/Games/Multiplexed/multiplex/lib/game/managers/level_manager.dart`

**Changes:**
- Added `startNewGame()` method to reset to level 1

### 5. Achievement Model Update
**Location:** `/Users/flakerimismani/Games/Multiplexed/packages/games_api/lib/src/models/achievement.dart`

**Changes:**
- Added `criteria` field as `Map<String, dynamic>` to store achievement unlock criteria
- Updated `fromJson` to parse criteria from JSON string or Map

### 6. AchievementNotification Widget Fix
**Location:** `/Users/flakerimismani/Games/Multiplexed/multiplex/lib/widgets/achievement_notification.dart`

**Changes:**
- Changed `achievement.title` to `achievement.name` (correct field name)
- Removed dependency on non-existent `achievement.category` field
- Simplified icon display to use default trophy icon

## Achievement Criteria Checking

### How It Works

The `AchievementTracker._checkCriteria()` method evaluates achievement criteria against current player stats using an **AND logic** approach - all criteria must be met for an achievement to unlock.

### Criteria Format

Achievement criteria is stored as JSON in the database:
```json
{
  "belts_placed": 1,
  "total_score": 100
}
```

### Checking Logic

1. **Numeric Criteria**: Current stat value must be >= required value
   ```dart
   Example: {"total_score": 10000}
   Unlocks when: stats['total_score'] >= 10000
   ```

2. **String Criteria**: Exact match required
   ```dart
   Example: {"difficulty": "hard"}
   Unlocks when: stats['difficulty'] == "hard"
   ```

3. **Boolean Criteria**: Exact match required
   ```dart
   Example: {"tutorial_completed": true}
   Unlocks when: stats['tutorial_completed'] == true
   ```

4. **Multiple Criteria**: All must be satisfied (AND logic)
   ```dart
   Example: {
     "levels_completed": 10,
     "total_score": 5000,
     "belts_placed": 50
   }
   Unlocks when: ALL three conditions are met
   ```

### Example Criteria Scenarios

#### Scenario 1: First Belt
```json
Achievement: "First Steps"
Criteria: {"belts_placed": 1}
```
- Unlocks: When player places their first belt
- Check: `stats.belts_placed >= 1`

#### Scenario 2: Score Master
```json
Achievement: "High Scorer"
Criteria: {"total_score": 10000}
```
- Unlocks: When total score reaches 10,000
- Check: `stats.total_score >= 10000`

#### Scenario 3: Level Complete
```json
Achievement: "Level 5 Champion"
Criteria: {"max_level": 5}
```
- Unlocks: When player reaches level 5
- Check: `stats.max_level >= 5`

#### Scenario 4: Multi-Criteria Achievement
```json
Achievement: "Efficient Engineer"
Criteria: {
  "levels_completed": 10,
  "belts_placed": 100,
  "total_score": 5000
}
```
- Unlocks: When player has:
  - Completed at least 10 levels AND
  - Placed at least 100 belts AND
  - Scored at least 5,000 points
- Check: All three conditions must be true

#### Scenario 5: Speedrun Achievement
```json
Achievement: "Speed Demon"
Criteria: {
  "levels_completed": 5,
  "total_playtime_seconds": 300
}
```
- Unlocks: When player completes 5 levels in under 5 minutes
- Note: The checking logic would need custom handling for "less than" scenarios
- Current implementation uses >=, so this would need adjustment

## Game Flow

### Initialization Sequence

1. **Screen Load** (`GameScreen.initState()`)
   - Create/Get `GameController`
   - Set up game callbacks (`onStatsChanged`, `onLevelChanged`)
   - Initialize notification service

2. **Post-Frame Callback** (`_initializeGame()`)
   - Initialize achievements via `GameController.initializeAchievements()`
     - Loads all achievements from API
     - Loads unlocked achievement IDs
   - Sync initial game stats to controller
   - Start auto-save timer

### Runtime Achievement Checking

**Trigger Points:**
1. After placing belt/operator/extractor
2. After delivering tile to factory (score increase)
3. After completing level
4. Any stat change in Multiplex game

**Flow:**
```
Game Event → Stats Change → onStatsChanged callback
  → _syncGameStatsToController()
    → GameController.updateStatsAndCheck()
      → Update controller stats
      → GameController.checkAchievements()
        → AchievementTracker.checkAchievements(stats)
          → Check each unlockable achievement
          → If criteria met: unlockAchievement(slug)
            → API call to unlock
            → Update local cache
            → Emit unlock event
            → Show notification
          → Sync stats to API
```

### Notification Display

When achievement is unlocked:
1. `AchievementTracker` emits event via Stream
2. `NotificationService.showAchievementUnlocked()` called
3. Animated notification slides down from top
4. Shows achievement name, description, points
5. Auto-dismisses after 4 seconds
6. Queues multiple achievements if unlocked simultaneously

## Optimization Strategies

### 1. Cache Management
- Achievements loaded once per session
- Unlocked achievement IDs stored in Set for O(1) lookup
- Only checks unlockable achievements (not already unlocked)

### 2. Session Tracking
- Tracks achievements unlocked in current session
- Prevents duplicate unlock attempts
- Reduces API calls

### 3. Batch Operations
- `unlockAchievements()` method supports batch unlocking
- Continues even if individual unlock fails
- Reduces network overhead

### 4. Async Achievement Checks
- Achievement checking runs asynchronously
- Doesn't block game updates
- Errors logged but don't crash game

### 5. Lazy Initialization
- Achievements loaded after screen renders
- Game playable even if achievement loading fails
- Graceful degradation

## Testing Recommendations

### Manual Testing

1. **First Belt Achievement**
   - Start new game
   - Place first belt
   - Verify achievement unlocks and notification shows

2. **Score Achievement**
   - Play until reaching score threshold
   - Verify unlock at correct score value

3. **Multi-Criteria Achievement**
   - Track multiple stats
   - Verify unlocks only when ALL criteria met

4. **Duplicate Prevention**
   - Unlock achievement
   - Continue playing
   - Verify no duplicate unlock for same achievement

5. **Offline Behavior**
   - Disconnect network
   - Play game and trigger achievement
   - Verify graceful error handling

### Example Achievement Data

Create these achievements in the API for testing:

```sql
-- First belt placed
INSERT INTO achievements (game_id, name, description, slug, points, criteria) VALUES
(1, 'First Steps', 'Place your first conveyor belt', 'first-steps', 10, '{"belts_placed": 1}');

-- Score milestone
INSERT INTO achievements (game_id, name, description, slug, points, criteria) VALUES
(1, 'Score Master', 'Reach 10,000 points', 'score-master', 50, '{"total_score": 10000}');

-- Level progression
INSERT INTO achievements (game_id, name, description, slug, points, criteria) VALUES
(1, 'Level 5 Champion', 'Complete level 5', 'level-5', 25, '{"max_level": 5}');

-- Multi-criteria
INSERT INTO achievements (game_id, name, description, slug, points, criteria) VALUES
(1, 'Efficient Engineer', 'Complete 10 levels with 100 belts', 'efficient-engineer', 100,
'{"levels_completed": 10, "belts_placed": 100}');

-- Tile processing
INSERT INTO achievements (game_id, name, description, slug, points, criteria) VALUES
(1, 'Production Line', 'Process 100 tiles', 'production-line', 30, '{"tiles_processed": 100}');
```

## Integration Points

### Stats Updated From Multiplex Game

The following stats are tracked and synced to the achievement system:

- `total_score` - Increases when correct tiles delivered to factory
- `tiles_processed` - Increments each time factory accepts a tile
- `belts_placed` - Increments when belt placed via input manager
- `operators_placed` - Increments when operator placed
- `extractors_placed` - Increments when extractor placed
- `levels_completed` - Increments when level target reached
- `max_level` - Current level number (1-indexed)
- `total_playtime_seconds` - Total time played across all sessions

### Callback Hooks in Multiplex Game

```dart
// In Multiplex class
VoidCallback? onStatsChanged;  // Called after any stat update
VoidCallback? onLevelChanged;  // Called when level changes

// In InputManager
VoidCallback? onBeltPlaced;
VoidCallback? onOperatorPlaced;
VoidCallback? onExtractorPlaced;
```

## Error Handling

### Graceful Degradation
- Game continues to function even if achievement system fails
- Achievement check errors are logged but not thrown
- API failures don't block gameplay

### Fallback Behavior
- If achievements fail to load: game plays normally, no achievements tracked
- If unlock fails: error logged, game continues
- If notification service unavailable: unlock still recorded in backend

## Future Enhancements

1. **Progress Tracking**: Add partial progress display for multi-step achievements
2. **Custom Icons**: Use achievement.icon field to load custom images
3. **Sound Effects**: Play sound when achievement unlocks
4. **Achievement Categories**: Group achievements by type (beginner, expert, hidden)
5. **Comparison Operators**: Support < and == for more flexible criteria
6. **Rarity Tiers**: Different notification styles for rare achievements
7. **Achievement History**: Show recently unlocked achievements
8. **Social Sharing**: Share achievement unlocks

## API Endpoints Used

- `GET /games/{slug}/achievements` - Load all achievements and unlocked status
- `POST /games/{slug}/achievements/{achievement_slug}` - Unlock achievement
- `POST /games/{slug}/stats` - Sync player stats to backend
- `GET /games/{slug}/progress` - Load game progress
- `POST /games/{slug}/progress` - Save game progress

## Summary

The achievement system is now fully integrated with the Multiplex game. Achievements are checked automatically after every stat update, unlocked via API when criteria are met, and displayed with animated notifications. The system is optimized to minimize API calls, prevent duplicate unlocks, and gracefully handle errors without disrupting gameplay.
