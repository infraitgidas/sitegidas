#!/bin/sh
set -e

# Esperar a que la base de datos esté disponible
echo "Esperando conexión a la base de datos..."
until php -r "new PDO('mysql:host=${DB_HOST};dbname=${DB_NAME}', '${DB_USER}', '${DB_PASSWORD}');" 2>/dev/null; do
    echo "Base de datos no disponible, esperando..."
    sleep 2
done

echo "Base de datos conectada exitosamente"

# Crear directorios de archivos si no existen
mkdir -p sites/default/files
mkdir -p /var/www/private

# Ajustar permisos (solo si somos root)
if [ "$(id -u)" = "0" ]; then
    chown -R www-data:www-data sites/default/files
    chown -R www-data:www-data /var/www/private
    chmod 755 sites/default/files
    chmod 755 /var/www/private
fi

# Verificar si existe settings.php, si no, copiar default
if [ ! -f "sites/default/settings.php" ]; then
    if [ -f "sites/default/default.settings.php" ]; then
        cp sites/default/default.settings.php sites/default/settings.php
        echo "Archivo settings.php creado desde default.settings.php"
    fi
fi

# Ejecutar comando original
exec "$@"