#!/bin/sh
echo "\n\tshutting kit down for good"

echo "\n\nstopping nginx"
sudo service nginx stop

echo "\n\nstopping postgresql"
sudo service postgresql stop

echo "\n\nstopping shotgun 9000"
sudo kill -9 $(lsof -i tcp:4567 | awk '{if(NR>1)print $2}') ;

echo "\n\nstopping shotgun 4567"
sudo kill -9 $(lsof -i tcp:9000 | awk '{if(NR>1)print $2}') ;

echo "\n\nchecking nginx"
sudo service nginx status

echo "\n\nchecking postgresql"
sudo service postgresql status

echo "\n\nchecking TCP 9000"
sudo lsof -i tcp:9000

echo "\n\nchecking TCP 4567"
sudo lsof -i tcp:4567

