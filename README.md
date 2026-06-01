# 🎓 GIDAS - Grupo de Investigación & Desarrollo Aplicado a Sistemas
## Universidad Tecnológica Nacional - Facultad Regional La Plata

[![Drupal](https://img.shields.io/badge/Drupal-9.4.8-009cde?logo=drupal)](https://drupal.org)
[![PHP](https://img.shields.io/badge/PHP-7.4-777bb4?logo=php)](https://php.net)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ed?logo=docker)](https://docker.com)
[![MariaDB](https://img.shields.io/badge/MariaDB-10.5-003545?logo=mariadb)](https://mariadb.org)
[![License](https://img.shields.io/badge/License-GPL--2.0+-blue.svg)](LICENSE)

> **Sitio web institucional del Grupo GIDAS**  
> Infraestructura Dockerizada para desarrollo y producción

---

## 📋 Tabla de Contenidos

- [Arquitectura](#-arquitectura)
- [Requisitos](#-requisitos)
- [Instalación Rápida](#-instalación-rápida)
- [Configuración](#-configuración)
- [Uso](#-uso)
- [Gestión de Base de Datos](#-gestión-de-base-de-datos)
- [Backups](#-backups)
- [Solución de Problemas](#-solución-de-problemas)
- [Seguridad](#-seguridad)
- [Créditos](#-créditos)

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                         CLIENTE                              │
│                   (Navegador Web)                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                      SERVIDOR HOST                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Nginx (Web Server)                                   │  │
│  │  - Puerto: 80/443                                     │  │
│  │  - Compresión Gzip                                    │  │
│  └──────────────┬────────────────────────────────────────┘  │
│                 │                                            │
│  ┌──────────────▼────────────────────────────────────────┐  │
│  │  PHP-FPM 7.4 (App Server)                             │  │
│  │  - Drupal 9.4.8                                       │  │
│  │  - OPcache + APCu                                     │  │
│  └──────────────┬────────────────────────────────────────┘  │
│                 │                                            │
│  ┌──────────────▼────────────────────────────────────────┐  │
│  │  MariaDB 10.5 (Database)                              │  │
│  │  - Volúmenes persistentes                             │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  [Opcional] Redis (Cache) | Portainer (Gestión)            │
└─────────────────────────────────────────────────────────────┘
```

### Stack Tecnológico

| Componente | Versión | Propósito |
|------------|---------|-----------|
| **Drupal** | 9.4.8 | CMS Institucional |
| **PHP** | 7.4 FPM | Procesamiento backend |
| **Nginx** | 1.25 | Servidor web/proxy |
| **MariaDB** | 10.5 | Base de datos |
| **Composer** | 2.x | Gestión de dependencias |
| **Drush** | 10.x | CLI de Drupal |

---

## 📦 Requisitos

### Software Necesario

- [Docker Engine](https://docs.docker.com/engine/install/) 20.10+
- [Docker Compose](https://docs.docker.com/compose/install/) 2.0+
- Git (opcional, para versionado)

### Recursos del Sistema

| Entorno | RAM | CPU | Disco |
|---------|-----|-----|-------|
| Desarrollo | 2 GB | 2 cores | 10 GB |
| Producción | 4 GB | 4 cores | 50 GB |

### Archivos Requeridos

```
gidas-docker/
├── gidas/                    # Código fuente Drupal
│   ├── composer.json
│   ├── composer.lock
│   ├── vendor/
│   └── web/
├── backup.sql                # Backup de base de datos (opcional para migración)
└── .env                      # Variables de entorno (crear desde .env.example)
```

---

## 🚀 Instalación Rápida

### 1. Clonar/Preparar el Proyecto

```bash
# Si viene de un backup comprimido
tar -xzf gidas-docker.tar.gz
cd gidas-docker
```

### 2. Configurar Variables de Entorno

```bash
# Copiar template
cp .env.example .env

# Editar con tus credenciales
nano .env  # o vim, vscode, etc.
```

**Variables críticas a configurar:**
```ini
DB_ROOT_PASSWORD=password_seguro_root
DB_NAME=gidas
DB_USER=gidas-db
DB_PASSWORD=cristal2022
ENVIRONMENT=development
```

### 3. Iniciar Servicios

```bash
# Construir e iniciar
docker compose up -d --build

# Verificar estado
docker compose ps
```

### 4. Configurar Base de Datos (Migración)

Si tienes un `backup.sql`:

```bash
# Crear base de datos y usuario
docker compose exec -T db mysql -u root -p"$DB_ROOT_PASSWORD" << EOF
CREATE DATABASE IF NOT EXISTS gidas CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'gidas-db'@'%' IDENTIFIED BY 'cristal2022';
GRANT ALL PRIVILEGES ON gidas.* TO 'gidas-db'@'%';
FLUSH PRIVILEGES;
EOF

# Importar backup
docker compose exec -T db mysql -u root -p"$DB_ROOT_PASSWORD" gidas < backup.sql
```

### 5. Verificar Instalación

```bash
# Test de conectividad
curl -I http://localhost

# Debe responder: HTTP/1.1 200 OK
```

Accede al sitio: **http://localhost**

---

## ⚙️ Configuración

### Estructura de Archivos

```
gidas-docker/
├── docker/
│   ├── nginx/              # Configuración Nginx
│   │   ├── nginx.conf
│   │   └── drupal.conf
│   ├── php/                # Configuración PHP
│   │   ├── Dockerfile
│   │   ├── php.ini
│   │   └── opcache.ini
│   └── mariadb/            # Configuración MySQL
│       └── my.cnf
├── gidas/                  # Código Drupal (volumen)
├── data/                   # Datos persistentes (Docker volumes)
│   ├── db/                 # Base de datos
│   ├── files/              # Archivos subidos
│   └── private/            # Archivos privados
├── backups/                # Backups automatizados
├── docker-compose.yml      # Orquestación principal
├── docker-compose.prod.yml # Overrides producción
├── docker-compose.override.yml # Overrides desarrollo
├── .env                    # Variables de entorno (NO versionar)
├── .env.example            # Template de variables
└── Makefile                # Comandos de conveniencia
```

### Configuración de Red

| Servicio | Puerto Host | Puerto Contenedor | Descripción |
|----------|-------------|-------------------|-------------|
| Nginx | 80 | 80 | HTTP |
| Nginx | 443 | 443 | HTTPS |
| Nginx | 8080 | 80 | HTTP alternativo |
| MariaDB | 3306 | 3306 | MySQL (solo dev) |
| PHP-FPM | - | 9000 | FastCGI (interno) |

---

## 🎮 Uso

### Comandos Básicos (Makefile)

```bash
# Ver todos los comandos disponibles
make help

# Iniciar servicios
make up

# Detener servicios
make down

# Ver logs
make logs

# Acceder a shell PHP
make shell

# Backup de base de datos
make db-backup

# Reconstruir imágenes
make build
```

### Comandos Docker Compose

```bash
# Iniciar en background
docker compose up -d

# Iniciar con rebuild
docker compose up -d --build

# Ver logs en tiempo real
docker compose logs -f

# Escala horizontal (múltiples workers PHP)
docker compose up -d --scale php=3

# Ejecutar drush
docker compose exec php drush cache:rebuild
docker compose exec php drush status
docker compose exec php drush updatedb -y

# Ejecutar composer
docker compose exec php composer install
docker compose exec php composer update

# Acceder a contenedores
docker compose exec php bash
docker compose exec db bash
docker compose exec nginx sh
```

### Gestión de Archivos

Los archivos subidos por usuarios se almacenan en:
- **Públicos**: `data/files/` (mapeado a `sites/default/files`)
- **Privados**: `data/private/`

---

## 🗄️ Gestión de Base de Datos

### Acceso Directo

```bash
# MySQL CLI
docker compose exec db mysql -u root -p

# O usar usuario de aplicación
docker compose exec db mysql -u gidas-db -p gidas
```

### phpMyAdmin (Desarrollo)

```bash
# Incluir en docker-compose.override.yml
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d phpmyadmin

# Acceder en: http://localhost:8080
```

### Importar/Exportar

```bash
# Exportar (Backup)
docker compose exec db mysqldump -u root -p gidas > backup_$(date +%Y%m%d_%H%M%S).sql

# Importar
docker compose exec -T db mysql -u root -p gidas < backup.sql
```

---

## 💾 Backups

### Backup Automatizado

El servicio `backup` está configurado en `docker-compose.yml`:

```bash
# Iniciar con perfil de backup
docker compose --profile backup up -d

# Backups se guardan en ./backups/
# Retención: 7 días por defecto
```

### Backup Manual Completo

```bash
#!/bin/bash
# backup-manual.sh

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups/$FECHA"
mkdir -p $BACKUP_DIR

# Base de datos
docker compose exec db mysqldump -u root -p$(grep DB_ROOT_PASSWORD .env | cut -d '=' -f2) gidas > $BACKUP_DIR/database.sql

# Archivos
cp -r data/files $BACKUP_DIR/files
cp -r data/private $BACKUP_DIR/private

# Código (opcional)
cp -r gidas/web $BACKUP_DIR/web

tar -czf $BACKUP_DIR.tar.gz $BACKUP_DIR
rm -rf $BACKUP_DIR

echo "Backup creado: $BACKUP_DIR.tar.gz"
```

---

## 🔧 Solución de Problemas

### Problema: 500 Internal Server Error

**Causa**: Error de conexión a base de datos  
**Solución**:
```bash
# Verificar credenciales
docker compose exec php php -r "new PDO('mysql:host=db;dbname=gidas', 'gidas-db', 'tu-password');"

# Recrear usuario si es necesario
docker compose exec db mysql -u root -p -e "CREATE USER 'gidas-db'@'%' IDENTIFIED BY 'cristal2022'; GRANT ALL ON gidas.* TO 'gidas-db'@'%'; FLUSH PRIVILEGES;"
```

### Problema: 404 Not Found

**Causa**: Nginx no encuentra archivos  
**Solución**:
```bash
# Verificar estructura
docker compose exec nginx ls -la /var/www/html/web/

# Reiniciar nginx
docker compose restart nginx
```

### Problema: Permisos de archivos

**Causa**: UID/GID no coinciden  
**Solución**:
```bash
# Ajustar permisos en host
sudo chown -R 1000:1000 gidas/web/sites/default/files
sudo chmod -R 755 gidas/web/sites/default/files
```

### Problema: Contenedores no inician

```bash
# Verificar logs
docker compose logs [servicio]

# Reconstruir todo
docker compose down -v
docker compose up -d --build

# Verificar puertos ocupados
sudo netstat -tlnp | grep :80
```

### Limpiar Todo (⚠️ Pérdida de datos)

```bash
docker compose down -v
docker system prune -f
docker volume prune -f
```

---

## 🔒 Seguridad

### Checklist de Producción

- [ ] Cambiar todas las contraseñas por defecto
- [ ] Configurar `trusted_host_patterns` en `settings.php`
- [ ] Habilitar SSL/TLS (Let's Encrypt)
- [ ] Deshabilitar puerto 3306 expuesto (quitar de docker-compose.override.yml)
- [ ] Configurar firewall (iptables/ufw)
- [ ] Deshabilitar phpMyAdmin en producción
- [ ] Configurar backups automáticos
- [ ] Actualizaciones de seguridad regulares

### Variables Sensibles

**NUNCA** subir al repositorio:
- `.env`
- `secrets/`
- `backup.sql` (si contiene datos reales)
- Certificados SSL (`*.pem`, `*.key`)

### SSL/TLS (Producción)

```bash
# Usar Traefik o certbot para Let's Encrypt
# Configurar en docker-compose.prod.yml
```

---

## 📚 Referencias

- [Documentación Drupal](https://www.drupal.org/docs)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Nginx Drupal Configuration](https://www.nginx.com/resources/wiki/start/topics/recipes/drupal/)
- [MariaDB Docker Hub](https://hub.docker.com/_/mariadb)

---

## 👥 Créditos

**Desarrollado por**: Grupo GIDAS - UTN FRLP  
**Contacto**: gidas@frlp.utn.edu.ar  
**Sitio Web**: https://gidas.frlp.utn.edu.ar

### Equipo de Infraestructura

- Arquitectura Docker: [Tu nombre]
- Drupal Development: GIDAS Team
- Base de Datos: MariaDB Community

---

## 📄 Licencia

Este proyecto está licenciado bajo GPL-2.0+ - ver [LICENSE](LICENSE) para más detalles.

Drupal es una marca registrada de Dries Buytaert.

---

<p align="center">
  <strong>🏛️ Universidad Tecnológica Nacional - Facultad Regional La Plata</strong><br>
  <em>Promoviendo la investigación y desarrollo tecnológico</em>
</p>
```

---

## 💾 COPIAR A PENDRIVE

Ahora te ayudo a copiar todo el proyecto a un pendrive. Primero, detecta dónde está montado tu pendrive:

```bash
# Ver dispositivos USB conectados
lsblk

# Ver puntos de montaje
df -h | grep -E "(media|mnt|run/media)"

# Listar contenido de /media o /run/media
ls /run/media/$USER/
```

### Script de Copia Segura

```bash
#!/bin/bash
# copiar-a-pendrive.sh

# CONFIGURACIÓN
PROYECTO_DIR="$HOME/gidas-docker"  # Ajusta según tu ruta
PENDRIVE_DIR=""  # Se detecta automáticamente o configura manual

echo "=== COPIA DE PROYECTO GIDAS A PENDRIVE ==="

# Detectar pendrive automáticamente
if [ -z "$PENDRIVE_DIR" ]; then
    PENDRIVE_DIR=$(find /run/media/$USER -maxdepth 1 -type d 2>/dev/null | head -2 | tail -1)
    if [ -z "$PENDRIVE_DIR" ]; then
        PENDRIVE_DIR=$(find /media/$USER -maxdepth 1 -type d 2>/dev/null | head -2 | tail -1)
    fi
fi

if [ -z "$PENDRIVE_DIR" ] || [ "$PENDRIVE_DIR" = "/run/media/$USER" ] || [ "$PENDRIVE_DIR" = "/media/$USER" ]; then
    echo "❌ No se detectó pendrive automáticamente"
    echo "Dispositivos disponibles:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "(usb|sdb|sdc|disk)"
    echo ""
    echo "Ingresa la ruta manualmente (ej: /run/media/emanuel/MiPendrive):"
    read PENDRIVE_DIR
fi

# Verificar que existe
if [ ! -d "$PENDRIVE_DIR" ]; then
    echo "❌ Error: $PENDRIVE_DIR no existe"
    exit 1
fi

echo "📁 Pendrive detectado: $PENDRIVE_DIR"
echo "📂 Proyecto origen: $PROYECTO_DIR"
echo ""

# Calcular tamaño
echo "📊 Calculando tamaño del proyecto..."
cd "$PROYECTO_DIR"
SIZE_TOTAL=$(du -sh . | cut -f1)
SIZE_GIDAS=$(du -sh gidas 2>/dev/null | cut -f1 || echo "N/A")
SIZE_DATA=$(du -sh data 2>/dev/null | cut -f1 || echo "N/A")

echo "Tamaños:"
echo "  - Total proyecto: $SIZE_TOTAL"
echo "  - Código (gidas/): $SIZE_GIDAS"
echo "  - Datos (data/): $SIZE_DATA"
echo ""

# Verificar espacio disponible
ESPACO_PENDRIVE=$(df -h "$PENDRIVE_DIR" | tail -1 | awk '{print $4}')
echo "💾 Espacio disponible en pendrive: $ESPACO_PENDRIVE"
echo ""

# Preguntar qué copiar
echo "¿Qué deseas copiar?"
echo "1) Todo el proyecto (incluye datos de DB y archivos)"
echo "2) Solo código fuente (sin data/, backups/, vendor/)"
echo "3) Solo configuración Docker (sin gidas/, data/)"
echo "4) Cancelar"
read -p "Opción [1-4]: " OPCION

DESTINO="$PENDRIVE_DIR/gidas-docker-$(date +%Y%m%d)"

case $OPCION in
    1)
        echo "📦 Copiando TODO el proyecto..."
        mkdir -p "$DESTINO"
        rsync -avh --progress \
            --exclude='.git' \
            --exclude='node_modules' \
            "$PROYECTO_DIR/" "$DESTINO/"
        ;;
    2)
        echo "📦 Copiando solo código fuente..."
        mkdir -p "$DESTINO"
        rsync -avh --progress \
            --exclude='.git' \
            --exclude='node_modules' \
            --exclude='data/' \
            --exclude='backups/*.sql' \
            --exclude='backups/*.gz' \
            --exclude='gidas/vendor/' \
            "$PROYECTO_DIR/" "$DESTINO/"
        
        # Crear instrucciones para reconstruir vendor
        cat > "$DESTINO/README-RECONSTRUIR.md" << 'EOF'
# Reconstrucción del Proyecto

Este backup contiene solo el código fuente. Para reconstruir:

1. Copiar a tu máquina
2. Ejecutar: `docker compose exec php composer install`
3. Configurar base de datos según README.md principal
EOF
        ;;
    3)
        echo "📦 Copiando solo configuración Docker..."
        mkdir -p "$DESTINO"
        cp -r "$PROYECTO_DIR/docker" "$DESTINO/"
        cp "$PROYECTO_DIR/docker-compose.yml" "$DESTINO/"
        cp "$PROYECTO_DIR/docker-compose.prod.yml" "$DESTINO/"
        cp "$PROYECTO_DIR/docker-compose.override.yml" "$DESTINO/"
        cp "$PROYECTO_DIR/Makefile" "$DESTINO/"
        cp "$PROYECTO_DIR/.env.example" "$DESTINO/"
        ;;
    4)
        echo "❌ Cancelado"
        exit 0
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac

# Crear archivo de información
cat > "$DESTINO/INFO-COPIA.txt" << EOF
Proyecto GIDAS Docker
====================
Fecha de copia: $(date)
Origen: $PROYECTO_DIR
Destino: $DESTINO
Tipo de copia: $OPCION
Tamaño: $(du -sh "$DESTINO" | cut -f1)

Contenido:
$(ls -la "$DESTINO")

Para restaurar:
1. Copiar esta carpeta a tu máquina
2. Renombrar a 'gidas-docker'
3. Seguir instrucciones de README.md
EOF

echo ""
echo "✅ COPIA COMPLETADA"
echo "📍 Ubicación: $DESTINO"
echo "📋 Archivo de info: $DESTINO/INFO-COPIA.txt"
echo ""
echo "Para verificar integridad:"
echo "  cd $DESTINO && find . -type f -exec md5sum {} \; > checksums.md5"

# Desmontar de forma segura
echo ""
read -p "¿Desmontar pendrive de forma segura? [s/N]: " DESMONTAR
if [ "$DESMONTAR" = "s" ] || [ "$DESMONTAR" = "S" ]; then
    sync
    umount "$PENDRIVE_DIR" 2>/dev/null || umount -l "$PENDRIVE_DIR" 2>/dev/null
    echo "✅ Pendrive desmontado. Puedes retirarlo."
fi
```

### Instrucciones de Uso

```bash
# 1. Guardar el script
nano copiar-a-pendrive.sh
# (Pegar el contenido y guardar)

# 2. Dar permisos
chmod +x copiar-a-pendrive.sh

# 3. Conectar pendrive y esperar que se monte automáticamente

# 4. Ejecutar
./copiar-a-pendrive.sh

# O manualmente con rsync:
rsync -avh --progress ~/gidas-docker/ /run/media/tu-usuario/MiPendrive/gidas-docker/
```

### Comando Simple (Alternativa)

Si prefieres algo más simple:

```bash
# Detectar pendrive
PENDRIVE=$(find /run/media/$USER -maxdepth 1 -type d | grep -v "^/run/media/$USER$" | head -1)

# Copiar todo
sudo rsync -avh --progress ~/gidas-docker/ "$PENDRIVE/gidas-docker-$(date +%Y%m%d)/"

# O comprimir primero (más rápido)
tar -czf /tmp/gidas-docker.tar.gz -C ~/ gidas-docker
cp /tmp/gidas-docker.tar.gz "$PENDRIVE/"

# Desmontar
sync
sudo umount "$PENDRIVE"
```

---
