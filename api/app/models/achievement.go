package models

import (
	"time"

	"gorm.io/gorm"
)

// Achievement represents a game achievement
type Achievement struct {
	Id          uint           `gorm:"column:id;primary_key;auto_increment" json:"id"`
	GameId      uint           `gorm:"column:game_id;not null;index" json:"game_id" validate:"required"`
	Game        *Game          `json:"game,omitempty" gorm:"foreignKey:GameId"`
	Slug        string         `gorm:"column:slug;index;not null" json:"slug" validate:"required"`
	Title       string         `gorm:"column:title;not null" json:"title" validate:"required"`
	Description string         `gorm:"column:description;type:text" json:"description"`
	Points      int            `gorm:"column:points;default:0" json:"points"`
	Icon        string         `gorm:"column:icon" json:"icon"`
	Criteria    string         `gorm:"column:criteria;type:json" json:"criteria"` // JSON field for achievement criteria
	CreatedAt   time.Time      `gorm:"column:created_at" json:"created_at"`
	UpdatedAt   time.Time      `gorm:"column:updated_at" json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (Achievement) TableName() string {
	return "achievements"
}
