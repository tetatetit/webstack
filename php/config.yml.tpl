#!/bin/bash

cat <<END
# This file used to run standalone project only.
# Feel free to tweak it for your needs to add/override
# any any keys of 'php' and 'http' services

version: '2'
services:
  php:
    ports:
      - "2222:22"
END
[[ $TAG != *apache* ]] && cat <<END
  http:
    image: nginx
    ports:
END
cat <<END
      - "80:80"
      - "443:443"
END
