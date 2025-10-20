package app

import (
	"base/app/models"
	"encoding/json"
	"log"

	"gorm.io/gorm"
)

// SeedGamesData seeds initial game data including Multiplex game and achievements
func SeedGamesData(db *gorm.DB) error {
	// Check if Multiplex game already exists
	var existingGame models.Game
	if err := db.Where("slug = ?", "multiplex").First(&existingGame).Error; err == nil {
		log.Println("Multiplex game already exists, skipping seed")
		return nil
	}

	// Create Multiplex game
	multiplexGame := models.Game{
		Slug:        "multiplex",
		Title:       "Multiplex",
		Description: "A challenging puzzle game where you manage multiple tasks simultaneously",
		Icon:        "/static/icons/multiplex.png",
		Active:      true,
	}

	if err := db.Create(&multiplexGame).Error; err != nil {
		log.Printf("Failed to create Multiplex game: %v", err)
		return err
	}

	log.Println("Created Multiplex game successfully")

	// Create achievements for Multiplex
	achievements := []models.Achievement{
		// Tutorial Achievements
		{
			GameId:      multiplexGame.Id,
			Slug:        "first-belt",
			Title:       "First Belt",
			Description: "Place your first conveyor belt",
			Points:      5,
			Icon:        "/static/icons/achievements/first-belt.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"belts_placed": 1}),
		},
		{
			GameId:      multiplexGame.Id,
			Slug:        "first-operator",
			Title:       "Operator Novice",
			Description: "Create your first operator",
			Points:      10,
			Icon:        "/static/icons/achievements/first-operator.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"operators_placed": 1}),
		},
		{
			GameId:      multiplexGame.Id,
			Slug:        "first-tile",
			Title:       "Production Line",
			Description: "Process your first tile",
			Points:      5,
			Icon:        "/static/icons/achievements/first-tile.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"tiles_processed": 1}),
		},
		{
			GameId:      multiplexGame.Id,
			Slug:        "first-level",
			Title:       "First Steps",
			Description: "Complete your first level",
			Points:      10,
			Icon:        "/static/icons/achievements/first-level.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"levels_completed": 1}),
		},
		// Progress Achievements
		{
			GameId:      multiplexGame.Id,
			Slug:        "factory-starter",
			Title:       "Factory Starter",
			Description: "Reach level 5",
			Points:      25,
			Icon:        "/static/icons/achievements/factory-starter.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"max_level": 5}),
		},
		{
			GameId:      multiplexGame.Id,
			Slug:        "factory-expert",
			Title:       "Factory Expert",
			Description: "Reach level 10",
			Points:      50,
			Icon:        "/static/icons/achievements/factory-expert.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"max_level": 10}),
		},
		{
			GameId:      multiplexGame.Id,
			Slug:        "factory-master",
			Title:       "Factory Master",
			Description: "Reach level 25",
			Points:      150,
			Icon:        "/static/icons/achievements/factory-master.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"max_level": 25}),
		},
		{
			GameId:      multiplexGame.Id,
			Slug:        "production-king",
			Title:       "Production King",
			Description: "Process 1000 tiles",
			Points:      100,
			Icon:        "/static/icons/achievements/production-king.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"tiles_processed": 1000}),
		},
		// Skill Achievements
		{
			GameId:      multiplexGame.Id,
			Slug:        "speed-demon",
			Title:       "Speed Demon",
			Description: "Complete a level in under 60 seconds",
			Points:      50,
			Icon:        "/static/icons/achievements/speed-demon.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"level_time_seconds": 60}),
		},
		{
			GameId:      multiplexGame.Id,
			Slug:        "efficient-engineer",
			Title:       "Efficient Engineer",
			Description: "Complete a level with less than 10 belts",
			Points:      75,
			Icon:        "/static/icons/achievements/efficient-engineer.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"max_belts_in_level": 10}),
		},
		{
			GameId:      multiplexGame.Id,
			Slug:        "perfectionist",
			Title:       "Perfectionist",
			Description: "Complete 10 levels without mistakes",
			Points:      100,
			Icon:        "/static/icons/achievements/perfectionist.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"perfect_levels": 10}),
		},
		// Collection Achievements
		{
			GameId:      multiplexGame.Id,
			Slug:        "belt-master",
			Title:       "Belt Master",
			Description: "Place 100 conveyor belts",
			Points:      50,
			Icon:        "/static/icons/achievements/belt-master.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"belts_placed": 100}),
		},
		{
			GameId:      multiplexGame.Id,
			Slug:        "operator-master",
			Title:       "Operator Master",
			Description: "Place 50 operators",
			Points:      75,
			Icon:        "/static/icons/achievements/operator-master.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"operators_placed": 50}),
		},
		{
			GameId:      multiplexGame.Id,
			Slug:        "extractor-expert",
			Title:       "Extractor Expert",
			Description: "Place 25 extractors",
			Points:      60,
			Icon:        "/static/icons/achievements/extractor-expert.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"extractors_placed": 25}),
		},
		// Score Achievements
		{
			GameId:      multiplexGame.Id,
			Slug:        "high-scorer",
			Title:       "High Scorer",
			Description: "Reach a score of 10,000 points",
			Points:      100,
			Icon:        "/static/icons/achievements/high-scorer.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"total_score": 10000}),
		},
		{
			GameId:      multiplexGame.Id,
			Slug:        "score-legend",
			Title:       "Score Legend",
			Description: "Reach a score of 50,000 points",
			Points:      250,
			Icon:        "/static/icons/achievements/score-legend.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"total_score": 50000}),
		},
		// Time Achievements
		{
			GameId:      multiplexGame.Id,
			Slug:        "dedicated-player",
			Title:       "Dedicated Player",
			Description: "Play for 5 hours total",
			Points:      100,
			Icon:        "/static/icons/achievements/dedicated.png",
			Criteria:    mustMarshalJSON(map[string]interface{}{"playtime_hours": 5}),
		},
	}

	for _, achievement := range achievements {
		if err := db.Create(&achievement).Error; err != nil {
			log.Printf("Failed to create achievement %s: %v", achievement.Slug, err)
		} else {
			log.Printf("Created achievement: %s", achievement.Title)
		}
	}

	log.Println("Game seeding completed successfully")
	return nil
}

// Helper function to marshal JSON
func mustMarshalJSON(data map[string]interface{}) string {
	jsonBytes, err := json.Marshal(data)
	if err != nil {
		return "{}"
	}
	return string(jsonBytes)
}
