#!/bin/sh
set -e

# Default values
DB_HOST="${DB_HOST:-localhost}"
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-postgres}"
DB_PORT="${DB_PORT:-5432}"

echo "Waiting for database at $DB_HOST:$DB_PORT..."

# Wait for Postgres to be ready
until PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

echo "Database is ready. Running migrations..."

# Migration files directory
MIGRATIONS_DIR="./data/migrations"

# Run migrations in alphanumeric order
for file in $(ls $MIGRATIONS_DIR/*.sql | sort); do
  echo "Applying migration: $file"
  PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" -f "$file"
done

echo "Migrations completed successfully."
