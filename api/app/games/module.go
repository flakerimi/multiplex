package games

import (
	"base/core/module"
	"base/core/router"
)

type Module struct {
	controller *Controller
	service    *Service
}

func (m *Module) Init() error {
	return nil
}

func (m *Module) Migrate() error {
	// Models are migrated globally, no need to migrate here
	return nil
}

func (m *Module) GetModels() []interface{} {
	// Return empty slice as models are registered globally
	return []interface{}{}
}

func (m *Module) Routes(group *router.RouterGroup) {
	m.controller.Routes(group)
}

// NewModule creates a new Games module instance
func NewModule(deps module.Dependencies) module.Module {
	service := &Service{
		DB:      deps.DB,
		Emitter: deps.Emitter,
		Logger:  deps.Logger,
	}

	controller := &Controller{
		Service: service,
		Logger:  deps.Logger,
	}

	return &Module{
		controller: controller,
		service:    service,
	}
}
