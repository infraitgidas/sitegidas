.PHONY: help build up down restart logs shell db-backup db-restore install

# Variables
COMPOSE = docker compose
COMPOSE_PROD = docker compose -f docker-compose.yml -f docker-compose.prod.yml
PROJECT_NAME = gidas

help:
	@echo "Comandos disponibles:"
	@echo "  make build        - Construir imágenes"
	@echo "  make up           - Iniciar en desarrollo"
	@echo "  make up-prod      - Iniciar en producción"
	@echo "  make down         - Detener contenedores"
	@echo "  make restart      - Reiniciar servicios"
	@echo "  make logs         - Ver logs"
	@echo "  make shell        - Acceder al contenedor PHP"
	@echo "  make db-backup    - Backup de base de datos"
	@echo "  make db-restore   - Restaurar base de datos"
	@echo "  make install      - Instalación inicial"
	@echo "  make update       - Actualizar Drupal"
	@echo "  make portainer    - Iniciar Portainer"

build:
	$(COMPOSE) build --no-cache

up:
	$(COMPOSE) up -d

up-prod:
	$(COMPOSE_PROD) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f

shell:
	$(COMPOSE) exec php sh

db-backup:
	@mkdir -p backups
	$(COMPOSE) exec db mysqldump -u root -p$(DB_ROOT_PASSWORD) $(DB_NAME) | gzip > backups/gidas-db-$(shell date +%Y%m%d-%H%M%S).sql.gz

db-restore:
	@echo "Uso: make db-restore FILE=/home/emanuel/gidas-docker/backups_20260224.sql"
	$(COMPOSE) exec -T db mysql -u root -p$(DB_ROOT_PASSWORD) $(DB_NAME) < $(FILE)

install:
	$(COMPOSE) up -d db
	sleep 10
	$(COMPOSE) up -d php nginx
	$(COMPOSE) exec php composer install --no-interaction
	$(COMPOSE) exec php drush site:install standard --db-url=mysql://$(DB_USER):$(DB_PASSWORD)@db/$(DB_NAME) --site-name="GIDAS UTN" --account-name=admin --account-pass=admin -y

update:
	$(COMPOSE) exec php composer update drupal/core --with-dependencies
	$(COMPOSE) exec php drush updatedb -y
	$(COMPOSE) exec php drush cache:rebuild

portainer:
	docker compose -f portainer-stack.yml up -d

clean:
	$(COMPOSE) down -v
	docker system prune -f