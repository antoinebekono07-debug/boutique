A complete solution for E-commerce Business with exclusive features & super responsive layout.

## Déploiement sur Railway (PHP)

Ce projet est maintenant prêt pour Railway avec un fichier `railway.json`.

### 1) Configuration déjà ajoutée au repo

- `railway.json`
  - Build: `composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction`
  - Start: `sh railway-start.sh`
- `server.php` adapté pour ce projet (front controller à la racine via `index.php`)
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
- `RAILWAY_STORAGE_LINK=true` (défaut)

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


