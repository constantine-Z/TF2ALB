#!/bin/bash

# Переменные среды
DB_HOST=${DB_HOST:-"pgaws.pam4.com"}
DB_USER=${DB_USER:-"dbuser"}
DB_PASS=${DB_PASS:-"password"}
DB_NAME=${DB_NAME:-"dbwebaws"}
S3_BUCKET=${S3_BUCKET:-"s3://constantine-z-2/"}


DUMP_FILE_PATH="${S3_BUCKET}${DB_NAME}_backup.dump"


echo "Downloading database dump from S3..."
aws s3 cp ${DUMP_FILE_PATH} ~/dbwebaws_backup.dump


echo "Waiting for the PostgreSQL database to become ready..."
max_attempts=50
attempt_no=0
until PGPASSWORD=$DB_PASS psql -h $DB_HOST -U $DB_USER -l; do
  ((attempt_no++))
  echo "Database is not ready yet. Attempt $attempt_no of $max_attempts. Retrying..."
  sleep 10
  if [ $attempt_no -ge $max_attempts ]; then
    echo "Failed to connect to PostgreSQL after $max_attempts attempts."
    exit 1
  fi
done


echo "Restoring database from dump..."
PGPASSWORD=$DB_PASS pg_restore -h $DB_HOST -U $DB_USER -d $DB_NAME -v ~/dbwebaws_backup.dump

echo "Database restoration complete."
