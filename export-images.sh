#!/bin/bash
set -e

# ==========================================
# CONFIGURACIÓN
# ==========================================
VERSION=$(date +%Y%m%d-%H%M%S)
EXPORT_DIR="./docker-images-${VERSION}"
PROJECT_NAME="gidas"
REGISTRY="localhost:5000"  # Opcional: para registry local

echo "=========================================="
echo "  EXPORTACIÓN DE IMÁGENES DOCKER - GIDAS"
echo "  Versión: ${VERSION}"
echo "=========================================="

# Crear directorio de exportación
mkdir -p "${EXPORT_DIR}"
echo "📁 Directorio de exportación: ${EXPORT_DIR}"

# ==========================================
# OBTENER IMÁGENES DEL PROYECTO
# ==========================================
echo ""
echo "🔍 Detectando imágenes del proyecto..."

# Obtener imágenes definidas en docker-compose
IMAGES=$(docker compose config | grep "image:" | awk '{print $2}' | sort -u)

# Agregar imágenes construidas localmente
IMAGES_LOCAL=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "${PROJECT_NAME}" || true)

echo "Imágenes detectadas:"
echo "${IMAGES}"
echo "${IMAGES_LOCAL}"

# ==========================================
# EXPORTAR CADA IMAGEN
# ==========================================
echo ""
echo "📦 Exportando imágenes..."

# Función para exportar imagen
export_image() {
    local img=$1
    local filename=$(echo "${img}" | tr '/' '_' | tr ':' '_')
    local filepath="${EXPORT_DIR}/${filename}.tar"
    
    echo "  → Exportando: ${img}"
    docker save -o "${filepath}" "${img}"
    
    # Comprimir
    echo "    Comprimiendo..."
    gzip -f "${filepath}"
    
    # Calcular checksum
    md5sum "${filepath}.gz" > "${filepath}.gz.md5"
    
    echo "    ✅ Exportado: ${filepath}.gz"
    ls -lh "${filepath}.gz"
}

# Exportar imágenes base
for img in mariadb:10.5.15 nginx:1.25-alpine; do
    if docker image inspect "${img}" >/dev/null 2>&1; then
        export_image "${img}"
    else
        echo "  ⚠️  Imagen no encontrada localmente: ${img}"
    fi
done

# Exportar imágenes personalizadas
CUSTOM_IMAGES=(
    "gidas-docker-php:latest"
    "gidas-docker-nginx:latest"
)

for img in "${CUSTOM_IMAGES[@]}"; do
    if docker image inspect "${img}" >/dev/null 2>&1; then
        # Taggear con versión
        docker tag "${img}" "${img%:*}:${VERSION}"
        export_image "${img%:*}:${VERSION}"
    else
        echo "  ⚠️  Imagen no encontrada: ${img}"
    fi
done

# ==========================================
# CREAR MANIFESTO DE VERSIONES
# ==========================================
echo ""
echo "📝 Creando manifesto de versiones..."

cat > "${EXPORT_DIR}/MANIFEST.md" << MANIFEST
# Manifesto de Imágenes Docker - GIDAS
## Versión: ${VERSION}
## Fecha: $(date -Iseconds)

### Imágenes Exportadas

| Imagen | Archivo | Tamaño | MD5 |
|--------|---------|--------|-----|
$(for f in ${EXPORT_DIR}/*.tar.gz; do 
    if [ -f "$f" ]; then
        img=$(basename "$f" .tar.gz | tr '_' '/' | sed 's/_latest/:latest/' | sed 's/_/: /' | sed 's/ /:/2')
        size=$(du -h "$f" | cut -f1)
        md5=$(cat "$f.md5" 2>/dev/null | awk '{print $1}' || echo "N/A")
        echo "| ${img} | $(basename "$f") | ${size} | ${md5} |"
    fi
done)

### Instrucciones de Importación

1. Transferir archivos .tar.gz al servidor destino
2. Ejecutar: \`docker load -i [archivo].tar.gz\`
3. Verificar: \`docker images | grep gidas\`

### Estructura del Proyecto

- docker-compose.yml: Orquestación principal
- docker-compose.prod.yml: Configuración de producción
- docker/: Configuraciones de servicios
- gidas/: Código fuente Drupal
- data/: Volúmenes de datos (NO incluido en imágenes)

MANIFEST

# ==========================================
# CREAR SCRIPT DE IMPORTACIÓN
# ==========================================
echo ""
echo "🔧 Creando script de importación..."

cat > "${EXPORT_DIR}/import-images.sh" << 'IMPORTSCRIPT'
#!/bin/bash
echo "Importando imágenes Docker..."

for img in *.tar.gz; do
    if [ -f "$img" ]; then
        echo "Importando: $img"
        docker load -i "$img"
    fi
done

echo "Imágenes importadas:"
docker images | grep -E "(gidas|mariadb|nginx)" | head -10
IMPORTSCRIPT

chmod +x "${EXPORT_DIR}/import-images.sh"

# ==========================================
# RESUMEN
# ==========================================
echo ""
echo "=========================================="
echo "  EXPORTACIÓN COMPLETADA"
echo "=========================================="
echo "📁 Ubicación: ${EXPORT_DIR}"
echo ""
echo "Contenido:"
ls -lh "${EXPORT_DIR}/"
echo ""
echo "Tamaño total:"
du -sh "${EXPORT_DIR}"
echo ""
echo "Para transferir a servidor remoto:"
echo "  rsync -avh --progress ${EXPORT_DIR}/ usuario@192.168.1.106:/opt/gidas-deploy/"
