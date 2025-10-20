package games

import (
	"base/app/models"
	"base/core/app/profile"
	"base/core/emitter"
	"base/core/logger"
	"encoding/json"
	"errors"
	"time"

	"gorm.io/gorm"
)

type Service struct {
	DB      *gorm.DB
	Emitter *emitter.Emitter
	Logger  logger.Logger
}

// GetProgress retrieves the game progress for a user
func (s *Service) GetProgress(userId uint, gameSlug string) (*models.GameProgress, error) {
	var progress models.GameProgress
	var game models.Game

	// Find the game by slug
	if err := s.DB.Where("slug = ?", gameSlug).First(&game).Error; err != nil {
		return nil, errors.New("game not found")
	}

	// Find or create progress
	err := s.DB.Where("user_id = ? AND game_id = ?", userId, game.Id).First(&progress).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Create new progress with empty data
			progress = models.GameProgress{
				UserId:       userId,
				GameId:       game.Id,
				Data:         "{}",
				LastSyncedAt: time.Now(),
			}
			if err := s.DB.Create(&progress).Error; err != nil {
				return nil, err
			}
		} else {
			return nil, err
		}
	}

	return &progress, nil
}

// SaveProgress saves the game progress for a user
func (s *Service) SaveProgress(userId uint, gameSlug string, data map[string]interface{}) (*models.GameProgress, error) {
	var game models.Game

	// Find the game by slug
	if err := s.DB.Where("slug = ?", gameSlug).First(&game).Error; err != nil {
		return nil, errors.New("game not found")
	}

	// Convert data to JSON
	dataJSON, err := json.Marshal(data)
	if err != nil {
		return nil, errors.New("invalid data format")
	}

	var progress models.GameProgress
	err = s.DB.Where("user_id = ? AND game_id = ?", userId, game.Id).First(&progress).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Create new progress
			progress = models.GameProgress{
				UserId:       userId,
				GameId:       game.Id,
				Data:         string(dataJSON),
				LastSyncedAt: time.Now(),
			}
			if err := s.DB.Create(&progress).Error; err != nil {
				return nil, err
			}
		} else {
			return nil, err
		}
	} else {
		// Update existing progress
		progress.Data = string(dataJSON)
		progress.LastSyncedAt = time.Now()
		if err := s.DB.Save(&progress).Error; err != nil {
			return nil, err
		}
	}

	s.Emitter.Emit("games.progress.saved", &progress)
	return &progress, nil
}

// GetAchievements retrieves available achievements for a game
func (s *Service) GetAchievements(gameSlug string) ([]models.Achievement, error) {
	var game models.Game
	var achievements []models.Achievement

	// Find the game by slug
	if err := s.DB.Where("slug = ?", gameSlug).First(&game).Error; err != nil {
		return nil, errors.New("game not found")
	}

	if err := s.DB.Where("game_id = ?", game.Id).Find(&achievements).Error; err != nil {
		return nil, err
	}

	return achievements, nil
}

// GetUserAchievements retrieves unlocked achievements for a user
func (s *Service) GetUserAchievements(userId uint, gameSlug string) ([]models.UserAchievement, error) {
	var game models.Game
	var achievements []models.Achievement
	var userAchievements []models.UserAchievement

	// Find the game by slug
	if err := s.DB.Where("slug = ?", gameSlug).First(&game).Error; err != nil {
		return nil, errors.New("game not found")
	}

	// Get all game achievements
	if err := s.DB.Where("game_id = ?", game.Id).Find(&achievements).Error; err != nil {
		return nil, err
	}

	// Get user's unlocked achievements
	achievementIds := make([]uint, len(achievements))
	for i, ach := range achievements {
		achievementIds[i] = ach.Id
	}

	if err := s.DB.Preload("Achievement").Where("user_id = ? AND achievement_id IN ?", userId, achievementIds).Find(&userAchievements).Error; err != nil {
		return nil, err
	}

	return userAchievements, nil
}

// UnlockAchievement unlocks an achievement for a user
func (s *Service) UnlockAchievement(userId uint, gameSlug string, achievementSlug string) (*models.UserAchievement, error) {
	var game models.Game
	var achievement models.Achievement

	// Find the game by slug
	if err := s.DB.Where("slug = ?", gameSlug).First(&game).Error; err != nil {
		return nil, errors.New("game not found")
	}

	// Find the achievement
	if err := s.DB.Where("game_id = ? AND slug = ?", game.Id, achievementSlug).First(&achievement).Error; err != nil {
		return nil, errors.New("achievement not found")
	}

	// Check if already unlocked
	var existing models.UserAchievement
	err := s.DB.Where("user_id = ? AND achievement_id = ?", userId, achievement.Id).First(&existing).Error
	if err == nil {
		return &existing, nil // Already unlocked
	}

	// Unlock achievement
	now := time.Now()
	userAchievement := models.UserAchievement{
		UserId:        userId,
		AchievementId: achievement.Id,
		UnlockedAt:    &now,
		Progress:      "{}",
	}

	if err := s.DB.Create(&userAchievement).Error; err != nil {
		return nil, err
	}

	// Preload the achievement details
	s.DB.Preload("Achievement").First(&userAchievement, userAchievement.Id)

	s.Emitter.Emit("games.achievement.unlocked", &userAchievement)
	return &userAchievement, nil
}

// GetStats retrieves player stats
func (s *Service) GetStats(userId uint, gameSlug string) (*models.PlayerStats, error) {
	var game models.Game
	var stats models.PlayerStats

	// Find the game by slug
	if err := s.DB.Where("slug = ?", gameSlug).First(&game).Error; err != nil {
		return nil, errors.New("game not found")
	}

	// Find or create stats
	err := s.DB.Where("user_id = ? AND game_id = ?", userId, game.Id).First(&stats).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Create new stats with empty data
			stats = models.PlayerStats{
				UserId: userId,
				GameId: game.Id,
				Stats:  "{}",
			}
			if err := s.DB.Create(&stats).Error; err != nil {
				return nil, err
			}
		} else {
			return nil, err
		}
	}

	return &stats, nil
}

// UpdateStats updates player stats
func (s *Service) UpdateStats(userId uint, gameSlug string, statsData map[string]interface{}) (*models.PlayerStats, error) {
	var game models.Game

	// Find the game by slug
	if err := s.DB.Where("slug = ?", gameSlug).First(&game).Error; err != nil {
		return nil, errors.New("game not found")
	}

	// Convert stats to JSON
	statsJSON, err := json.Marshal(statsData)
	if err != nil {
		return nil, errors.New("invalid stats format")
	}

	var stats models.PlayerStats
	err = s.DB.Where("user_id = ? AND game_id = ?", userId, game.Id).First(&stats).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Create new stats
			stats = models.PlayerStats{
				UserId: userId,
				GameId: game.Id,
				Stats:  string(statsJSON),
			}
			if err := s.DB.Create(&stats).Error; err != nil {
				return nil, err
			}
		} else {
			return nil, err
		}
	} else {
		// Update existing stats
		stats.Stats = string(statsJSON)
		if err := s.DB.Save(&stats).Error; err != nil {
			return nil, err
		}
	}

	s.Emitter.Emit("games.stats.updated", &stats)
	return &stats, nil
}

// GetLeaderboard retrieves top players by a specific stat
func (s *Service) GetLeaderboard(gameSlug string, limit int) ([]models.PlayerStats, error) {
	var game models.Game
	var stats []models.PlayerStats

	// Find the game by slug
	if err := s.DB.Where("slug = ?", gameSlug).First(&game).Error; err != nil {
		return nil, errors.New("game not found")
	}

	// Get top players (you may want to sort by a specific stat in the JSON)
	if err := s.DB.Preload("User").Where("game_id = ?", game.Id).Limit(limit).Order("updated_at DESC").Find(&stats).Error; err != nil {
		return nil, err
	}

	return stats, nil
}

// PlayerProfile represents a complete player profile
type PlayerProfile struct {
	User         *profile.User             `json:"user"`
	Stats        *models.PlayerStats       `json:"stats"`
	Progress     *models.GameProgress      `json:"progress"`
	Achievements []models.UserAchievement  `json:"unlocked_achievements"`
	TotalAchievements int                  `json:"total_achievements"`
	AchievementPoints int                  `json:"achievement_points"`
}

// GetPlayerProfile retrieves complete player profile
func (s *Service) GetPlayerProfile(userId uint, gameSlug string) (*PlayerProfile, error) {
	var game models.Game
	var user profile.User

	// Find the game by slug
	if err := s.DB.Where("slug = ?", gameSlug).First(&game).Error; err != nil {
		return nil, errors.New("game not found")
	}

	// Get user
	if err := s.DB.First(&user, userId).Error; err != nil {
		return nil, errors.New("user not found")
	}

	// Get stats
	stats, err := s.GetStats(userId, gameSlug)
	if err != nil {
		return nil, err
	}

	// Get progress
	progress, err := s.GetProgress(userId, gameSlug)
	if err != nil {
		return nil, err
	}

	// Get unlocked achievements
	userAchievements, err := s.GetUserAchievements(userId, gameSlug)
	if err != nil {
		return nil, err
	}

	// Calculate total achievements and points
	var totalAchievements int64
	s.DB.Model(&models.Achievement{}).Where("game_id = ?", game.Id).Count(&totalAchievements)

	achievementPoints := 0
	for _, ua := range userAchievements {
		if ua.Achievement != nil {
			achievementPoints += ua.Achievement.Points
		}
	}

	profile := &PlayerProfile{
		User:              &user,
		Stats:             stats,
		Progress:          progress,
		Achievements:      userAchievements,
		TotalAchievements: int(totalAchievements),
		AchievementPoints: achievementPoints,
	}

	return profile, nil
}
