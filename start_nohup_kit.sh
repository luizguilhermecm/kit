#!/bin/sh

set -x 
sudo kill -9 $(lsof -i tcp:9000 | awk '{if(NR>1)print $2}') ;
sudo nohup shotgun config.ru -p 9000 -o 0.0.0.0 & 
