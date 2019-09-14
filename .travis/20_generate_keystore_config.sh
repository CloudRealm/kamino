#!/bin/bash
STORE_PASSWORD="$1"
KEY_PASSWORD="$2"
KEY_ALIAS="$3"

cat <<____HERE
storePassword=`echo "$STORE_PASSWORD"`
keyPassword=`echo "$KEY_PASSWORD"`
keyAlias=`echo "$KEY_ALIAS"`
storeFile=/home/travis/key.jks
____HERE