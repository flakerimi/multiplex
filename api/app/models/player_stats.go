package models

import (
	"base/core/app/profile"
	"time"

	"gorm.io/gorm"
)

// PlayerStats stores player statistics per game
type PlayerStats struct {
	Id        uint           `gorm:"column:id;primary_key;auto_increment" json:"id"`
	UserId    uint           `gorm:"column:user_id;not null;index" json:"user_id" validate:"required"`
	User      *profile.User  `json:"user,omitempty" gorm:"foreignKey:UserId"`
	GameId    uint           `gorm:"column:game_id;not null;index" json:"game_id" validate:"required"`
	Game      *Game          `json:"game,omitempty" gorm:"foreignKey:GameId"`
	Stats     string         `gorm:"column:stats;type:json" json:"stats"` // JSON for scores, playtime, wins, etc.
	CreatedAt time.Time      `gorm:"column:created_at" json:"created_at"`
	UpdatedAt time.Time      `gorm:"column:updated_at" json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (PlayerStats) TableName() string {
	return "player_stats"
}
