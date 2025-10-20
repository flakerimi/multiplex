package models

import (
	"base/core/app/profile"
	"time"

	"gorm.io/gorm"
)

// GameProgress stores user's game state and progress
type GameProgress struct {
	Id           uint           `gorm:"column:id;primary_key;auto_increment" json:"id"`
	UserId       uint           `gorm:"column:user_id;not null;index" json:"user_id" validate:"required"`
	User         *profile.User  `json:"user,omitempty" gorm:"foreignKey:UserId"`
	GameId       uint           `gorm:"column:game_id;not null;index" json:"game_id" validate:"required"`
	Game         *Game          `json:"game,omitempty" gorm:"foreignKey:GameId"`
	Data         string         `gorm:"column:data;type:json" json:"data"` // JSON field for flexible game state
	LastSyncedAt time.Time      `gorm:"column:last_synced_at;autoUpdateTime" json:"last_synced_at"`
	CreatedAt    time.Time      `gorm:"column:created_at" json:"created_at"`
	UpdatedAt    time.Time      `gorm:"column:updated_at" json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (GameProgress) TableName() string {
	return "game_progress"
}
