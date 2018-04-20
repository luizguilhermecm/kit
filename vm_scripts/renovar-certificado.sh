#!/bin/bash

# Script to be used when the certificate to use https here.
#
# Known Issues:
#   At the first time, after ran this the nginx did not start with 
#       "$ service nginx start"
#   kit just went up when this VM was restarted with 
#       "$ reboot"
#   Once there is a script to run at start up the kit gets to work.

service nginx stop
cd /etc/letsencrypt
./letsencrypt-auto --text --agree-tos --email luizgui@gmail.com certonly --renew-by-default -d lgcm.com.br -d lgcm.com.br
service nginx start
