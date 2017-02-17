#################################################################
# Dockerfile to build Zimbra Collaboration 8.6 container images
# Based on Ubuntu 14.04
# Created by Jorge de la Cruz
#################################################################
FROM ubuntu:16.04
MAINTAINER Jorge de la Cruz <jorgedlcruz@gmail.com>

RUN \
  mkdir -p /var/lib/resolvconf && touch /var/lib/resolvconf/linkified && \
  apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
  wget \
  openssh-client \
  bind9 \
  bind9utils \
  bind9-doc \
  dnsutils \
  libidn11 \
  libpcre3 \
  libgmp10 \
  libexpat1 \
  libstdc++6 \
  libperl5.22 \
  libaio1 \
  netcat-openbsd \
  pax \
  resolvconf \
  sqlite3 \
  sudo \
  sysstat \
  unzip \
  dialog \
  apt-utils \
  lsb-release \
  rsyslog \
  openssh-server \
  cron \
  vim \
  mc

#VOLUME ["/opt/zimbra"]

EXPOSE 22 25 465 587 110 143 993 995 80 443 8080 8443 7071

COPY opt /opt/

##Install the Zimbra Collaboration ##
RUN \
  wget https://files.zimbra.com/downloads/8.7.2_GA/zcs-8.7.2_GA_1736.UBUNTU16_64.20170131053933.tgz \
#  wget https://files.zimbra.com/downloads/8.6.0_GA/zcs-8.6.0_GA_1153.UBUNTU14_64.20141215151116.tgz \
  && tar xzvf zcs-*.tgz && rm zcs-*.tgz && cd zcs-* \
  && /bin/bash -c '\
                   hostname() { echo zimbra.localdomain; }; \
                   export -f hostname; \
                   echo "127.0.0.1 `hostname`" >> /etc/hosts; \
                   echo -e "y\ny\ny\ny\ny\nn\ny\ny\ny\ny\ny\ny\ny\ny\n" | ./install.sh -s \
                  '\
  && rm -rf /zcs-* \
  && ln -s /opt/zimbra/common/lib/jvm/openjdk-1.8.0_92-zimbra /opt/zimbra/java \
  && sed "s/-u/-4 -u/g" /etc/default/bind9 > /etc/default/bind9.new \
  && mv /etc/default/bind9.new /etc/default/bind9

CMD ["/bin/bash", "/opt/start.sh", "-d"]
