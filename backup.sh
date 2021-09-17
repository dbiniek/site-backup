#! /bin/bash

#Where to put the files
DEST='/backup/site-backups/'
#Archive file name
DATE=$(date +%F)
HOSTNAME=$(hostname -s)
ARCHIVE="$HOSTNAME-$date.tar.gz"
#with the following list of domains:
awk '$1 == "ServerAlias" {print $2}' /etc/httpd/sites-enabled/*.conf | uniq > /tmp/domains.txt
#echo "cat /tmp/domains.txt"
#cat /tmp/domains.txt

###Make the sql bups, since I only have WP sites and HTML sites, I'll only worry about wordpress dbs here for now###
#Make an array of domain names that have wp-config.php files currently and save domains and configs for later
mapfile -t DOMAINS < <(find /var/www/ -type f -name "wp-config.php" | awk -F"/" '{print $4}')
WP_CONFIGS="$(find /var/www/ -type f -name "wp-config.php")"

#Database Credentials with name, user, pass in array so we can do all at once
HOST="localhost"
mapfile -t DB_NAMES < <(awk -F"'" '$2 ~ /DB_N/ {print $4}' ${WP_CONFIGS})
mapfile -t DB_USERS < <(awk -F"'" '$2 ~ /DB_U/ {print $4}' ${WP_CONFIGS})
mapfile -t DB_PASSWORDS < <(awk -F"'" '$2 ~ /DB_P/ {print $4}' ${WP_CONFIGS})
##Make the actual .sql dump files to our backup directory
for ((i=0;i<${#DB_NAMES[@]};++i)); do
    mysqldump -h $HOST -u "${DB_USERS[i]}" -p"${DB_PASSWORDS[i]}" "${DB_NAMES[i]}" >> $DEST/${DOMAINS[i]}-$DATE.sql
done

#Backup the other files for each domain
#while read $domain ; do
#	tar -czf $DEST/$domain-$DATE.tar.gz /var/www/$domain
#echo "$domain"
#done < /tmp/domains.txt

for domain in $(cat /tmp/domains.txt) ; do
	tar -czf $DEST/$domain-$DATE.tar.gz /var/www/$domain
done
