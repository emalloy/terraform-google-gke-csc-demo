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
  echo "stackdriver logging agent already installed! Continue!"
fi
}

function galera_repo {

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

if [[  $(grep $(hostname -I) /etc/mysql/my.cnf ) ]]; then
  echo "Galera is probably already configured. Continue ...";
else
  sed -i 's/^datadir.*/datadir\ =\ \/data\/lib\/mysql/g' \
   /etc/mysql/my.cnf  \
   && sed -i "s|127.0.0.1|$(hostname -I)|" \
   /etc/mysql/my.cnf
  cat << EOF > /etc/mysql/conf.d/50-galera.cnf
[galera]
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_name="${WSREP_CLUSTER_NAME}"
wsrep_cluster_address="gcomm://${WSREP_MEMBERS}"
wsrep_node_address=$(hostname -I)
wsrep_node_name="$(hostname -s)"
wsrep_sst_method=rsync
binlog_format=row
EOF
fi
}

check_disk
logging_agent
galera_repo
galera_conf
if [[ ! -f /tmp/.mysql-stackdriver-been-setup ]]; then
  configure_mysql_monitoring_agent
fi


