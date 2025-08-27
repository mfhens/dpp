#!/bin/sh
set -euo pipefail

# Read secrets (strip CR/LF in case files were created on Windows)
export KC_DB=postgres
export KC_DB_URL="jdbc:postgresql://postgres:5432/${POSTGRES_DB:-dpp}"
export KC_DB_USERNAME="$(tr -d '\r\n' < /run/secrets/postgres_user)"
export KC_DB_PASSWORD="$(tr -d '\r\n' < /run/secrets/postgres_password)"
export KC_BOOTSTRAP_ADMIN_USERNAME="$(tr -d '\r\n' < /run/secrets/keycloak_admin_user)"
export KC_BOOTSTRAP_ADMIN_PASSWORD="$(tr -d '\r\n' < /run/secrets/keycloak_admin_password)"

# Wait for database
echo "Waiting for database connection..."
until nc -z postgres 5432; do
  echo "Database not ready, waiting..."
  sleep 2
done

# Nice to have in dev
export KC_HEALTH_ENABLED=true
export KC_METRICS_ENABLED=true

exec /opt/keycloak/bin/kc.sh start-dev --import-realm