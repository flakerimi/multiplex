package models

import (
	"time"

	"gorm.io/gorm"
)

// Game represents a game in the platform
type Game struct {
	Id          uint           `gorm:"column:id;primary_key;auto_increment" json:"id"`
	Slug        string         `gorm:"column:slug;uniqueIndex;not null;size:255" json:"slug" validate:"required"`
	Title       string         `gorm:"column:title;not null;size:255" json:"title" validate:"required"`
	Description string         `gorm:"column:description;type:text" json:"description"`
	Icon        string         `gorm:"column:icon" json:"icon"`
	Active      bool           `gorm:"column:active;default:true" json:"active"`
	CreatedAt   time.Time      `gorm:"column:created_at" json:"created_at"`
	UpdatedAt   time.Time      `gorm:"column:updated_at" json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (Game) TableName() string {
	return "games"
}
