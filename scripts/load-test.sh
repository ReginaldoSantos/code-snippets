#!/bin/bash

##############################################################################################
# Simple load testing script to hit your server endpoint as many times as you want.
#
#  Use:
#
#   1. 
#     bash load-test.sh 10 "http://server.com/api/endpoint"
# 
#   2.
#     curl -L https://raw.githubusercontent.com/ReginaldoSantos/code-snippets/master/scripts/load-test.sh | bash -s 10 "http://server.com/api/endpoint"
#
##############################################################################################

max="$1"
date
echo "url: $2
rate: $max calls / second"
START=$(date +%s);

##############################################################################################
# A verbose and silent cURL to make the HTTP Request.
# The results are piped to tr which removes all the newline.
# In the end, with the help of awk results are appended at /temp/load-test.log
##############################################################################################
get () {
  curl -s -v "$1" 2>&1 | tr '\r\n' '\\n' | awk -v date="$(date +'%r')" '{print $0"\n-----", date}' >> /tmp/load-test.log
}

while true
do

  # Printing minute and second of each execution
  echo $(($(date +%s) - START)) | awk '{print int($1/60)":"int($1%60)}'
  sleep 1

  for i in `seq 1 $max`
  do
    get $2 &
  done
done
