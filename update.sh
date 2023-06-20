#!/bin/bash
set -e

read -p "Enter version: " version

DOWNLOAD_URL="https://downloads.metabase.com/$version/metabase.jar"
APP_PATH="/opt/metabase/metabase.jar"
BACKUP_PATH="/root/metabase.backup.$(date +"%Y%m%d")"
SSH_DESTINATION=""
DB_BACKUP_CMD="sh /backup/backup.sh"
HEALTH_CHECK_URL="https://METABASE_SERVER_DNS/api/health"

echo "Downloading new version $version from $DOWNLOAD_URL"
wget $DOWNLOAD_URL || { echo "Download failed"; exit 1; }

echo "Stopping Metabase service"
systemctl stop metabase.service

echo "Backup process"

echo "Backing up application"
cp $APP_PATH $BACKUP_PATH || { echo "Application backup failed"; exit 1; }

echo "Backing up database"
ssh $SSH_DESTINATION $DB_BACKUP_CMD || { echo "Database backup failed"; exit 1; }

echo "Removing previous version"
rm -rf $APP_PATH || { echo "Failed to remove previous version"; exit 1; }

echo "Copying new version"
mv metabase.jar $APP_PATH || { echo "Failed to move new version"; exit 1; }

echo "Setting permissions"
chmod +x $APP_PATH && chown metabase:metabase $APP_PATH || { echo "Failed to set permissions"; exit 1; }

echo "Starting Metabase service"
systemctl start metabase.service

echo "Waiting for 10 seconds before performing health check"
sleep 10

echo "Performing health check"
response=$(curl --write-out "%{http_code}" --silent --output /dev/null $HEALTH_CHECK_URL)

if [ "$response" -ne 200 ]; then
    echo "Health check failed with HTTP status $response"
    exit 1;
else
    echo "Health check successful"
fi

systemctl status metabase.service
