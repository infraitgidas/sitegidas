# Roadmap de Actualización — Drupal in-place (Sitio GIDAS, UTN FRLP)

> **Objetivo:** actualizar el stack actual (Drupal 9.4.8 / PHP 7.4 / MariaDB 10.5) a versiones soportadas, sin migrar de CMS, priorizando **mantenibilidad** y **rendimiento** dentro del ecosistema Drupal.
>
> **Ruta alternativa a:** `roadmap-migracion-wordpress.md` (migración a WordPress). Ambos documentos quedan disponibles para que la decisión final dependa de lo que se resuelva institucionalmente.
>
> **Estado general (25/06/2026):** sitio en producción funcionando correctamente. Se completaron las fases de auditoría y la primera tanda de actualizaciones de seguridad/mantenimiento sobre Drupal 9.x. Próximo hito: actualizar módulos contrib pendientes (Paso 5) antes de planificar el salto a Drupal 10.
>
> **Cómo usar este documento:** bitácora viva. Marcar checkboxes y completar la tabla de [Bitácora de cambios](#bitácora-de-cambios) a medida que se avanza.

---

## 1. Diagnóstico de partida (actualizado)

| Componente | Versión al inicio | Versión actual (25/06/2026) | Estado | Versión objetivo |
|---|---|---|---|---|
| CMS | Drupal 9.4.8 | **Drupal 9.5.11** ✅ | Soportado (rama 9 vigente) | Drupal 10.x → luego 11.x |
| PHP | Se asumía 7.4 (README desactualizado) | **8.1.34** (ya estaba así) | Soportado | PHP 8.3 FPM |
| Nginx | 1.25 | 1.25 | OK | Se mantiene |
| MariaDB | 10.5 | 10.5 | Fin de soporte (jun 2025), pendiente | MariaDB 10.11 LTS |
| Composer | 2.x | 2.9.x | OK | Se mantiene |
| Drush | 10.6.1 | **11.6.0** ✅ | Soportado | 11.x (suficiente para D10) |

**Por qué esta ruta es viable:** Drupal tiene rutas de actualización oficiales entre majors (9→10→11), a diferencia de un cambio de CMS. El riesgo principal no está en Drupal core sino en **módulos contrib y custom (y un tema custom)** — por eso el primer trabajo real de este roadmap fue auditar exactamente eso.

**Trade-off a tener en cuenta:** este camino resuelve la urgencia de seguridad/soporte ahora, pero el problema de fondo (ciclos de actualización pesados cada ~2 años) se repite a futuro. Es una decisión válida si se prioriza no perder/migrar contenido y mantener el modelo operativo actual.

---

## 2. Arquitectura objetivo

```
┌─────────────────────────────────────────┐
│         Traefik (reverse proxy /         │
│           SSL) + Nginx 1.25+             │
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
      + Drush 11.x (CLI) — ya implementado ✅
```

> Nota agregada durante la ejecución: el stack real incluye **Traefik** delante de Nginx (descubierto al validar conectividad en la Fase de verificación). No cambia el plan, pero hay que tenerlo en cuenta para configuración de dominios/SSL más adelante.

---

## 3. Fases de actualización

### Fase 0 — Seguridad y preparación ✅ COMPLETADA (25/06/2026)

- [x] Rotación de credenciales expuestas en el README (realizada antes de iniciar esta rama de trabajo).
- [x] Limpieza de historial de git (se optó por reescribir el historial dado que el repo tenía un solo commit).
- [x] Permisos de `sites/default` corregidos: carpeta en `755`, archivos de configuración (`settings.php`, `settings.php.backup`, `services.yml`, `default.settings.php`, `default.services.yml`) en `644`. **Carpeta `files/` dejada sin tocar a propósito** (debe seguir siendo escribible por el servidor web).
- [x] Backup completo del estado pre-actualización.
- [x] Tag de punto de retorno en git.

### Fase 1 — Auditoría de módulos ✅ COMPLETADA (25/06/2026)

Resultado real obtenido con `drupal/upgrade_status`. **Conclusión clave: no hay módulos custom (carpeta `custom` no existe en `modules/`), pero sí hay un tema custom (`gidas_b5`, basado en `bootstrap5`) que requiere revisión puntual.**

#### Hallazgos del Status Report (núcleo y entorno)
- ✅ PHP ya estaba en **8.1.34** — el README tenía esta info desactualizada, nos ahorramos un paso completo del roadmap original.
- ✅ Resuelto: módulo **Color** (deprecado en core) desinstalado.
- ✅ Resuelto: Drush actualizado a **11.6.0** (D10 exige mínimo v11).
- ✅ Resuelto: Drupal core actualizado a **9.5.11**.
- 🔲 Pendiente: directorio de configuración privada con warning de `.htaccess` no escribible (ver punto 8).

#### 🔴 Bloqueantes reales (incompatibles con D10, sin upgrade simple disponible) — pendientes

| Proyecto | Tipo | Problemas reportados | Acción definida |
|---|---|---|---|
| `gidas_b5` | **Tema custom** | 2 | Revisar y corregir manualmente (código propio, bajo volumen) |
| `ckeditor_codemirror` | Contrib | 5 | Desinstalar al migrar a CKEditor 5 (no reparar) |
| `flexslider` | Contrib | 63 | Reemplazar por Slick o Splide (sin solución oficial D10/D11) |

#### ⚠️ Necesitan actualizar versión (compatibles, solo desactualizados) — **pendiente, es el Paso 5 actual**

| Módulo/tema | Versión local | Versión objetivo |
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
| bootstrap5 (tema base de `gidas_b5`) | 1.1.5 | 4.0.8 — **se actualiza por separado, validando visualmente antes/después** |

#### ✅ Ya compatibles, sin acción urgente
ckeditor (CKEditor 4, contrib — ya actualizado a 1.0.2 como dependencia del core update), admin_toolbar, crop, ctools, easy_breadcrumb, entity_reference_revisions, field_formatter_class, field_group, field_label, filefield_paths, jquery_ui, paragraphs, pathauto, token, views_bootstrap.

#### 🗑️ Limpieza pendiente
`field_tokens` — desinstalado pero sigue en composer.json. Remover si no se usa.

#### Checklist de ejecución de esta fase

- [x] Listar módulos contrib instalados (`drush pm:list`).
- [x] Confirmar que no hay módulos custom (solo tema custom `gidas_b5`).
- [x] Instalar y correr `drupal/upgrade_status` (luego desinstalado tras cumplir su función — incompatible con Drush 11).
- [x] Clasificar todos los proyectos en 🔴 / ⚠️ / ✅.
- [x] Asegurar permisos de `sites/default` (no escribible) → Fase 0.
- [x] Actualizar Drush a v11 (11.6.0).
- [x] Desinstalar módulo Color.
- [x] Actualizar Drupal core 9.4.8 → 9.5.11.
- [ ] **Actualizar los 10 módulos + tema `bootstrap5` de la tabla ⚠️ (Paso 5, en curso).**
- [ ] Revisar y corregir los 2 problemas del tema `gidas_b5`.
- [ ] Definir y ejecutar reemplazo de FlexSlider (Slick/Splide).
- [ ] Confirmar desinstalación de `ckeditor_codemirror` en la fase de CKEditor 5.
- [ ] Re-correr Upgrade Status (reinstalándolo puntualmente) para confirmar que solo quedan los 3 bloqueantes pendientes antes de planificar el salto a D10.

#### Notas técnicas registradas durante la ejecución de esta fase
- `drush` no está en el `$PATH` global del contenedor: se invoca como `vendor/bin/drush`.
- Composer 2.9 introdujo bloqueo automático de paquetes con advisories de seguridad conocidas (`audit.block-insecure`, default `true`). Se desactivó temporalmente (`composer config audit.block-insecure false`) para poder avanzar con las actualizaciones sin que cada `composer require` se trabara — **revertir a `true` en la Fase 10 (hardening)**, una vez resueltas las advisories reales por la actualización de versiones.
- El módulo `drupal/upgrade_status` (y sus dependencias `phpstan`) no es compatible con Drush 11 — rompe cualquier comando de Drush con un `TypeError` de container injection. Se desinstaló desde la UI (`/admin/modules`) una vez obtenida la info de auditoría que necesitábamos.

### Fase 2 — Entorno de staging (espejo de producción)

> Nota: en la práctica, los pasos de la Fase 1 (Drush, Color, core 9.5.11) se ejecutaron y validaron directamente, verificando salud del stack en cada paso (`docker compose ps`, `drush status`, `watchdog:show`, `curl`) en lugar de un staging separado. Mantener esta fase formalizada para los pasos más riesgosos que siguen (salto a D10, actualización de MariaDB).

- [ ] Levantar copia exacta del stack actual en un entorno separado.
- [ ] A partir del Paso 5 en adelante (módulos con más superficie de cambio) y especialmente antes del salto a D10, probar primero ahí.

### Fase 3 — PHP ✅ YA NO APLICA

Ya se confirmó que PHP está en 8.1.34 desde el inicio (el README del repo tenía esta info desactualizada). No se requiere acción en esta fase; el salto a PHP 8.3 se deja para la Fase 6, junto con MariaDB.

### Fase 4 — Actualizar Drupal 9.4 → 9.5 ✅ COMPLETADA (25/06/2026)

- [x] Backup de DB antes de actualizar (`mysqldump`).
- [x] Actualización vía Composer:
  ```bash
  docker compose exec php composer require 'drupal/core-recommended:^9.5' -W
  ```
  Resultado: `drupal/core` 9.4.8 → 9.5.11, junto con ~20 dependencias internas (Symfony, Laminas, Doctrine) actualizadas automáticamente. Sin "Problems" de resolución de dependencias.
- [x] Actualizaciones de base de datos aplicadas:
  ```bash
  docker compose exec php vendor/bin/drush updatedb -y
  docker compose exec php vendor/bin/drush cache:rebuild
  ```
  3 actualizaciones aplicadas sin errores (`block_content_post_update_entity_changed_constraint`, `user_post_update_sort_permissions`, `user_post_update_sort_permissions_again`).
- [x] Validación post-actualización:
  - `drush status` → Drupal 9.5.11 confirmado, DB conectada, bootstrap exitoso.
  - `curl -I` sobre la IP real del servidor → `200 OK`, headers de Drupal y cache funcionando normalmente.
  - `watchdog:show --severity=Error` → solo errores preexistentes (ver punto 8), ningún error nuevo introducido por la actualización.
  - Advisories de seguridad bajaron de 94 a 84 tras esta actualización — primera mejora medible.

### Fase 5 — Actualizar módulos/tema desactualizados 🔄 EN CURSO

- [ ] Backup de DB antes de actualizar.
- [ ] Actualizar los 10 módulos vía Composer:
  ```bash
  docker compose exec php composer require drupal/block_class:^4.0 drupal/colorbox:^2.2 drupal/eva:^3.1 drupal/focal_point:^2.1 drupal/realname:^2.0 drupal/scrollup:^3.0 drupal/svg_image:^3.2 drupal/taxonomy_manager:^2.0 drupal/token_filter:^2.2 drupal/userprotect:^8.1 -W
  ```
- [ ] `drush updatedb -y` + `drush cache:rebuild`.
- [ ] Validar sitio visualmente.
- [ ] Repetir el mismo patrón, por separado, para el tema `bootstrap5` (1.1.5 → 4.0.8), validando apariencia antes/después dado que es la base del tema custom `gidas_b5`.

### Fase 6 — Actualizar Drupal 9.5 → 10.x

- [ ] Resolver antes los 3 bloqueantes 🔴 de la Fase 1 (`gidas_b5`, `ckeditor_codemirror`, `flexslider`).
- [ ] Actualizar core:
  ```bash
  docker compose exec php composer require 'drupal/core-recommended:^10' -W
  ```
- [ ] Migrar editor CKEditor 4 → CKEditor 5 (core en D10).
- [ ] `drush updatedb -y` + `drush cache:rebuild`.
- [ ] Validar el sitio completo, página por página.

### Fase 7 — Subir PHP 8.1 → 8.3 y MariaDB 10.5 → 10.11

- [ ] Actualizar `docker/php/Dockerfile` a `php:8.3-fpm`, rebuild.
- [ ] Actualizar imagen de MariaDB en `docker-compose.yml` a `mariadb:10.11`.
- [ ] Backup completo antes de tocar MariaDB (los upgrades major pueden requerir migración del volumen de datos).
- [ ] Validar conectividad y funcionamiento completo tras ambos cambios.

### Fase 8 — (Opcional, recomendado a futuro) Drupal 10 → 11

- [ ] Repetir auditoría de módulos (estilo Fase 1) específica para D11.
- [ ] Actualizar vía composer apuntando a `^11`.
- [ ] Puede posponerse unos meses tras el cutover de D10 para estabilizar primero.

### Fase 9 — Optimización de rendimiento

- [ ] Activar/verificar OPcache con `opcache.validate_timestamps=0` en producción.
- [ ] Configurar Redis como backend de cache de Drupal (módulo `drupal/redis`).
- [ ] Activar agregación de CSS/JS en `/admin/config/development/performance`.
- [ ] Activar BigPipe o Internal Page Cache según el tipo de contenido.
- [ ] Benchmark antes/después con Lighthouse/GTmetrix.

### Fase 10 — Testing y validación

- [ ] Revisar todas las páginas/secciones clave.
- [ ] Verificar formularios, búsqueda interna, multimedia, editor de contenido.
- [ ] Probar permisos de usuarios/roles.
- [ ] Pedir a 2-3 personas del equipo que naveguen y reporten problemas.

### Fase 11 — Hardening de seguridad antes de producción

- [ ] Revertir `composer config audit.block-insecure true` (ver nota en Fase 1) — confirmar antes con `composer audit` que no quedan advisories reales sin resolver.
- [ ] Resolver el warning de `.htaccess` no escribible en el directorio de configuración privada (ver punto 8).
- [ ] Resolver los archivos SVG faltantes en `sites/default/files/areas/` (ver punto 8).
- [ ] `trusted_host_patterns` actualizado en `settings.php`.
- [ ] SSL/TLS vigente (validar config de Traefik).
- [ ] Puerto 3306 cerrado al exterior.
- [ ] Backups automáticos probados (restaurar al menos una vez en staging).

### Fase 12 — Cutover a producción

- [ ] Definir ventana de mantenimiento.
- [ ] Backup final justo antes del corte.
- [ ] Verificar funcionamiento end-to-end en producción real.
- [ ] Mantener un backup completo pre-cutover disponible por 2-4 semanas como red de seguridad.

### Fase 13 — Mantenimiento continuo

- [ ] Calendario de actualizaciones de seguridad de Drupal (revisar `/admin/reports/updates` mensualmente).
- [ ] Suscribirse a los security advisories de drupal.org para los módulos en uso.
- [ ] Backups verificados periódicamente.
- [ ] Monitoreo básico de uptime.
- [ ] Planificar la actualización a Drupal 11 (Fase 8) dentro del próximo ciclo si se pospuso.

---

## 4. Plan de rollback

Si algo falla gravemente después de un paso:
1. Restaurar el backup de DB tomado justo antes del paso en cuestión (cada fase de este documento incluye su propio backup previo).
2. Si el problema es de dependencias de Composer, revertir `composer.json`/`composer.lock` al commit anterior (`git checkout -- composer.json composer.lock && composer install`).
3. Documentar qué falló antes de reintentar.

---

## 5. Bitácora de cambios

| Fecha | Fase | Cambio realizado | Notas / problemas encontrados |
|---|---|---|---|
| 25/06/2026 | Fase 0 | Permisos de `sites/default` corregidos (755/644), `files/` sin tocar | Resuelto sin incidentes |
| 25/06/2026 | Fase 1 | Auditoría completa con `drupal/upgrade_status` | Confirmado: sin módulos custom, 1 tema custom (`gidas_b5`), 3 bloqueantes reales, 11 desactualizados |
| 25/06/2026 | Fase 1 | Drush 10.6.1 → 11.6.0 | Bloqueado inicialmente por bug de parsing en Drush 10 (`[preflight] Unable to parse`) y por bloqueo de advisories de Composer 2.9; resuelto desactivando `audit.block-insecure` temporalmente |
| 25/06/2026 | Fase 1 | Módulo `upgrade_status` desinstalado | Incompatible con Drush 11 (rompía todos los comandos); ya había cumplido su función |
| 25/06/2026 | Fase 1 | Módulo `Color` desinstalado | Deprecado en core, sin impacto visible |
| 25/06/2026 | Fase 4 | Drupal core 9.4.8 → 9.5.11 | Sin errores; advisories de seguridad bajaron de 94 a 84; sitio validado funcionando (200 OK, sin errores nuevos en watchdog) |
| | Fase 5 | Actualización de 10 módulos + tema `bootstrap5` | En curso |

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
- Stack original: Drupal 9.4.8 / PHP 7.4 (asumido, en realidad 8.1.34) FPM / Nginx 1.25 / MariaDB 10.5 / Traefik (descubierto durante la ejecución)
- Documento complementario: `roadmap-migracion-wordpress.md` (ruta WordPress)

---

## 8. Hallazgos preexistentes detectados durante la ejecución (no bloqueantes, pendientes para más adelante)

- **Archivos SVG faltantes en disco** (8 íconos de la sección "áreas" del sitio — `people.svg`, `green.svg`, `wheelchair-solid.svg`, `tractor-solid_4.svg`, `area-computacion.svg`, `area-salud.svg`, `area-software.svg`, `area-educacion.svg` — referenciados en DB pero ausentes en `sites/default/files/areas/`). Preexistente desde febrero 2026, no relacionado con esta migración. Pendiente: re-subir los archivos o limpiar las referencias huérfanas. Revisar en Fase 11.
- **Warning de seguridad `.htaccess`** en un directorio de configuración privada (`sites/default/files/config_...`) que no pudo escribirse. Preexistente desde febrero 2026. Pendiente: revisar permisos de esa carpeta en la Fase 11 (hardening).
- **Stack incluye Traefik** delante de Nginx (no documentado en el README original) — relevante para configuración de dominios/SSL en fases futuras.
