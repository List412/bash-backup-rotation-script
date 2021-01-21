#!/bin/bash

### User Pass Mysql ###
MYSQL_HOST=localhost
MYSQL_PORT=3306
USER=backup
PASS=pass
DBNAME=dbname
BACKUP_DIR="backup/test/"
DST_HOST="user@host"
REMOTE_DST_DIR="/root/backup"
BACKUP_DAILY=true # if set to false backup will not work
BACKUP_WEEKLY=true # if set to false backup will not work
BACKUP_MONTHLY=true # if set to false backup will not work
BACKUP_RETENTION_DAILY=4
BACKUP_RETENTION_WEEKLY=3
BACKUP_RETENTION_MONTHLY=6
BACKUP_MODE='remote-local' ## Available option ( 'local-only' | 'remote-only' | 'local-remote' | 'remote-local' )
OPTIONS='--single-transaction=TRUE'

###Test daily weekly or monthly###
MONTH=`date +%d`
DAYWEEK=`date +%u`

if [[ ( $MONTH -eq 1 ) && ( $BACKUP_MONTHLY == true ) ]];
        then
        FN='monthly'
elif [[ ( $DAYWEEK -eq 7 ) && ( $BACKUP_WEEKLY == true ) ]];
        then
        FN='weekly'
elif [[ ( $DAYWEEK -lt 7 ) && ( $BACKUP_DAILY == true ) ]];
        then
        FN='daily'
fi


DATE=$FN-`date +"%Y_%m_%d_%H_%m"`

function local_remote
{
	mysqldump -u$USER -p$PASS $DBNAME  | gzip > $BACKUP_DIR/$DBNAME-mysql-$DATE.sql.gz
	cd $BACKUP_DIR/
	ls -t | grep $DBNAME | grep mysql | grep daily | sed -e 1,"$BACKUP_RETENTION_DAILY"d | xargs -d '\n' rm -R > /dev/null 2>&1
	ls -t | grep $DBNAME | grep mysql | grep weekly | sed -e 1,"$BACKUP_RETENTION_WEEKLY"d | xargs -d '\n' rm -R > /dev/null 2>&1
	ls -t | grep $DBNAME | grep mysql | grep monthly | sed -e 1,"$BACKUP_RETENTION_MONTHLY"d | xargs -d '\n' rm -R > /dev/null 2>&1
	rsync -avh --delete $BACKUP_DIR/ $DST_HOST:$REMOTE_DST_DIR
}

function local_only
{
	mysqldump -u$USER -p$PASS $DBNAME  | gzip > $BACKUP_DIR/$DBNAME-sql-$DATE.sql.gz
	cd $BACKUP_DIR/
	ls -t | grep $DBNAME | grep mysql | grep daily | sed -e 1,"$BACKUP_RETENTION_DAILY"d | xargs -d '\n' rm -R > /dev/null 2>&1
	ls -t | grep $DBNAME | grep mysql | grep weekly | sed -e 1,"$BACKUP_RETENTION_WEEKLY"d | xargs -d '\n' rm -R > /dev/null 2>&1
	ls -t | grep $DBNAME | grep mysql | grep monthly | sed -e 1,"$BACKUP_RETENTION_MONTHLY"d | xargs -d '\n' rm -R > /dev/null 2>&1
}

function remote_only
{
	mysqldump -u$USER -p$PASS $DBNAME  | gzip > $BACKUP_DIR/$DBNAME-sql-$DATE.sql.gz
	rsync -avh --remove-source-files $BACKUP_DIR/ $DST_HOST:$REMOTE_DST_DIR
	ssh -t -t $DST_HOST "cd $REMOTE_DST_DIR ; ls -t | grep $DBNAME | grep mysql | grep daily | sed -e 1,"$BACKUP_RETENTION_DAILY"d | xargs -d '\n' rm -R > /dev/null 2>&1"
	ssh -t -t $DST_HOST "cd $REMOTE_DST_DIR ; ls -t | grep $DBNAME | grep mysql | grep weekly | sed -e 1,"$BACKUP_RETENTION_WEEKLY"d | xargs -d '\n' rm -R > /dev/null 2>&1"
	ssh -t -t $DST_HOST "cd $REMOTE_DST_DIR ; ls -t | grep $DBNAME | grep mysql | grep monthly | sed -e 1,"$BACKUP_RETENTION_MONTHLY"d | xargs -d '\n' rm -R > /dev/null 2>&1"
}

function remote_local
{
	mysqldump -h $MYSQL_HOST --port $MYSQL_PORT -u $USER -p$PASS $OPTIONS $DBNAME | gzip > $BACKUP_DIR/$DBNAME-mysql-$DATE.sql.gz
	cd $BACKUP_DIR/
	ls -t | grep $DBNAME | grep mysql | grep daily | sed -e 1,"$BACKUP_RETENTION_DAILY"d | xargs -d '\n' rm -R > /dev/null 2>&1
	ls -t | grep $DBNAME | grep mysql | grep weekly | sed -e 1,"$BACKUP_RETENTION_WEEKLY"d | xargs -d '\n' rm -R > /dev/null 2>&1
	ls -t | grep $DBNAME | grep mysql | grep monthly | sed -e 1,"$BACKUP_RETENTION_MONTHLY"d | xargs -d '\n' rm -R > /dev/null 2>&1
}

if [ $BACKUP_MODE == local-remote ]; then
	if [[ ( $BACKUP_DAILY == true ) && ( ! -z "$BACKUP_RETENTION_DAILY" ) && ( $BACKUP_RETENTION_DAILY -ne 0 ) && ( $FN == daily ) ]]; then
		local_remote
	fi
	if [[ ( $BACKUP_WEEKLY == true ) && ( ! -z "$BACKUP_RETENTION_WEEKLY" ) && ( $BACKUP_RETENTION_WEEKLY -ne 0 ) && ( $FN == weekly ) ]]; then
		local_remote
	fi
	if [[ ( $BACKUP_MONTHLY == true ) && ( ! -z "$BACKUP_RETENTION_MONTHLY" ) && ( $BACKUP_RETENTION_MONTHLY -ne 0 ) && ( $FN == monthly ) ]]; then
		local_remote
	fi
elif [ $BACKUP_MODE == local-only ]; then
	if [[ ( $BACKUP_DAILY == true ) && ( ! -z "$BACKUP_RETENTION_DAILY" ) && ( $BACKUP_RETENTION_DAILY -ne 0 ) && ( $FN == daily ) ]]; then
		local_only
	fi
	if [[ ( $BACKUP_WEEKLY == true ) && ( ! -z "$BACKUP_RETENTION_WEEKLY" ) && ( $BACKUP_RETENTION_WEEKLY -ne 0 ) && ( $FN == weekly ) ]]; then
		local_only
	fi
	if [[ ( $BACKUP_MONTHLY == true ) && ( ! -z "$BACKUP_RETENTION_MONTHLY" ) && ( $BACKUP_RETENTION_MONTHLY -ne 0 ) && ( $FN == monthly ) ]]; then
		local_only
	fi
elif [ $BACKUP_MODE == remote-only ]; then
	if [[ ( $BACKUP_DAILY == true ) && ( ! -z "$BACKUP_RETENTION_DAILY" ) && ( $BACKUP_RETENTION_DAILY -ne 0 ) && ( $FN == daily ) ]]; then
		remote_only
	fi
	if [[ ( $BACKUP_WEEKLY == true ) && ( ! -z "$BACKUP_RETENTION_WEEKLY" ) && ( $BACKUP_RETENTION_WEEKLY -ne 0 ) && ( $FN == weekly ) ]]; then
		remote_only
	fi
	if [[ ( $BACKUP_MONTHLY == true ) && ( ! -z "$BACKUP_RETENTION_MONTHLY" ) && ( $BACKUP_RETENTION_MONTHLY -ne 0 ) && ( $FN == monthly ) ]]; then
		remote_only
	fi
elif [ $BACKUP_MODE == remote-local ]; then
	if [[ ( $BACKUP_DAILY == true ) && ( ! -z "$BACKUP_RETENTION_DAILY" ) && ( $BACKUP_RETENTION_DAILY -ne 0 ) && ( $FN == daily ) ]]; then
		remote_local
	fi
	if [[ ( $BACKUP_WEEKLY == true ) && ( ! -z "$BACKUP_RETENTION_WEEKLY" ) && ( $BACKUP_RETENTION_WEEKLY -ne 0 ) && ( $FN == weekly ) ]]; then
		remote_local
	fi
	if [[ ( $BACKUP_MONTHLY == true ) && ( ! -z "$BACKUP_RETENTION_MONTHLY" ) && ( $BACKUP_RETENTION_MONTHLY -ne 0 ) && ( $FN == monthly ) ]]; then
		remote_local
	fi
fi