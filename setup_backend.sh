	#!/bin/bash
	
	echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
	echo "LANG=en_US.utf-8" >> /etc/environment
	echo "LC_ALL=en_US.utf-8" >> /etc/environment
	service sshd restart
	hostnamectl set-hostname backend
	amazon-linux-extras install php7.4 -y
	rm -rf /var/lib/mysql/*
	yum remove mysql -y
    yum install httpd mariadb-server -y
	systemctl restart mariadb.service
    systemctl enable mariadb.service
    mysqladmin -u root password 'mysql123'
	mysql -u root -pmysql123 -e "create database ${DB_NAME};"
	mysql -u root -pmysql123 -e "create user '${DB_USER}'@'%' identified by '${DB_PASSWD}';"
	mysql -u root -pmysql123 -e "grant all privileges on ${DB_NAME}.* to '${DB_USER}'@'%'"
	mysql -u root -pmysql123 -e "flush privileges"

