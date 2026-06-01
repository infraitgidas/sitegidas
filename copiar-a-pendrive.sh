#!/bin/bash
# copiar-a-pendrive.sh

# CONFIGURACIÓN
PROYECTO_DIR="$HOME/gidas-docker"  # Ajusta según tu ruta
PENDRIVE_DIR="/run/media/emanuel/Ventoy"  # Se detecta automáticamente o configura manual

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