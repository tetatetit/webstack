#!/bin/bash

cat <<END
$NOEDIT_MSG

# This file for run it as standalone project/stack only
# i.e. just "docker-compose -p <project> up -d" , without -f
# It adds/overrides keys of main docker-compose.yml

version: '2'
services:
  php:
    build: .
    networks:
      - mysql
    extends:
      file: config.yml
      service: php
END
[[ $TAG != *apache* ]] && cat <<END
  http:
    extends:
      file: config.yml
      service: http
    depends_on:
      - php
    volumes_from:
      - php
    restart: always
END
cat <<END
volumes:
  www:
    driver: local
networks:
  mysql:
    external:
      name: mysql_default
END
