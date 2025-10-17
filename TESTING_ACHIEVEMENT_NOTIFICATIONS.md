# Testing Achievement Notifications

## Quick Test Guide

This guide shows you how to test the achievement notification system.

## Method 1: Play the Game Normally

The notifications will appear automatically when you unlock achievements:

1. **Start a new game**
2. **Place your first belt** → Should trigger "First Belt" achievement
3. **Place your first operator** → Should trigger "First Operator" achievement
4. **Process your first tile** → Should trigger "First Tile" achievement
5. **Complete a level** → May trigger level-based achievements

## Method 2: Manual Testing (Development)

You can manually trigger notifications for testing purposes.

### Add Test Button to Game Screen

Add this to your game screen for quick testing:

```dart
// In game_screen.dart, add a floating action button
floatingActionButton: FloatingActionButton(
  onPressed: _testNotification,
  child: Icon(Icons.emoji_events),
  tooltip: 'Test Achievement',
),

// Add this method
void _testNotification() {
  // Create a test achievement
  final testAchievement = Achievement(
    id: 999,
    gameId: 1,
    name: 'Test Achievement',
    title: 'Testing Master',
    description: 'You successfully tested the notification system!',
    slug: 'test-achievement',
    points: 100,
    category: 'special',
    criteria: {},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Show notification
  _notificationService.showAchievementUnlocked(testAchievement);
}
```

### Test Multiple Notifications

To test the queue system:

```dart
void _testMultipleNotifications() {
  final achievements = [
    Achievement(
      id: 1,
      gameId: 1,
      name: 'First Achievement',
      title: 'Getting Started',
      description: 'Place your first belt',
      slug: 'first-belt',
      points: 10,
      category: 'tutorial',
      criteria: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Achievement(
      id: 2,
      gameId: 1,
      name: 'Second Achievement',
      title: 'Progressing',
      description: 'Complete level 5',
      slug: 'level-5',
      points: 50,
      category: 'progress',
      criteria: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Achievement(
      id: 3,
      gameId: 1,
      name: 'Third Achievement',
      title: 'Master Builder',
      description: 'Place 100 belts',
      slug: 'master-builder',
      points: 100,
      category: 'collection',
      criteria: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // Show all notifications (they will queue)
  for (final achievement in achievements) {
    _notificationService.showAchievementUnlocked(achievement);
  }
}
```

## Method 3: Integration Testing

### Test with Real Achievement Data

1. **Set up achievements in your API** with low criteria:

```json
{
  "slug": "test-first-belt",
  "name": "Test: First Belt",
  "title": "Getting Started",
  "description": "Place your first conveyor belt",
  "points": 10,
  "category": "tutorial",
  "criteria": {
    "belts_placed": 1
  }
}
```

2. **Run the game** and perform the action (place a belt)

3. **Watch for notification** to appear at the top

### Check Achievement Tracking

Monitor console output:

```
AchievementTracker: Loaded 15 achievements, 0 unlocked
GameController: Stats synced to API
AchievementTracker: Checking achievements...
Achievement unlocked: Test: First Belt (+10 points)
NotificationService: Showing notification for Test: First Belt
```

## Expected Behavior

### Single Notification

1. Notification slides down from top with spring animation
2. Gold gradient background with glow effect
3. Shows achievement icon, title, description, and points
4. Glows with pulsing animation
5. Automatically dismisses after 4 seconds
6. Can be dismissed early by tapping

### Multiple Notifications

1. First notification appears immediately
2. Second notification waits for first to finish (4.5 seconds)
3. Each notification displays in sequence
4. Queue prevents notification spam

## Visual Checklist

- [ ] Notification slides down smoothly (spring curve)
- [ ] Gold gradient background is visible
- [ ] Glow effect pulses
- [ ] Achievement icon is appropriate for category
- [ ] Title is bold and prominent
- [ ] Description is readable
- [ ] Points badge shows correct value
- [ ] "ACHIEVEMENT UNLOCKED!" text is visible
- [ ] Auto-dismisses after 4 seconds
- [ ] Tapping dismisses immediately
- [ ] Multiple notifications queue properly

## Troubleshooting Tests

### Notification Not Appearing

Check:
1. Is NotificationService initialized? (Should see in console)
2. Is context available? (WidgetsBinding.instance.addPostFrameCallback)
3. Are there any errors in console?
4. Is the notification appearing off-screen? (Check MediaQuery.padding)

### Notification Appears But Looks Wrong

Check:
1. Achievement data is valid (not null values)
2. Theme is applied correctly
3. Screen size is adequate (test on different devices)

### Multiple Notifications Not Queuing

Check:
1. Queue system is working (add debug prints in NotificationService)
2. _isShowingNotification flag is being set correctly
3. _processQueue() is being called after each notification

## Performance Testing

Test notification performance:

```dart
void _testNotificationPerformance() async {
  final stopwatch = Stopwatch()..start();

  final testAchievement = Achievement(/* ... */);
  _notificationService.showAchievementUnlocked(testAchievement);

  stopwatch.stop();
  print('Notification display took: ${stopwatch.elapsedMilliseconds}ms');

  // Should be < 50ms for smooth gameplay
}
```

## Automated Testing

Create widget tests:

```dart
testWidgets('Achievement notification appears and dismisses', (tester) async {
  final achievement = Achievement(/* test data */);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AchievementNotification(
          achievement: achievement,
          onDismiss: () {},
        ),
      ),
    ),
  );

  // Verify notification is visible
  expect(find.text('ACHIEVEMENT UNLOCKED!'), findsOneWidget);
  expect(find.text(achievement.title), findsOneWidget);

  // Wait for auto-dismiss
  await tester.pumpAndSettle(Duration(seconds: 5));

  // Notification should be gone
  expect(find.text('ACHIEVEMENT UNLOCKED!'), findsNothing);
});
```

## Production Checklist

Before releasing:

- [ ] Test on multiple screen sizes (phone, tablet)
- [ ] Test with different achievement categories
- [ ] Test notification queue with 5+ achievements
- [ ] Test with screen reader (accessibility)
- [ ] Test with airplane mode (offline)
- [ ] Test notification persistence across screen rotations
- [ ] Verify no memory leaks (dispose properly)
- [ ] Test performance impact during gameplay
- [ ] Verify sound effects (if added)
- [ ] Check notification visibility on light/dark backgrounds

## Debug Mode

Enable debug mode in NotificationService:

```dart
// In notification_service.dart
static const bool debugMode = true;

void showAchievementUnlocked(Achievement achievement) {
  if (debugMode) {
    print('NotificationService: Showing ${achievement.title}');
    print('NotificationService: Queue size: ${_notificationQueue.length}');
  }
  // ... rest of implementation
}
```

## Common Issues and Solutions

### Issue: Notification appears but immediately disappears
**Solution**: Check that context is valid and mounted

### Issue: Multiple notifications stack on top of each other
**Solution**: Verify queue system is working, check _isShowingNotification flag

### Issue: Glow animation not visible
**Solution**: Check that _glowController is properly initialized and repeating

### Issue: Notification appears off-screen
**Solution**: Adjust MediaQuery.padding in Positioned widget

### Issue: Achievement icon not showing
**Solution**: Verify category mapping in _buildAchievementIcon()
