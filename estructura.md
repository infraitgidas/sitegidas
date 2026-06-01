gidas-docker/
├── docker-compose.yml              # Orquestación principal
├── docker-compose.prod.yml         # Overrides para producción
├── docker-compose.override.yml     # Overrides para desarrollo (auto-loaded)
├── .env.example                    # Variables de entorno template
├── .env                            # Variables locales (no versionar)
├── Makefile                        # Comandos de conveniencia
├── docker/
│   ├── nginx/
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   └── drupal.conf
│   ├── php/
│   │   ├── Dockerfile
│   │   ├── php.ini
│   │   ├── opcache.ini
│   │   └── entrypoint.sh
│   └── mariadb/
│       └── my.cnf
├── scripts/
│   ├── init.sh                     # Script de inicialización
│   ├── backup.sh                   # Backup automatizado
│   └── deploy.sh                   # Despliegue automatizado
└── data/                           # Volúmenes persistentes (gitignored)
    ├── db/
    ├── files/
    └── private/

----

gidas-docker/                          ← Raíz del proyecto
│
├── .env                               ← [FALTA] Variables de entorno (CREAR)
├── .env.example                       ← [FALTA] Template de variables (CREAR)
├── .gitignore                         ← [FALTA] Exclusiones de git (CREAR)
│
├── gidas/                             ← [FALTA] COPIAR AQUÍ tu proyecto Drupal
│   ├── composer.json                  ← (de tu backup)
│   ├── composer.lock                  ← (de tu backup)
│   ├── vendor/                        ← (de tu backup)
│   └── web/                           ← (de tu backup)
│       ├── index.php
│       ├── core/
│       ├── modules/
│       ├── sites/
│       └── themes/
│
├── backup.sql                         ← [FALTA] COPIAR AQUÍ el backup SQL
│
├── docker-compose.yml                 ← (ya tienes)
├── docker-compose.prod.yml            ← (ya tienes)
├── docker-compose.override.yml        ← [FALTA] Overrides locales (CREAR)
├── portainer-stack.yml                ← (ya tienes)
├── Makefile                           ← (ya tienes)
│
├── docker/                            ← (ya tienes)
│   ├── mariadb/
│   │   └── my.cnf                     ← [FALTA] Config MySQL (CREAR)
│   ├── nginx/
│   │   ├── Dockerfile                 ← (ya tienes)
│   │   ├── nginx.conf                 ← [FALTA] Config base Nginx (CREAR)
│   │   └── drupal.conf                ← (ya tienes)
│   └── php/
│       ├── Dockerfile                 ← (ya tienes)
│       ├── entrypoint.sh              ← (ya tienes)
│       ├── opcache.ini                ← (ya tienes)
│       └── php.ini                    ← [FALTA] Config PHP (CREAR)
│
├── scripts/                           ← (ya tienes)
│   └── migrate.sh                     ← (ya tienes)
│
├── data/                              ← (ya tienes - se crea automático)
│   ├── db/                            ← Volúmen Docker (NO TOCAR)
│   ├── files/                         ← Volúmen Docker (NO TOCAR)
│   └── private/                       ← Volúmen Docker (NO TOCAR)
│
└── backups/                           ← [FALTA] Directorio para backups (CREAR)