# Zenbase Makefile
# Organized commands for development and deployment

.PHONY: help install build dev up down logs clean test deploy health

help: ## Show this help message
	@echo "Zenbase - Multi-Tenant Enterprise Application"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies for backend and frontend
	@echo "📦 Installing dependencies..."
	cd backend && npm install
	cd frontend && npm install

build: ## Build the application
	@echo "🔨 Building application..."
	./scripts/build.sh

dev: ## Start development servers (requires 2 terminals)
	@echo "🚀 Starting development servers..."
	@echo "Run these in separate terminals:"
	@echo "  Terminal 1: cd backend && npm run dev"
	@echo "  Terminal 2: cd frontend && npm run dev"

up: ## Start services with docker-compose
	@echo "🐳 Starting services with docker-compose..."
	phase run --app "zenbase.online" docker-compose up -d
	@echo "Running Ports:"
	@docker-compose ps

stg: ## Make Stage
	@echo "🐳 Starting services with docker-compose..."
	docker-compose up -d
	@echo "Running Ports:"
	@docker-compose ps

down: ## Stop docker-compose services
	@echo "🛑 Stopping services..."
	docker-compose down

logs: ## Show docker-compose logs
	docker-compose logs -f

clean: ## Clean up containers, volumes, and build artifacts
	@echo "🧹 Cleaning up..."
	docker-compose down -v
	rm -rf backend/node_modules frontend/node_modules
	rm -rf frontend/dist
	rm -rf backend/.env frontend/.env

test: ## Run tests
	@echo "🧪 Running tests..."
	docker-compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit

deploy-dev: ## Deploy to development environment
	@echo "🚀 Deploying to development..."
	./scripts/deploy.sh development

deploy-staging: ## Deploy to staging environment
	@echo "🚀 Deploying to staging..."
	./scripts/deploy.sh staging

deploy-prod: ## Deploy to production environment
	@echo "🚀 Deploying to production..."
	./scripts/deploy.sh production

health: ## Run health checks
	@echo "🏥 Running health checks..."
	./scripts/health-check.sh

validate: ## Validate docker-compose configuration
	@echo "✅ Validating configuration..."
	docker-compose config > /dev/null
	@echo "Configuration is valid"

# Screwdriver.cd specific targets
sd-build: install build ## Screwdriver: Build step
	@echo "✅ Screwdriver build complete"

sd-test: test ## Screwdriver: Test step
	@echo "✅ Screwdriver tests complete"

sd-deploy: deploy-dev health ## Screwdriver: Deploy step
	@echo "✅ Screwdriver deployment complete"
