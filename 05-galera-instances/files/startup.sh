#!/bin/bash


function format_and_mount() {

blkid /dev/sdb
if [[ $? -ne 0 ]]; then
        echo "empty. Making filesystem ..."
        mkfs.ext4 \
          -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard \
          /dev/sdb \
          && mkdir -p /data  \
          && mount -o discard,defaults /dev/sdb /data \
          && echo "filesystem created and mounted successfully!"
else
        echo "/dev/sdb not empty!"
fi
}

function check_disk() {

lsblk /dev/sdb
if [[ $? -eq 0 ]]; then
        echo "/dev/sdb exists! Continue ..."
        format_and_mount;
else
        echo "/dev/sdb does not exist. Continue"
fi
}

function logging_agent() {
# https://cloud.google.com/logging/docs/agent
if [[ ! $(dpkg --list | grep google-fluent) ]]; then
      echo "Installing stackdriver logging agent ..."
      curl -sS -o /tmp/install-logging-agent.sh \
        https://dl.google.com/cloudagents/install-logging-agent.sh \
        && bash /tmp/install-logging-agent.sh
else
  echo "stackdriver logging agent already installed! Continue ..."
fi
}


function monitoring_agent() {
   #https://cloud.google.com/monitoring/agent/
   if [[ ! $(dpkg --list | grep stackdriver-agent ) ]]; then
     echo "Installing stackdriver monitoring agent ..."
     curl -sS -o /tmp/install-monitoring-agent.sh \
      https://dl.google.com/cloudagents/install-monitoring-agent.sh \
      && bash /tmp/install-monitoring-agent.sh
   else
     echo "stackdriver monitoring agent already installed! Continue ..."
   fi
}


function galera_repo() {
export DEBIAN_FRONTEND=noninteractive
apt-get update \
&& apt-get install dirmngr -qy

if [[ ! -f /etc/apt/sources.list.d/galera.list ]]; then
cat << EOF > /etc/apt/sources.list.d/galera.list
deb http://mirror.nodesdirect.com/mariadb/repo/10.1/debian stretch main
EOF
apt-key adv --recv-keys \
  --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
apt update \
        && apt install -yq \
        rsync \
        mariadb-server && \
        service mysql stop && \
        mkdir -p /data/lib/mysql && \
        chown -Rv mysql:mysql /data/lib/mysql && \
        rsync -az /var/lib/mysql/* /data/lib/mysql/
else
        echo "Galera repo already installed!"
fi

}

function galera_conf() {

local HEADER="Metadata-Flavor: Google"
local URI="http://metadata.google.internal/computeMetadata/v1/instance/attributes/"
local WSREP_MEMBERS=$(curl -s -H "${HEADER}" "${URI}/wsrep_members")
local WSREP_CLUSTER_NAME=$(curl -s -H "${HEADER}" "${URI}/wsrep_cluster_name")



if [[  $(grep $(hostname -I) /etc/mysql/my.cnf ) ]]; then
  echo "Galera is probably already configured. Continue ...";
else
  sed -i 's/^datadir.*/datadir\ =\ \/data\/lib\/mysql/g' \
   /etc/mysql/my.cnf  \
   && sed -i "s|127.0.0.1|$(hostname -I)|" \
   /etc/mysql/my.cnf
  cat << EOF > /etc/mysql/conf.d/50-galera.cnf
[galera]
binlog_format=row
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_name="${WSREP_CLUSTER_NAME}"
wsrep_cluster_address="gcomm://${WSREP_MEMBERS}"
wsrep_node_address=$(hostname -I)
wsrep_node_name="$(hostname -s)"
wsrep_sst_method=rsync
EOF
fi
}

02_maxscale_users() {

cat << EOF > /tmp/02_maxscale_users.sh

  #based on https://github.com/mariadb-corporation/maxscale-docker
  # https://mariadb.com/kb/en/mariadb-maxscale-23-setting-up-mariadb-maxscale/
  # poc, these values should live somewhere in process and in-perpetuity
local MAXSCALE_USER="'maxscale'"
local MAXSCALE_PASS="maxscaledemo"
local MAXSCALE_PERMITTED_CIDR="'10.21.%'"
local FE_DB_NAME="wordpress-maxscale"

cat << EOF > /tmp/maxscale_users.sql
CREATE USER ${MAXSCALE_USER}@${MAXSCALE_PERMITTED_CIDR} IDENTIFIED BY "${MAXSCALE_PASS}";
GRANT SELECT ON mysql.user TO ${MAXSCALE_USER}@${MAXSCALE_PERMITTED_CIDR};
GRANT SELECT ON mysql.db TO ${MAXSCALE_USER}@${MAXSCALE_PERMITTED_CIDR};
GRANT SELECT ON mysql.tables_priv TO ${MAXSCALE_USER}@${MAXSCALE_PERMITTED_CIDR};
GRANT SELECT ON mysql.roles_mapping TO ${MAXSCALE_USER}@${MAXSCALE_PERMITTED_CIDR};
GRANT SHOW DATABASES ON *.* TO ${MAXSCALE_USER}@${MAXSCALE_PERMITTED_CIDR};
# sample database and grant
CREATE DATABASE \`${FE_DB_NAME}\`;
CREATE USER ${MAXSCALE_USER}@${MAXSCALE_PERMITTED_CIDR} IDENTIFIED BY "${MAXSCALE_PASS}";
GRANT ALL PRIVILEGES ON \`${FE_DB_NAME}\`.* to ${MAXSCALE_USER}@${MAXSCALE_PERMITTED_CIDR};
EOF
cat /tmp/maxscale_users.sql | mysql -uroot

EOF
}

function 03_config_stackdriver_agent() {

cat << EOF > /tmp/0303_config_stackdriver_agent.sh_

#https://cloud.google.com/monitoring/agent/plugins/mysql
# https://collectd.org/wiki/index.php/Plugin:MySQL

local STATS_USER="stackdriver_user"
local STATS_PASS="thisIsADemoanditIsInsecure"
cat << EOF > /tmp/collectd.sql
CREATE USER ${STATS_USER}@'%' IDENTIFIED BY "${STATS_PASS}";
GRANT USAGE ON *.* TO ${STATS_USER}@'localhost';
GRANT REPLICATION CLIENT ON *.* TO ${STATS_USER}@'localhost';
EOF
cat /tmp/collectd.sql | mysql -uroot

cat << EOF > /opt/stackdriver/collectd/etc/collectd.d/mysql.conf
LoadPlugin mysql
<Plugin "mysql">
    # Each database needs a separate Database section.
    # Replace DATABASE_NAME in the Database section with the name of the database.
    <Database "DATABASE_NAME">
        # When using non-standard MySQL configurations, replace the below with
        #Host "MYSQL_HOST"
        #Port "MYSQL_PORT"
        Host "localhost"
        Port 3306
        User "${STATS_USER}"
        Password "${STATS_PASS}"
        MasterStats true
        SlaveStats true
    </Database>
</Plugin>
EOF
touch /tmp/.mysql-stackdriver-been-setup
service stackdriver-agent restart
EOF
}

check_disk
logging_agent
monitoring_agent
galera_repo
galera_conf

02_maxscale_users
03_config_stackdriver_agent

