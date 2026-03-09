#!/bin/sh

set -e

echo "[Railway] Boot sequence started"

if [ -z "$APP_KEY" ]; then
  echo "[Railway] ERREUR: APP_KEY est vide. Configure APP_KEY dans Railway Variables."
  exit 1
fi

if [ "${RAILWAY_RUN_MIGRATIONS:-true}" = "true" ]; then
  MIGRATION_MAX_RETRIES="${RAILWAY_MIGRATION_MAX_RETRIES:-10}"
  MIGRATION_RETRY_DELAY="${RAILWAY_MIGRATION_RETRY_DELAY:-5}"
  ATTEMPT=1

  echo "[Railway] Exécution des migrations automatiques"
  while [ "$ATTEMPT" -le "$MIGRATION_MAX_RETRIES" ]; do
    echo "[Railway] Migration tentative ${ATTEMPT}/${MIGRATION_MAX_RETRIES}"

    if php artisan migrate --force --no-interaction; then
      echo "[Railway] Migrations OK"
      break
    fi

    if [ "$ATTEMPT" -eq "$MIGRATION_MAX_RETRIES" ]; then
      echo "[Railway] ERREUR: migrations échouées après ${MIGRATION_MAX_RETRIES} tentatives"
      exit 1
    fi

    ATTEMPT=$((ATTEMPT + 1))
    echo "[Railway] Base indisponible, nouvelle tentative dans ${MIGRATION_RETRY_DELAY}s..."
    sleep "$MIGRATION_RETRY_DELAY"
  done
else
  echo "[Railway] Migrations désactivées (RAILWAY_RUN_MIGRATIONS=${RAILWAY_RUN_MIGRATIONS})"
fi

if [ "${RAILWAY_STORAGE_LINK:-true}" = "true" ]; then
  echo "[Railway] Création du lien storage"
  php artisan storage:link || true
fi

echo "[Railway] Démarrage serveur PHP sur le port ${PORT:-8080}"
exec php -d variables_order=EGPCS -S 0.0.0.0:${PORT:-8080} server.php
