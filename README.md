A complete solution for E-commerce Business with exclusive features & super responsive layout.

## Déploiement sur Railway (PHP)

Ce projet est maintenant prêt pour Railway avec un fichier `railway.json`.

> ✅ Correctif build Railway : un fichier `nixpacks.toml` est ajouté pour forcer un build **PHP uniquement** (évite l'étape `npm i` et l'erreur `node-sass`).

### 1) Configuration déjà ajoutée au repo

- `railway.json`
  - Build: `composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction`
  - Start: `sh railway-start.sh`
- `server.php` adapté pour ce projet (front controller à la racine via `index.php`)
- `nixpacks.toml`
  - Force `providers = ["php"]`
  - Empêche l'auto-détection Node/NPM par Nixpacks
  - Build uniquement via Composer
- `railway-start.sh`
  - Vérifie `APP_KEY`
  - Lance les migrations automatiquement (avec retry)
  - Lance `storage:link` (optionnel)
  - Démarre le serveur PHP

### 2) Variables d'environnement Railway (minimum)

Configurer ces variables dans Railway:

- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://<votre-domaine-railway>`
- `APP_KEY=` (**obligatoire**, générer avec `php artisan key:generate --show` puis coller la valeur)

> Si `APP_KEY` est absent, `railway-start.sh` peut générer une clé runtime temporaire (voir `RAILWAY_AUTO_GENERATE_APP_KEY`). Pour la prod, définis toujours `APP_KEY` en variable Railway.

Base de données MySQL Railway (service DB relié):

- `DB_CONNECTION=mysql`
- `DB_HOST=<MYSQLHOST>`
- `DB_PORT=<MYSQLPORT>`
- `DB_DATABASE=<MYSQLDATABASE>`
- `DB_USERNAME=<MYSQLUSER>`
- `DB_PASSWORD=<MYSQLPASSWORD>`

Variables Laravel recommandées pour un premier déploiement:

- `CACHE_DRIVER=file`
- `SESSION_DRIVER=file`
- `QUEUE_CONNECTION=sync`

Variables de contrôle auto-migration (optionnelles):

- `RAILWAY_RUN_MIGRATIONS=true` (défaut)
- `RAILWAY_MIGRATION_MAX_RETRIES=10` (défaut)
- `RAILWAY_MIGRATION_RETRY_DELAY=5` secondes (défaut)
- `RAILWAY_FAIL_ON_MIGRATION_ERROR=false` (défaut, laisse l'app démarrer même si migration KO)
- `RAILWAY_STORAGE_LINK=true` (défaut)
- `RAILWAY_AUTO_GENERATE_APP_KEY=true` (défaut)

Variables de mode routes (installation/update):

- `INSTALLATION_MODE=false` (défaut: mode application normal)
- `ENABLE_UPDATE_ROUTES=false` (défaut: routes update désactivées)

### 3) Initialisation après premier déploiement

Les migrations sont exécutées automatiquement au démarrage via `railway-start.sh`.

Si tu veux le faire manuellement depuis un shell Railway:

```bash
php artisan migrate --force
php artisan storage:link
```

Si votre projet dépend du dump SQL fourni (`shop.sql`), importez-le dans la base Railway à la place de `migrate`.

### 4) Notes importantes

- Le stockage local Railway est éphémère. Pour les uploads persistants, configurez S3 (variables AWS dans `.env.example`).
- Vérifiez les permissions d'écriture sur `storage/` et `bootstrap/cache/` (Railway/Nixpacks les gère en général correctement).
- En environnement avec plusieurs instances, éviter de lancer les migrations sur toutes les instances en parallèle (désactiver `RAILWAY_RUN_MIGRATIONS` sur les réplicas si nécessaire).

### 5) En cas d'erreur `npm i` / `node-sass` sur Railway

Si Railway tente encore un build Docker/Node, vérifie dans **Settings > Build** du service :

1. Builder = **Nixpacks** (pas Dockerfile)
2. Redéploie le dernier commit contenant `nixpacks.toml`
3. Optionnel: Clear build cache puis redeploy

### 6) Si tu tombes sur "CHECKING FILE PERMISSIONS" (installateur)

Sur Railway en production, tu ne dois pas rester sur l'installateur.

Vérifie ces variables:

- `INSTALLATION_MODE=false`
- `ENABLE_UPDATE_ROUTES=false`

Puis redeploy. Le projet chargera alors les routes normales (`web`, `api`, `admin`, etc.) au lieu des routes d'installation uniquement.


