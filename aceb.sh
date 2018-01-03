#!/usr/bin/env bash

# Folders (or files) that should be backed up.
folders=(/etc /var)

# Used during testing so critical data that should be later backed up are not compromised by some bug. 
#test_folders=(af bf cf)

# Files contanining passwords that are used during backup process.
enc_pass=""
disk_pass=""
db_pass=""
back_jrn=""


# Location where backup will be stored
disk_location=""
log_file="/var/log/aceb.log"

cbp=$(awk -F: '{print $1}' $back_jrn) 	# current backup phase
mbp=14 					# maximum backup phases
arch_name=$cbp.tar


function log() {
  echo "`date +"%d-%m-%Y.%H:%M:%S"` |"$2"| "$1"" >> $log_file
}


function dump_mysql() {
	dbpwd=$(cat "$db_pass")
	mysqldump --opt -usefino -p$dbpwd --all-databases > /root/db.sql
	
	if [ $? -ne 0 ]; then
		log "Failed to create DB dump. Error: $?" "critical"
		exit 1
	fi
}


function archive() {
	tar -cpf $arch_name ${folders[@]}

	if [ $? -ne 0 ]; then
		log "Failed to archive all files to archive [$arch_name]. Error: $?" "critical"
		exit 1
	fi
}


function compress() {	
	ls $arch_name

	if [ $? -ne 0 ]; then
		log "Compression failed. No archive to compress. Error: $?" "critical"
		exit 1
	fi

	lzma $arch_name

	if [ $? -ne 0 ]; then
		log "Compression failed. Failed to compress archive [$arch_name]. Error: $?" "critical"
		exit 1
	fi
}


function encrypt() {
	openssl aes-256-cbc -e -in $arch_name.lzma -out $arch_name.arch -pass file:$enc_pass
	if [ $? -ne 0 ]; then
		log "Failed to encrypt file $arch_name.lzma. Error: $?" "critical"
		exit 1
	fi
}


function backup() {
	rsync --password-file=$disk_pass $arch_name.arch $disk_location
	if [ $? -ne 0 ]; then
		log "Failed to send $arch_name.arch to disk. Error: $?" "critical"
		exit 1
	fi
}


function update_journal() {
	last=$(awk -F: '{print $2}' $back_jrn)
	now=$(date +"%d%m%Y")

	# today backup already ran so we just overwrite todays backup and do not increase phase counter
	# because we are still in last backup phase.
	if [ $last -eq $now ]; then
		return
	else
		nbp=$(((cbp+1) % mbp)) # increase backup phase. nbp = next backup phase
		echo "$nbp:$now" > $back_jrn
	fi
}


function clean() {
	rm -f $arch_name.arch
	rm -f $arch_name.lzma
	rm -f /root/db.sql
}


### BACKUP

log "Backup of system started" "normal"

dump_mysql
archive
compress
encrypt
backup
update_journal
clean

log "Backup of system done!" "normal"

exit 0
