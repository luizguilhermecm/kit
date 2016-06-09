#!/bin/sh

set -x 
sudo kill -9 $(lsof -i tcp:9000 | awk '{if(NR>1)print $2}') ;
