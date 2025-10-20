package models

import (
	"log"

	"gorm.io/gorm"
)

// AutoMigrate runs all model migrations
func AutoMigrate(db *gorm.DB) error {
	log.Println("Running game models migrations...")

	// Migrate all game-related models
	if err := db.AutoMigrate(
		&Game{},
		&Achievement{},
		&UserAchievement{},
		&GameProgress{},
		&PlayerStats{},
	); err != nil {
		log.Printf("Failed to migrate game models: %v", err)
		return err
	}

	log.Println("Game models migrated successfully")
	return nil
}
