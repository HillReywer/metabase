#!/bin/sh

USER='PUT_USER_HERE'

TARGET='/backup/metadb'

DATE=$(date +'%Y%m%d%H%M')

mysqldump -u $USER DB_NAME_HERE --all-tablespaces | /bin/gzip > $TARGET/mysql.dump.$DATE.sql.gz