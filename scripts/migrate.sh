#!/bin/bash
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MIGRACIÓN GIDAS A DOCKER ===${NC}"

# Verificar dependencias
command -v docker-compose >/dev/null 2>&1 || { echo -e "${RED}Error: docker-compose no instalado${NC}" >&2; exit 1; }

# Cargar variables de entorno
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Paso 1: Preparar estructura
echo -e "${YELLOW}[1/6] Preparando estructura de directorios...${NC}"
mkdir -p data/db data/files data/private backups

# Paso 2: Iniciar solo la base de datos para importación
echo -e "${YELLOW}[2/6] Iniciando base de datos...${NC}"
docker-compose up -d db
sleep 15

# Paso 3: Importar backup SQL si existe
if [ -f "backup.sql" ]; then
    echo -e "${YELLOW}[3/6] Importando base de datos...${NC}"
    docker-compose exec -T db mysql -u root -p${DB_ROOT_PASSWORD} ${DB_NAME} < backup.sql
    echo -e "${GREEN}Base de datos importada exitosamente${NC}"
else
    echo -e "${YELLOW}No se encontró backup.sql, saltando importación${NC}"
fi

# Paso 4: Copiar archivos existentes
if [ -d "gidas/web/sites/default/files" ]; then
    echo -e "${YELLOW}[4/6] Copiando archivos subidos...${NC}"
    cp -r gidas/web/sites/default/files/* data/files/ 2>/dev/null || true
    chown -R 1000:1000 data/files
fi

# Paso 5: Iniciar servicios completos
echo -e "${YELLOW}[5/6] Iniciando servicios completos...${NC}"
docker-compose up -d

# Paso 6: Verificar instalación
echo -e "${YELLOW}[6/6] Verificando instalación...${NC}"
sleep 10

if curl -f -s http://localhost/user/login > /dev/null; then
    echo -e "${GREEN}✓ Drupal accesible en http://localhost${NC}"
else
    echo -e "${RED}✗ No se pudo verificar acceso a Drupal${NC}"
fi

echo -e "${GREEN}=== MIGRACIÓN COMPLETADA ===${NC}"
echo -e "Accesos:"
echo -e "  - Sitio: http://localhost"
echo -e "  - phpMyAdmin: http://localhost:8080"
echo -e "  - Logs: docker-compose logs -f"