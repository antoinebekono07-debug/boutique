#!/bin/sh

set -e

echo "[Railway] Boot sequence started"

if [ -z "$APP_KEY" ]; then
  if [ "${RAILWAY_AUTO_GENERATE_APP_KEY:-true}" = "true" ]; then
    GENERATED_APP_KEY="base64:$(php -r 'echo base64_encode(random_bytes(32));')"
    export APP_KEY="$GENERATED_APP_KEY"
    echo "[Railway] APP_KEY absent -> clé temporaire générée pour ce runtime"
    echo "[Railway] IMPORTANT: définis APP_KEY dans Railway Variables pour une clé persistante"
  else
    echo "[Railway] ERREUR: APP_KEY est vide. Configure APP_KEY dans Railway Variables."
    exit 1
  fi
fi

if [ "${RAILWAY_RUN_MIGRATIONS:-true}" = "true" ]; then
  MIGRATION_MAX_RETRIES="${RAILWAY_MIGRATION_MAX_RETRIES:-10}"
  MIGRATION_RETRY_DELAY="${RAILWAY_MIGRATION_RETRY_DELAY:-5}"
  MIGRATION_FAIL_ON_ERROR="${RAILWAY_FAIL_ON_MIGRATION_ERROR:-false}"
  ATTEMPT=1
  MIGRATION_OK=false

  if [ -z "${DB_HOST:-}" ] || [ -z "${DB_DATABASE:-}" ] || [ -z "${DB_USERNAME:-}" ]; then
    echo "[Railway] Variables DB incomplètes -> migrations ignorées"
  else
    echo "[Railway] Exécution des migrations automatiques"
    while [ "$ATTEMPT" -le "$MIGRATION_MAX_RETRIES" ]; do
      echo "[Railway] Migration tentative ${ATTEMPT}/${MIGRATION_MAX_RETRIES}"

      if php artisan migrate --force --no-interaction; then
        echo "[Railway] Migrations OK"
        MIGRATION_OK=true
        break
      fi

      if [ "$ATTEMPT" -eq "$MIGRATION_MAX_RETRIES" ]; then
        echo "[Railway] ERREUR: migrations échouées après ${MIGRATION_MAX_RETRIES} tentatives"
        break
      fi

      ATTEMPT=$((ATTEMPT + 1))
      echo "[Railway] Base indisponible, nouvelle tentative dans ${MIGRATION_RETRY_DELAY}s..."
      sleep "$MIGRATION_RETRY_DELAY"
    done

    if [ "$MIGRATION_OK" != "true" ] && [ "$MIGRATION_FAIL_ON_ERROR" = "true" ]; then
      echo "[Railway] Arrêt car RAILWAY_FAIL_ON_MIGRATION_ERROR=true"
      exit 1
    fi

    if [ "$MIGRATION_OK" != "true" ] && [ "$MIGRATION_FAIL_ON_ERROR" != "true" ]; then
      echo "[Railway] Migrations KO, mais démarrage poursuivi (RAILWAY_FAIL_ON_MIGRATION_ERROR=false)"
    fi
  fi
else
  echo "[Railway] Migrations désactivées (RAILWAY_RUN_MIGRATIONS=${RAILWAY_RUN_MIGRATIONS})"
fi

if [ "${RAILWAY_STORAGE_LINK:-true}" = "true" ]; then
  echo "[Railway] Préparation du lien storage"

  # Évite l'erreur "symlink(): Aucun fichier ou répertoire de ce type"
  # quand le dossier cible n'existe pas encore dans un container neuf.
  mkdir -p storage/app/public
  mkdir -p public

  if [ -e "public/storage" ] && [ ! -L "public/storage" ]; then
    echo "[Railway] public/storage existe déjà (non-symlink) -> storage:link ignoré"
  else
    echo "[Railway] Création du lien storage"
    php artisan storage:link --no-interaction || {
      echo "[Railway] storage:link a échoué, tentative de symlink manuel"
      ln -sfn ../storage/app/public public/storage 2>/dev/null || true
    }
  fi
fi

echo "[Railway] Démarrage serveur PHP sur le port ${PORT:-8080}"
exec php -d variables_order=EGPCS -S 0.0.0.0:${PORT:-8080} server.php
