#!/bin/sh


echo "================================================================================" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

echo "================================================================================" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

echo "\n\n\t\t$0" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

echo "\n$ date" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt 
date >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

echo "\n$ set -x"  >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt
set -x

echo "\n$ pwd" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt ; pwd >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

echo "\n$ sudo service postgresql start" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt
sudo service postgresql start >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

echo "\n$ sudo service nginx start" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt
sudo service nginx start >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

echo "\n$ pwd" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt ; pwd >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

echo "\n$ cd /home/kit/kit/ " >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt
cd /home/kit/kit/

echo "\n$ pwd" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt ; pwd >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

echo "\n$ sudo nohup shotgun config.ru -p 9000 -o 0.0.0.0 & " >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt
sudo nohup shotgun config.ru -p 9000 -o 0.0.0.0 & >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

#
################################################################################
#
echo "================================================================================"  >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt
echo "\n\n\t\tChecking status of VM ...\n" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

echo "\n$ sudo lsof -i tcp:9000" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt
sudo lsof -i tcp:9000 >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

echo "\n$ sudo service postgresql status" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt
sudo service postgresql status >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

echo "\n$ sudo service nginx status" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt
sudo service nginx status >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt
echo "\n[DONE]\n================================================================================" >> /home/kit/kit/uploads/snk/kitvm/log_rc-local.txt

