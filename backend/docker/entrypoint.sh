#!/bin/sh
set -e

# Render fournit le port d'écoute dans $PORT.
sed -i "s/Listen 80$/Listen ${PORT:-10000}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:${PORT:-10000}>/" /etc/apache2/sites-available/000-default.conf

# Render « generateValue » produit une clé base64 de 256 bits sans le préfixe attendu par Laravel.
case "$APP_KEY" in
  base64:*) ;;
  "") echo "APP_KEY manquante" >&2; exit 1 ;;
  *) export APP_KEY="base64:$APP_KEY" ;;
esac

mkdir -p storage/app/public storage/app/private storage/framework/cache storage/framework/sessions storage/framework/views storage/logs
chown -R www-data:www-data storage bootstrap/cache

php artisan storage:link --force >/dev/null 2>&1 || true
php artisan migrate --force
# Crée / met à jour le compte admin à partir de ADMIN_EMAIL / ADMIN_PASSWORD (pas de données démo en production).
php artisan db:seed --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

exec "$@"
