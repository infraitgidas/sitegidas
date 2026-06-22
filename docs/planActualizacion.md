# Roadmap de Migración — Sitio GIDAS (UTN FRLP)

> **Objetivo:** migrar de Drupal 9.4.8 / PHP 7.4 / MariaDB 10.5 (todos en fin de soporte) a un stack moderno, optimizado para **mantenibilidad** y **rendimiento**, minimizando riesgo sobre el sitio en producción.
>
> **Decisión tomada:** migrar de Drupal → **WordPress**, reutilizando la arquitectura Docker existente (Nginx + PHP-FPM + MariaDB).
>
> **Cómo usar este documento:** es tu bitácora viva. Cada vez que completes un paso, marcá el checkbox y agregá la fecha/nota en la sección [Bitácora de cambios](#bitácora-de-cambios) al final.

---

## 1. Diagnóstico de partida

| Componente | Versión actual | Estado | Versión objetivo |
|---|---|---|---|
| CMS | Drupal 9.4.8 | Fin de soporte | WordPress (última estable) |
| PHP | 7.4 FPM | Fin de soporte (sin parches desde 2022) | PHP 8.3 FPM |
| Nginx | 1.25 | OK | Se mantiene, se ajusta config |
| MariaDB | 10.5 | Fin de soporte (jun 2025) | MariaDB 10.11 LTS |

**Por qué WordPress y no actualizar Drupal in-place:** actualizar Drupal 9→10/11 obliga a subir PHP simultáneamente y revisar todos los módulos custom/contrib uno por uno (alto riesgo de breakage en un sitio institucional con poco soporte de desarrollo). Migrar a WordPress resuelve el problema de fondo —la dificultad de mantenimiento— en vez de posponerlo.

---

## 2. Arquitectura objetivo

```
┌─────────────────────────────────────────┐
│              Nginx 1.25+                │
│         (reverse proxy + gzip)           │
└───────────────────┬──────────────────────┘
                    │
┌───────────────────▼──────────────────────┐
│           PHP-FPM 8.3                    │
│   WordPress + OPcache + Object Cache     │
│        (Redis como backend)              │
└───────────────────┬──────────────────────┘
                    │
┌───────────────────▼──────────────────────┐
│          MariaDB 10.11 LTS               │
└───────────────────────────────────────────┘

      + Redis (cache de objetos WP)
      + WP-CLI (gestión, equivalente a Drush)
```

**Por qué esta arquitectura es la más óptima para tu caso:**
- **Modificabilidad:** WordPress separa núcleo / temas / plugins con actualizaciones independientes desde el panel — no más "composer update rompe todo".
- **Mantenibilidad:** ciclo de soporte de WP es más largo y retrocompatible que Drupal; PHP 8.3 tiene soporte activo hasta 2026 y seguridad hasta 2027.
- **Rendimiento:** PHP 8.3 es significativamente más rápido que 7.4 (JIT, mejoras internas) + Redis como cache de objetos reduce carga a MariaDB en cada request.

---

## 3. Fases de migración

### Fase 0 — Seguridad y preparación (hacer ANTES de tocar nada)

- [ ] Rotar cualquier password real que coincida con ejemplos expuestos en el README del repo (`cristal2022`, usuario `gidas-db`, etc.)
- [ ] Verificar si `.env` o `backup.sql` reales quedaron en el historial de git:
  ```bash
  git log --all --full-history -- .env
  git log --all --full-history -- backup.sql
  ```
- [ ] Si aparecen, limpiar el historial (`git filter-repo` o BFG Repo-Cleaner) y rotar todas las credenciales que hayan estado expuestas.
- [ ] Confirmar que el puerto 3306 de MariaDB no esté expuesto en `docker-compose.prod.yml`.
- [ ] Hacer un backup completo del estado actual (DB + archivos + código) usando el script ya existente (`backup-manual.sh` / `make db-backup`).
- [ ] Etiquetar el commit actual en git como punto de retorno: `git tag pre-migracion-wp`.

### Fase 1 — Entorno de staging (espejo de producción)

- [ ] Levantar una copia exacta del stack actual en un entorno separado (otro host, VM, o mismo host en otro puerto) usando `docker-compose.yml` + el `backup.sql` real.
- [ ] Verificar que el staging replica el comportamiento de producción (contenido, theming, URLs).
- [ ] **Toda la migración se hace primero en este staging.** Producción no se toca hasta el cutover final (Fase 8).

### Fase 2 — Nueva infraestructura Docker (WordPress)

- [ ] Crear nuevo `docker-compose.yml` con 3 servicios: `nginx`, `php` (WordPress + PHP 8.3-fpm), `db` (MariaDB 10.11), + `redis` opcional.
- [ ] Adaptar `docker/php/Dockerfile`: base `php:8.3-fpm`, extensiones necesarias para WP (`mysqli`, `gd`, `intl`, `zip`, `opcache`), instalar WP-CLI.
- [ ] Adaptar `docker/nginx/drupal.conf` → `wordpress.conf` (reglas de rewrite de WP son más simples que las de Drupal).
- [ ] Configurar OPcache (ya tenés práctica con esto del setup de Drupal) + instalar/configurar Redis para object cache.
- [ ] Mantener la misma estructura de volúmenes (`data/db`, `data/files`) para no perder la lógica de backups ya armada.

### Fase 3 — Instalación base de WordPress

- [ ] Levantar WordPress limpio en staging: `docker compose up -d --build`.
- [ ] Crear base de datos y usuario dedicados (mismo patrón que usaban para Drupal).
- [ ] Instalar WP-CLI dentro del contenedor PHP (reemplaza a Drush) y correr `wp core install`.
- [ ] Elegir/armar el tema (recomendado: un tema block-based moderno o uno custom liviano, evitando builders pesados tipo Elementor para no perder rendimiento).
- [ ] Instalar plugins esenciales:
  - SEO: Yoast SEO o Rank Math
  - Cache: WP Rocket o W3 Total Cache (configurado contra Redis)
  - Seguridad: Wordfence o Sucuri
  - Formularios (si el sitio tenía formularios en Drupal): WPForms o Fluent Forms

### Fase 4 — Migración de contenido

- [ ] Inventariar tipos de contenido en Drupal (`drush php:eval "print_r(\Drupal\node\Entity\NodeType::loadMultiple());"` o revisar `/admin/structure/types`).
- [ ] Mapear cada content type de Drupal a su equivalente en WordPress (posts, páginas, custom post types si hace falta).
- [ ] Exportar contenido de Drupal (plugin **FG Drupal to WordPress** o un script custom vía Drupal JSON:API → importador WP).
- [ ] Migrar medios (imágenes, PDFs) desde `data/files` hacia `wp-content/uploads`, preservando rutas si es posible (para no romper enlaces externos/SEO).
- [ ] Migrar usuarios/autores y reasignar roles equivalentes.
- [ ] Configurar redirects 301 de las URLs viejas de Drupal a las nuevas de WordPress (plugin Redirection), clave para no perder SEO acumulado.

### Fase 5 — Optimización de rendimiento

- [ ] Activar y verificar OPcache (`opcache.validate_timestamps=0` en producción, requiere reload manual en deploys).
- [ ] Activar cache de página completa (WP Rocket / similar) + cache de objetos vía Redis.
- [ ] Configurar compresión Gzip/Brotli en Nginx (ya tenían Gzip, sumar Brotli si la versión de Nginx lo soporta).
- [ ] Optimizar imágenes: plugin de compresión automática + lazy loading nativo.
- [ ] Configurar `cache headers` largos para assets estáticos en Nginx.
- [ ] Benchmark antes/después con herramientas como Lighthouse o GTmetrix sobre staging.

### Fase 6 — Testing y validación

- [ ] Revisar todas las páginas/secciones clave del sitio en staging.
- [ ] Verificar formularios, búsqueda interna, multimedia.
- [ ] Probar en mobile y revisar Core Web Vitals.
- [ ] Validar que los redirects 301 funcionan.
- [ ] Pedir a 2-3 personas del equipo que naveguen el staging y reporten problemas.

### Fase 7 — Hardening de seguridad antes de producción

- [ ] Checklist de producción (igual espíritu al que ya tenían en el README de Drupal, adaptado a WP):
  - [ ] Cambiar todas las credenciales por defecto.
  - [ ] Deshabilitar `xmlrpc.php` si no se usa.
  - [ ] Ocultar versión de WP (`wp_generator` removido).
  - [ ] SSL/TLS vía Let's Encrypt (Certbot o Traefik).
  - [ ] Puerto 3306 cerrado al exterior.
  - [ ] Backups automáticos configurados y probados (restaurar al menos una vez en staging para confirmar que el backup sirve).
  - [ ] Plugin de seguridad activo con reglas de login (rate limiting, 2FA para admins).

### Fase 8 — Cutover a producción

- [ ] Definir ventana de mantenimiento (avisar con anticipación, idealmente de baja audiencia).
- [ ] Backup final de Drupal en producción (DB + archivos) justo antes del corte.
- [ ] Sincronizar cualquier contenido nuevo publicado en Drupal durante el desarrollo del staging (si pasó tiempo entre Fase 1 y este punto).
- [ ] Apuntar DNS / cambiar el stack en el servidor de producción al nuevo `docker-compose.yml` de WordPress.
- [ ] Verificar funcionamiento end-to-end en producción real.
- [ ] Mantener el stack de Drupal viejo apagado pero disponible (no borrar) por al menos 2-4 semanas como red de seguridad.

### Fase 9 — Mantenimiento continuo (post-migración)

- [ ] Calendario de actualizaciones: WP core + plugins, revisar mensualmente.
- [ ] Backups automáticos verificados periódicamente (no solo que corran, que se puedan restaurar).
- [ ] Monitoreo básico de uptime (UptimeRobot o similar, gratuito).
- [ ] Revisión de seguridad trimestral (plugins desactualizados, usuarios admin innecesarios).

---

## 4. Plan de rollback

Si algo falla gravemente después del cutover:
1. Revertir DNS / `docker-compose.yml` de producción al stack de Drupal (que se mantiene apagado, no borrado).
2. Restaurar desde el backup tomado en la Fase 8 si hubo escritura de datos en el nuevo WordPress que se quiera preservar.
3. Documentar qué falló antes de reintentar.

---

## 5. Bitácora de cambios

> Completar a medida que se avanza. Formato sugerido:

| Fecha | Fase | Cambio realizado | Notas / problemas encontrados |
|---|---|---|---|
| | | | |
| | | | |
| | | | |

---

## 6. Referencias técnicas propias

- Repo original: `infraitgidas/sitegidas`
- Stack original: Drupal 9.4.8 / PHP 7.4 FPM / Nginx 1.25 / MariaDB 10.5
- Backups: usar mismo mecanismo de `backup-manual.sh` adaptado a las nuevas rutas de WordPress
