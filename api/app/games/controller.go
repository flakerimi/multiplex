package games

import (
	"base/core/logger"
	"base/core/router"
	"strconv"
)

type Controller struct {
	Service *Service
	Logger  logger.Logger
}

// @Summary Get game progress
// @Description Get the current game progress for the authenticated user
// @Tags Games
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param game_slug path string true "Game slug (e.g., multiplex, tetris)"
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /games/{game_slug}/progress [get]
func (c *Controller) GetProgress(ctx *router.Context) error {
	userIdVal, _ := ctx.Get("user_id")
	userId := userIdVal.(uint)
	gameSlug := ctx.Param("game_slug")

	progress, err := c.Service.GetProgress(userId, gameSlug)
	if err != nil {
		c.Logger.Error("Failed to get progress", logger.String("error", err.Error()))
		return ctx.JSON(500, map[string]interface{}{
			"error": "Failed to get progress",
		})
	}

	return ctx.JSON(200, map[string]interface{}{
		"progress": progress,
	})
}

// @Summary Save game progress
// @Description Save the game progress for the authenticated user
// @Tags Games
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param game_slug path string true "Game slug (e.g., multiplex, tetris)"
// @Param data body map[string]interface{} true "Game progress data"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /games/{game_slug}/progress [post]
func (c *Controller) SaveProgress(ctx *router.Context) error {
	userIdVal, _ := ctx.Get("user_id")
	userId := userIdVal.(uint)
	gameSlug := ctx.Param("game_slug")

	var data map[string]interface{}
	if err := ctx.Bind(&data); err != nil {
		return ctx.JSON(400, map[string]interface{}{
			"error": "Invalid request body",
		})
	}

	progress, err := c.Service.SaveProgress(userId, gameSlug, data)
	if err != nil {
		c.Logger.Error("Failed to save progress", logger.String("error", err.Error()))
		return ctx.JSON(500, map[string]interface{}{
			"error": "Failed to save progress",
		})
	}

	return ctx.JSON(200, map[string]interface{}{
		"progress": progress,
		"message":  "Progress saved successfully",
	})
}

// @Summary Get available achievements
// @Description Get all available achievements for a game
// @Tags Games
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param game_slug path string true "Game slug (e.g., multiplex, tetris)"
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /games/{game_slug}/achievements [get]
func (c *Controller) GetAchievements(ctx *router.Context) error {
	gameSlug := ctx.Param("game_slug")

	achievements, err := c.Service.GetAchievements(gameSlug)
	if err != nil {
		c.Logger.Error("Failed to get achievements", logger.String("error", err.Error()))
		return ctx.JSON(500, map[string]interface{}{
			"error": "Failed to get achievements",
		})
	}

	// Also get user's unlocked achievements
	userIdVal, _ := ctx.Get("user_id")
	userId := userIdVal.(uint)
	userAchievements, _ := c.Service.GetUserAchievements(userId, gameSlug)

	return ctx.JSON(200, map[string]interface{}{
		"achievements":      achievements,
		"user_achievements": userAchievements,
	})
}

// @Summary Unlock achievement
// @Description Unlock a specific achievement for the authenticated user
// @Tags Games
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param game_slug path string true "Game slug (e.g., multiplex, tetris)"
// @Param slug path string true "Achievement slug"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /games/{game_slug}/achievements/{slug} [post]
func (c *Controller) UnlockAchievement(ctx *router.Context) error {
	userIdVal, _ := ctx.Get("user_id")
	userId := userIdVal.(uint)
	gameSlug := ctx.Param("game_slug")
	slug := ctx.Param("slug")

	if slug == "" {
		return ctx.JSON(400, map[string]interface{}{
			"error": "Achievement slug is required",
		})
	}

	userAchievement, err := c.Service.UnlockAchievement(userId, gameSlug, slug)
	if err != nil {
		c.Logger.Error("Failed to unlock achievement", logger.String("error", err.Error()))
		return ctx.JSON(500, map[string]interface{}{
			"error": err.Error(),
		})
	}

	return ctx.JSON(200, map[string]interface{}{
		"achievement": userAchievement,
		"message":     "Achievement unlocked successfully",
	})
}

// @Summary Get player stats
// @Description Get the player stats for the authenticated user
// @Tags Games
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param game_slug path string true "Game slug (e.g., multiplex, tetris)"
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /games/{game_slug}/stats [get]
func (c *Controller) GetStats(ctx *router.Context) error {
	userIdVal, _ := ctx.Get("user_id")
	userId := userIdVal.(uint)
	gameSlug := ctx.Param("game_slug")

	stats, err := c.Service.GetStats(userId, gameSlug)
	if err != nil {
		c.Logger.Error("Failed to get stats", logger.String("error", err.Error()))
		return ctx.JSON(500, map[string]interface{}{
			"error": "Failed to get stats",
		})
	}

	return ctx.JSON(200, map[string]interface{}{
		"stats": stats,
	})
}

// @Summary Update player stats
// @Description Update the player stats for the authenticated user
// @Tags Games
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param game_slug path string true "Game slug (e.g., multiplex, tetris)"
// @Param stats body map[string]interface{} true "Player stats data"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /games/{game_slug}/stats [post]
func (c *Controller) UpdateStats(ctx *router.Context) error {
	userIdVal, _ := ctx.Get("user_id")
	userId := userIdVal.(uint)
	gameSlug := ctx.Param("game_slug")

	var statsData map[string]interface{}
	if err := ctx.Bind(&statsData); err != nil {
		return ctx.JSON(400, map[string]interface{}{
			"error": "Invalid request body",
		})
	}

	stats, err := c.Service.UpdateStats(userId, gameSlug, statsData)
	if err != nil {
		c.Logger.Error("Failed to update stats", logger.String("error", err.Error()))
		return ctx.JSON(500, map[string]interface{}{
			"error": "Failed to update stats",
		})
	}

	return ctx.JSON(200, map[string]interface{}{
		"stats":   stats,
		"message": "Stats updated successfully",
	})
}

// @Summary Get leaderboard
// @Description Get the top players leaderboard for a game
// @Tags Games
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param game_slug path string true "Game slug (e.g., multiplex, tetris)"
// @Param limit query int false "Number of top players to return" default(10)
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /games/{game_slug}/leaderboard [get]
func (c *Controller) GetLeaderboard(ctx *router.Context) error {
	gameSlug := ctx.Param("game_slug")
	limitStr := ctx.Query("limit")
	limit := 10
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}

	leaderboard, err := c.Service.GetLeaderboard(gameSlug, limit)
	if err != nil {
		c.Logger.Error("Failed to get leaderboard", logger.String("error", err.Error()))
		return ctx.JSON(500, map[string]interface{}{
			"error": "Failed to get leaderboard",
		})
	}

	return ctx.JSON(200, map[string]interface{}{
		"leaderboard": leaderboard,
	})
}

// @Summary Get player profile
// @Description Get complete player profile with stats, achievements, and progress
// @Tags Games
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param game_slug path string true "Game slug (e.g., multiplex, tetris)"
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /games/{game_slug}/profile [get]
func (c *Controller) GetProfile(ctx *router.Context) error {
	userIdVal, _ := ctx.Get("user_id")
	userId := userIdVal.(uint)
	gameSlug := ctx.Param("game_slug")

	profile, err := c.Service.GetPlayerProfile(userId, gameSlug)
	if err != nil {
		c.Logger.Error("Failed to get player profile", logger.String("error", err.Error()))
		return ctx.JSON(500, map[string]interface{}{
			"error": "Failed to get player profile",
		})
	}

	return ctx.JSON(200, map[string]interface{}{
		"profile": profile,
	})
}

// Routes registers all game routes with :game_slug parameter
func (c *Controller) Routes(group *router.RouterGroup) {
	gamesGroup := group.Group("/games")
	gameGroup := gamesGroup.Group("/:game_slug")
	gameGroup.GET("/progress", c.GetProgress)
	gameGroup.POST("/progress", c.SaveProgress)
	gameGroup.GET("/achievements", c.GetAchievements)
	gameGroup.POST("/achievements/:slug", c.UnlockAchievement)
	gameGroup.GET("/stats", c.GetStats)
	gameGroup.POST("/stats", c.UpdateStats)
	gameGroup.GET("/leaderboard", c.GetLeaderboard)
	gameGroup.GET("/profile", c.GetProfile)
}
