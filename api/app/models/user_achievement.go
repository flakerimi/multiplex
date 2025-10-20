package models

import (
	"base/core/app/profile"
	"time"

	"gorm.io/gorm"
)

// UserAchievement tracks which achievements users have unlocked
type UserAchievement struct {
	Id            uint           `gorm:"column:id;primary_key;auto_increment" json:"id"`
	UserId        uint           `gorm:"column:user_id;not null;index" json:"user_id" validate:"required"`
	User          *profile.User  `json:"user,omitempty" gorm:"foreignKey:UserId"`
	AchievementId uint           `gorm:"column:achievement_id;not null;index" json:"achievement_id" validate:"required"`
	Achievement   *Achievement   `json:"achievement,omitempty" gorm:"foreignKey:AchievementId"`
	Progress      string         `gorm:"column:progress;type:json" json:"progress"` // JSON for partial completion tracking
	UnlockedAt    *time.Time     `gorm:"column:unlocked_at" json:"unlocked_at"`
	CreatedAt     time.Time      `gorm:"column:created_at" json:"created_at"`
	UpdatedAt     time.Time      `gorm:"column:updated_at" json:"updated_at"`
	DeletedAt     gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (UserAchievement) TableName() string {
	return "user_achievements"
}
