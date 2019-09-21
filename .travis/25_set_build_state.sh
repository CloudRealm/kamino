#!/bin/bash
BUILD_NUMBER="$1"

cat <<____HERE
{
  "isDevelopmentBuild": true,
  "devCode": `echo $BUILD_NUMBER`
}
____HERE