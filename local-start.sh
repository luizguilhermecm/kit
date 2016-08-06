#!/bin/sh

kill -9 $(lsof -i tcp:4567 | awk '{if(NR>1)print $2}') ;
shotgun config.ru -p 4567 -o 0.0.0.0;
