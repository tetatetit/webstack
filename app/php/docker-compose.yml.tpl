#!/bin/bash

cat <<END
$NOEDIT_MSG

# This file for running it both as standalone and/or as part of another project
# e.g "docker-compose -p <project> -f <this_file> -f <file2> -f <file3>  up -d"

version: '2'
services:
  php:
    image: $IMAGE_OUT:$TAG
    volumes:
      - www:/var/www
    restart: always
END

