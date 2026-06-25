# Roadmap de Actualización — Drupal in-place (Sitio GIDAS, UTN FRLP)

> **Objetivo:** actualizar el stack actual (Drupal 9.4.8 / PHP 7.4 / MariaDB 10.5) a versiones soportadas, sin migrar de CMS, priorizando **mantenibilidad** y **rendimiento** dentro del ecosistema Drupal.
>
> **Ruta alternativa a:** `roadmap-migracion-gidas.md` (migración a WordPress). Ambos documentos quedan disponibles para que la decisión final dependa de lo que se resuelva institucionalmente.
>
> **Cómo usar este documento:** bitácora viva. Marcar checkboxes y completar la tabla de [Bitácora de cambios](#bitácora-de-cambios) a medida que se avanza.

---

## 1. Diagnóstico de partida

| Componente | Versión actual | Estado | Versión objetivo |
|---|---|---|---|
| CMS | Drupal 9.4.8 | Fin de soporte | Drupal 10.x → luego 11.x |
| PHP | 7.4 FPM | Fin de soporte | PHP 8.3 FPM |
| Nginx | 1.25 | OK | Se mantiene |
| MariaDB | 10.5 | Fin de soporte (jun 2025) | MariaDB 10.11 LTS |
| Composer | 2.x | OK | Se mantiene, se actualizan dependencias |
| Drush | 10.x | Desactualizado para D10/11 | Drush 12.x+ |

**Por qué esta ruta es viable:** Drupal tiene rutas de actualización oficiales entre majors (9→10→11), a diferencia de un cambio de CMS. El riesgo principal no está en Drupal core sino en **módulos contrib y custom** — por eso el primer paso real de este roadmap es auditar exactamente eso.

**Trade-off a tener en cuenta:** este camino resuelve la urgencia de seguridad/soporte ahora, pero el problema de fondo (ciclos de actualización pesados cada ~2 años) se repite a futuro. Es una decisión válida si se prioriza no perder/migrar contenido y mantener el modelo operativo actual.

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
│   Drupal 10/11 + OPcache + APCu          │
│        (Redis opcional como cache)        │
└───────────────────┬──────────────────────┘
                    │
┌───────────────────▼──────────────────────┐
│          MariaDB 10.11 LTS               │
└───────────────────────────────────────────┘

      + Redis (cache backend, opcional pero recomendado)
      + Drush 12.x (CLI)
```

---

## 3. Fases de actualización

### Fase 0 — Seguridad y preparación

> Comparte la misma Fase 0 ya ejecutada/documentada en `roadmap-migracion-gidas.md` (rotación de credenciales, limpieza de historial de git, backup, tag de punto de retorno). No se repite acá: si ya se hizo para la ruta WordPress, está cubierta también para esta ruta. Si no se hizo, hacerla primero.

- [ ] Confirmar que la Fase 0 del otro roadmap está completa antes de seguir.

### Fase 1 — Auditoría de módulos (el paso que define la complejidad real) ✅ COMPLETADA

Resultado real obtenido con `drupal/upgrade_status` el 25/06/2026. **Conclusión clave: no hay módulos custom (carpeta `custom` no existe), pero sí hay un tema custom (`gidas_b5`) que requiere revisión.**

#### Hallazgos adicionales del Status Report (fuera de módulos, pero relevantes)
- 🔴 Directorio `sites/default` sin protección de escritura (riesgo de seguridad).
- 🔴 Módulo **Color** deprecado en core, será removido en próxima major.
- 🔴 Drush en versión 10; Drupal 10 exige **mínimo Drush 11**.
- ⚠️ PHP ya está en **8.1.34** (no 7.4 como indicaba el README desactualizado) — un paso menos en el roadmap.
- ⚠️ Drupal core en 9.4.8, recomendado subir primero a 9.5.11 antes de tocar D10.

#### 🔴 Bloqueantes reales (incompatibles, sin upgrade simple disponible)

| Proyecto | Tipo | Problemas | Acción definida |
|---|---|---|---|
| `gidas_b5` | **Tema custom** | 2 | Revisar y corregir manualmente (código propio, bajo volumen) |
| `ckeditor_codemirror` | Contrib | 5 | Desinstalar al migrar a CKEditor 5 (no reparar) |
| `flexslider` | Contrib | 63 | Reemplazar por Slick o Splide (sin solución oficial D10/D11) |

#### ⚠️ Necesitan actualizar versión (compatibles, solo desactualizados)

| Módulo | Versión local | Versión objetivo |
|---|---|---|
| block_class | 8.x-1.3 | 4.0.2 |
| colorbox | 8.x-1.10 | 2.2.0 |
| eva | 8.x-2.1 | 3.1.1 |
| focal_point | 8.x-1.5 | 2.1.2 |
| realname | 2.0.0-beta1 | 2.0.0 |
| scrollup | 3.0.0 | 3.0.4 |
| svg_image | 8.x-1.16 | 3.2.3 |
| taxonomy_manager | 2.0.7 | 2.0.23 |
| token_filter | 8.x-1.4 | 2.2.1 |
| userprotect | 8.x-1.1 | 8.x-1.4 |
| bootstrap5 (tema) | 1.1.5 | 4.0.8 |

#### ✅ Ya compatibles, sin acción urgente
ckeditor (CKEditor 4, contrib), admin_toolbar, crop, ctools, easy_breadcrumb, entity_reference_revisions, field_formatter_class, field_group, field_label, filefield_paths, jquery_ui, paragraphs, pathauto, token, views_bootstrap.

#### 🗑️ Limpieza
`field_tokens` — desinstalado pero sigue en composer.json. Remover si no se usa.

#### Checklist de ejecución de esta fase

- [x] Listar módulos contrib instalados (`drush pm:list`).
- [x] Confirmar que no hay módulos custom (solo tema custom `gidas_b5`).
- [x] Instalar y correr `drupal/upgrade_status`.
- [x] Clasificar todos los proyectos en 🔴 / ⚠️ / ✅.
- [ ] Asegurar permisos de `sites/default` (no escribible).
- [ ] Actualizar Drush a v11.
- [ ] Desinstalar módulo Color.
- [ ] Actualizar Drupal core 9.4.8 → 9.5.11.
- [ ] Actualizar los 11 módulos/tema de la tabla ⚠️.
- [ ] Revisar y corregir los 2 problemas del tema `gidas_b5`.
- [ ] Definir y ejecutar reemplazo de FlexSlider (Slick/Splide).
- [ ] Confirmar desinstalación de `ckeditor_codemirror` en la fase de CKEditor 5.
- [ ] Re-correr Upgrade Status para confirmar que solo quedan los 3 bloqueantes pendientes de la fase de migración a D10.

### Fase 2 — Entorno de staging (espejo de producción)

- [ ] Levantar copia exacta del stack actual en un entorno separado, igual que en la otra ruta.
- [ ] Toda la actualización se prueba primero ahí. Producción no se toca hasta el cutover final.

### Fase 3 — Subir PHP 7.4 → 8.1 (paso intermedio, antes de Drupal 10)

> Drupal 9.4 corre sobre PHP 8.1, así que conviene subir PHP primero, validar que nada se rompe, y recién después subir Drupal.

- [ ] Actualizar `docker/php/Dockerfile` a base `php:8.1-fpm`.
- [ ] Reinstalar extensiones necesarias (gd, mysqli, opcache, apcu, etc.) en el nuevo Dockerfile.
- [ ] Rebuild y levantar en staging:
  ```bash
  docker compose build php
  docker compose up -d
  ```
- [ ] Correr `drush status` y navegar el sitio completo en staging para detectar errores de compatibilidad de módulos con PHP 8.1.
- [ ] Resolver errores módulo por módulo (actualizar versión vía composer o parchear código custom).

### Fase 4 — Actualizar Drupal 9.4 → 9.5 (última versión de la rama 9)

- [ ] Backup de DB en staging antes de tocar nada.
- [ ] Actualizar vía composer:
  ```bash
  docker compose exec php composer require 'drupal/core-recommended:^9.5' \
    'drupal/core-composer-scaffold:^9.5' \
    'drupal/core-project-message:^9.5' --update-with-dependencies
  ```
- [ ] Ejecutar actualizaciones de base de datos:
  ```bash
  docker compose exec php drush updatedb -y
  docker compose exec php drush cache:rebuild
  ```
- [ ] Validar el sitio completo en staging.

### Fase 5 — Actualizar Drupal 9.5 → 10.x

- [ ] Resolver en `composer.json` cualquier módulo que todavía no soporte D10 (usar lo documentado en la Fase 1).
- [ ] Actualizar core:
  ```bash
  docker compose exec php composer require 'drupal/core-recommended:^10' \
    'drupal/core-composer-scaffold:^10' \
    'drupal/core-project-message:^10' --update-with-dependencies
  ```
- [ ] Correr el chequeo de compatibilidad de tema (Drupal 10 cambia algunas convenciones de Twig/CKEditor 5 si el tema es custom):
  ```bash
  docker compose exec php drush theme:list
  ```
- [ ] `drush updatedb -y` + `drush cache:rebuild`.
- [ ] Revisar especialmente: editor CKEditor 4→5 (cambia configuración), y cualquier dependencia de jQuery UI (deprecada en D10).
- [ ] Validar el sitio completo en staging, página por página.

### Fase 6 — Subir PHP 8.1 → 8.3 y MariaDB 10.5 → 10.11

- [ ] Actualizar `docker/php/Dockerfile` a `php:8.3-fpm`, rebuild.
- [ ] Actualizar imagen de MariaDB en `docker-compose.yml` a `mariadb:10.11`.
- [ ] **Importante:** antes de actualizar MariaDB, hacer backup completo — los upgrades de versión major de MariaDB pueden requerir `mysql_upgrade` o pasos de migración del volumen de datos.
- [ ] Validar conectividad y funcionamiento completo en staging tras ambos cambios.

### Fase 7 — (Opcional, recomendado a futuro) Drupal 10 → 11

- [ ] Repetir el mismo proceso de auditoría de módulos (Fase 1) específico para D11.
- [ ] Actualizar vía composer igual que la Fase 5, apuntando a `^11`.
- [ ] Esta fase puede posponerse unos meses después del cutover de D10 si el equipo necesita estabilizar primero — D10 ya sale del problema de "fin de soporte" inmediato.

### Fase 8 — Optimización de rendimiento

- [ ] Activar/verificar OPcache con `opcache.validate_timestamps=0` en producción (requiere reload manual en deploys).
- [ ] Configurar Redis como backend de cache de Drupal (módulo `drupal/redis`) en lugar de solo DB cache.
- [ ] Revisar y activar agregación de CSS/JS en `/admin/config/development/performance`.
- [ ] Activar BigPipe o Internal Page Cache según el tipo de contenido (anónimo vs autenticado).
- [ ] Benchmark antes/después con Lighthouse/GTmetrix sobre staging.

### Fase 9 — Testing y validación

- [ ] Revisar todas las páginas/secciones clave en staging.
- [ ] Verificar formularios, búsqueda interna, multimedia, editor de contenido (CKEditor 5).
- [ ] Probar permisos de usuarios/roles (a veces se resetean con upgrades de core).
- [ ] Pedir a 2-3 personas del equipo que naveguen el staging y reporten problemas.

### Fase 10 — Hardening de seguridad antes de producción

- [ ] Checklist ya armado en el README original, validado contra la nueva versión:
  - [ ] Credenciales rotadas (si no se hizo en Fase 0).
  - [ ] `trusted_host_patterns` actualizado en `settings.php`.
  - [ ] SSL/TLS vigente.
  - [ ] Puerto 3306 cerrado al exterior.
  - [ ] Backups automáticos probados (restaurar al menos una vez en staging).

### Fase 11 — Cutover a producción

- [ ] Definir ventana de mantenimiento.
- [ ] Backup final de producción justo antes del corte.
- [ ] Aplicar la misma secuencia de fases (3 a 8) sobre producción, o reemplazar el stack completo por el de staging ya validado.
- [ ] Verificar funcionamiento end-to-end en producción real.
- [ ] Mantener un backup completo pre-cutover disponible por 2-4 semanas como red de seguridad.

### Fase 12 — Mantenimiento continuo

- [ ] Calendario de actualizaciones de seguridad de Drupal (revisar `/admin/reports/updates` mensualmente).
- [ ] Suscribirse a los security advisories de drupal.org para los módulos en uso.
- [ ] Backups verificados periódicamente.
- [ ] Monitoreo básico de uptime.
- [ ] Planificar la actualización a Drupal 11 (Fase 7) dentro del próximo ciclo si se pospuso.

---

## 4. Plan de rollback

Si algo falla gravemente después del cutover:
1. Restaurar el backup completo (DB + código + archivos) tomado justo antes del cutover.
2. Volver al stack Docker anterior (versión Drupal 9.4 / PHP 7.4) que se mantiene documentado/disponible.
3. Documentar qué falló antes de reintentar.

---

## 5. Bitácora de cambios

| Fecha | Fase | Cambio realizado | Notas / problemas encontrados |
|---|---|---|---|
| | | | |
| | | | |

---

## 6. Comparación rápida con la ruta WordPress

| Criterio | Actualizar Drupal (este doc) | Migrar a WordPress |
|---|---|---|
| Riesgo de pérdida de contenido/SEO | Bajo (sin cambio de URLs ni modelo de datos) | Medio (requiere redirects 301 y migración de contenido) |
| Esfuerzo inmediato | Alto (auditoría de módulos + 3-4 saltos de versión) | Alto (migración completa de contenido) |
| Mantenimiento a largo plazo | Sigue requiriendo ciclos de actualización mayor cada ~2 años | Más liviano, actualizaciones incrementales desde panel |
| Apto para modelado de contenido complejo | Sí, mejor para taxonomías/permisos avanzados | Limitado sin plugins adicionales |

---

## 7. Referencias técnicas propias

- Repo original: `infraitgidas/sitegidas`
- Stack original: Drupal 9.4.8 / PHP 7.4 FPM / Nginx 1.25 / MariaDB 10.5
- Documento complementario: `roadmap-migracion-gidas.md` (ruta WordPress)
