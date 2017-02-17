#!/bin/sh

## Preparing all the variables like IP, Hostname, etc, all of them from the container
sleep 5
DATA_DIR=/var/lib/zimbra
HOSTNAME=$(hostname -s)
DOMAIN=$(hostname -d)
CONTAINERIP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
RANDOMHAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMSPAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMVIRUS=$(date +%s|sha256sum|base64|head -c 10)

echo "Configuring DNS Server"
cat <<EOF > /etc/bind/named.conf.options
options {
directory "/var/cache/bind";

listen-on { localnets; }; # ns1 private IP address - listen on private network only
allow-transfer { none; }; # disable zone transfers by default

forwarders {
  127.0.0.11;
  8.8.8.8;
  8.8.4.4;
};
auth-nxdomain no; # conform to RFC1035
#listen-on-v6 { any; };
};
EOF
cat <<EOF > /etc/bind/named.conf.local
zone "$DOMAIN" {
        type master;
        file "/etc/bind/db.$DOMAIN";
};
EOF
cat <<EOF > /etc/bind/db.$DOMAIN
\$TTL  604800
@      IN      SOA    ns1.$DOMAIN. root.localhost. (
                              2        ; Serial
                        604800        ; Refresh
                          86400        ; Retry
                        2419200        ; Expire
                        604800 )      ; Negative Cache TTL
;
@     IN      NS      ns1.$DOMAIN.
@     IN      A      $CONTAINERIP
@     IN      MX     10     $HOSTNAME.$DOMAIN.
$HOSTNAME     IN      A      $CONTAINERIP
ns1      IN      A      $CONTAINERIP
mail     IN      A      $CONTAINERIP
pop3     IN      A      $CONTAINERIP
imap     IN      A      $CONTAINERIP
imap4    IN      A      $CONTAINERIP
smtp     IN      A      $CONTAINERIP
EOF

cat <<EOF > /etc/resolv.conf
nameserver 127.0.0.1
options ndots:0
EOF

#service rsyslog start
service bind9 start
service cron start
service ssh start

if [ ! -f /opt/zimbra/initial-setup-config ]; then
  link_to_data_basenames="backup conf contrib data db fbqueue index initial-setup-config log logger redolog ssl store zmstat"
  link_to_data_dir() {
    cd /opt/zimbra
    $@
    for link in $link_to_data_basenames; do
      ln -s $DATA_DIR/$link $link
    done
  }
  if [ -f $DATA_DIR/initial-setup-config ]; then
    echo "Just reconfiguring/updating Zimbra"
    link_to_data_dir rm -rf $link_to_data_basenames
  else
    echo "Configuring Zimbra from scratch"
    ##Creating the Zimbra Collaboration Config File ##
    cat <<EOF > /opt/zimbra/initial-setup-config
AVDOMAIN="$DOMAIN"
AVUSER="admin@$DOMAIN"
CREATEADMIN="admin@$DOMAIN"
CREATEADMINPASS="$PASSWORD"
CREATEDOMAIN="$DOMAIN"
DOCREATEADMIN="yes"
DOCREATEDOMAIN="yes"
DOTRAINSA="yes"
EXPANDMENU="no"
HOSTNAME="$HOSTNAME.$DOMAIN"
HTTPPORT="8080"
HTTPPROXY="TRUE"
HTTPPROXYPORT="80"
HTTPSPORT="8443"
HTTPSPROXYPORT="443"
IMAPPORT="7143"
IMAPPROXYPORT="143"
IMAPSSLPORT="7993"
IMAPSSLPROXYPORT="993"
INSTALL_WEBAPPS="service zimlet zimbra zimbraAdmin"
JAVAHOME="/opt/zimbra/java"
LDAPAMAVISPASS="$PASSWORD"
LDAPPOSTPASS="$PASSWORD"
LDAPROOTPASS="$PASSWORD"
LDAPADMINPASS="$PASSWORD"
LDAPREPPASS="$PASSWORD"
LDAPBESSEARCHSET="set"
LDAPHOST="$HOSTNAME.$DOMAIN"
LDAPPORT="389"
LDAPREPLICATIONTYPE="master"
LDAPSERVERID="2"
MAILBOXDMEMORY="972"
MAILPROXY="TRUE"
MODE="https"
MYSQLMEMORYPERCENT="30"
POPPORT="7110"
POPPROXYPORT="110"
POPSSLPORT="7995"
POPSSLPROXYPORT="995"
PROXYMODE="https"
REMOVE="no"
RUNARCHIVING="no"
RUNAV="yes"
RUNCBPOLICYD="no"
RUNDKIM="yes"
RUNSA="yes"
RUNVMHA="no"
SERVICEWEBAPP="yes"
SMTPDEST="admin@$DOMAIN"
SMTPHOST="$HOSTNAME.$DOMAIN"
SMTPNOTIFY="yes"
SMTPSOURCE="admin@$DOMAIN"
SNMPNOTIFY="yes"
SNMPTRAPHOST="$HOSTNAME.$DOMAIN"
SPELLURL="http://$HOSTNAME.$DOMAIN:7780/aspell.php"
STARTSERVERS="yes"
SYSTEMMEMORY="3.8"
TRAINSAHAM="ham.$RANDOMHAM@$DOMAIN"
TRAINSASPAM="spam.$RANDOMSPAM@$DOMAIN"
UIWEBAPPS="yes"
UPGRADE="yes"
USESPELL="yes"
VERSIONUPDATECHECKS="TRUE"
VIRUSQUARANTINE="virus-quarantine.$RANDOMVIRUS@$DOMAIN"
ZIMBRA_REQ_SECURITY="yes"
ldap_bes_searcher_password="$PASSWORD"
ldap_dit_base_dn_config="cn=zimbra"
ldap_nginx_password="$PASSWORD"
mailboxd_directory="/opt/zimbra/mailboxd"
mailboxd_keystore="/opt/zimbra/mailboxd/etc/keystore"
mailboxd_keystore_password="$PASSWORD"
mailboxd_server="jetty"
mailboxd_truststore="/opt/zimbra/java/jre/lib/security/cacerts"
mailboxd_truststore_password="changeit"
postfix_setgid_group="postdrop"
ssl_default_digest="sha256"
zimbraFeatureBriefcasesEnabled="Enabled"
zimbraFeatureTasksEnabled="Enabled"
zimbraIPMode="ipv4"
zimbraMailProxy="FALSE"
#zimbraMtaMyNetworks="127.0.0.0/8 $CONTAINERIP/24 [::1]/128 [fe80::]/64"
zimbraPrefTimeZoneId="Europe/Kiev"
zimbraReverseProxyLookupTarget="TRUE"
zimbraVersionCheckNotificationEmail="admin@$DOMAIN"
zimbraVersionCheckNotificationEmailFrom="admin@$DOMAIN"
zimbraVersionCheckSendNotifications="TRUE"
zimbraWebProxy="FALSE"
zimbra_ldap_userdn="uid=zimbra,cn=admins,cn=zimbra"
zimbra_require_interprocess_security="1"
INSTALL_PACKAGES="zimbra-core zimbra-ldap zimbra-logger zimbra-mta zimbra-snmp zimbra-store zimbra-apache zimbra-spell zimbra-memcached zimbra-proxy"
EOF
  fi
  /opt/zimbra/libexec/zmsetup.pl -c /opt/zimbra/initial-setup-config
  if [ ! -f $DATA_DIR/initial-setup-config ]; then
    mkdir -p $DATA_DIR
    echo "Stopping Zimbra"
    sudo -i -u zimbra zmcontrol stop
    sleep 20
    echo "Moving data apart from code to the separate directory which conveniently can be a volume"
    link_to_data_dir mv $link_to_data_basenames $DATA_DIR
    #echo "Extra step to configure syslog to avoid 'Some services are not running' as well as 'Message: system failure: Unable to read logger stats Error code: service.FAILURE Method: [unknown] Details:soap:Receiver'"
    #service rsyslog stop
    #pkill rsyslog
    #./libexec/zmsyslogsetup
  fi
fi

if ! pgrep java; then
  echo "Starting Zimbra"
  sudo -i -u zimbra zmcontrol start
fi

if [ $1 == "-d" ]; then
  while true; do sleep 1000; done
fi

if [ $1 == "-bash" ]; then
  /bin/bash
fi
