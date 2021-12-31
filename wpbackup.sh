#!/bin/bash
source .env
cd ~/
mysqldump -u $dbuser -p$sqlpass --add-drop-table -h localhost $db | bzip2 -c > $db.sql.bz2
cp -Rp
