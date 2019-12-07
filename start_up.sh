#!/bin/sh
echo "\n[DONE]\n================================================================================" 
date >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

set -x

service postgresql start 

service nginx start 

echo "\n$ cd /home/kit/kit/ " 
cd /home/kit/kit/

echo "\n[DONE]\n================================================================================" 
echo "\n$ sudo nohup shotgun config.ru -p 9000 -o 0.0.0.0 & " 
nohup shotgun config.ru -p 9000 -o 0.0.0.0 & 

echo "\n$ sudo lsof -i tcp:9000" 
lsof -i tcp:9000 

echo "\n$ sudo service postgresql status" 
service postgresql status 

echo "\n$ sudo service nginx status" 
service nginx status 
echo "\n[DONE]\n================================================================================" 

