#!/bin/bash

export IMAGE_IN=php
export IMAGE_OUT=tetatetit/php
export NOEDIT_MSG=`cat <<END
# Autogenerated by update.sh
# DO NOT EDIT IT DIRECTLY
END`

[[ $1 == --clean-configs ]] && CLEAN=yes

function gen {
  export TAG=$1
  [ $CLEAN ] && rm -rf $TAG
  [ ! -d $TAG ] && mkdir $TAG
  ./Dockerfile.tpl > $TAG/Dockerfile
  ./docker-compose.yml.tpl > $TAG/docker-compose.yml
  ./docker-compose.override.yml.tpl > $TAG/docker-compose.override.yml
  [ ! -f $TAG/config.yml ] && ./config.yml.tpl > $TAG/config.yml
}

gen 7.0-apache
gen 7.0-fpm
gen 5.6-apache
gen 5.6-fpm
