#!/bin/bash
# From JAmesiii

echo "\n### Kill all containers...\n"
docker kill $(docker ps -qa)

echo "\n### Remove all container...\n"
docker rm $(docker ps -qa)

echo "\n### Build apache_static\n"
docker build -t res/apache_php ./apache-php-image/

echo "\n### Build express_dynamic\n"
docker build -t res/express ./express-image/

echo "\n### Build apache_rp\n"
docker build -t res/apache_rp ./apache-reverse-proxy/

echo "\n### Run apache_static containers\n"
docker run -d --name apache_static1 res/apache_php
docker run -d --name apache_static2 res/apache_php

echo "\n### Run express_dynamic containers\n"
docker run -d --name express_dynamic1 res/express
docker run -d --name express_dynamic2 res/express

echo "\n### Run apache_rp"
static_app1=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' apache_static1`
static_app2=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' apache_static2`
dynamic_app1=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' express_dynamic1`
dynamic_app2=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' express_dynamic2`

echo "## IP of injected: static $static_app1, $static_app2 and dynamic $dynamic_app1, $dynamic_app2\n" 
docker run -d -p 8080:80 -e STATIC_APP1=$static_app1:80 -e STATIC_APP2=$static_app2:80 -e DYNAMIC_APP1=$dynamic_app1:3000 -e DYNAMIC_APP2=$dynamic_app2:3000 --name apache_rp res/apache_rp

echo "\n### check ip apache_static1 container\n"
docker inspect apache_static1 | grep -i ipaddress

echo "\n### check ip apache_static2 container\n"
docker inspect apache_static2 | grep -i ipaddress

echo "\n### check ip express_dynamic1 conatiner\n"
docker inspect express_dynamic1 | grep -i ipaddress

echo "\n### check ip express_dynamic2 conatiner\n"
docker inspect express_dynamic2 | grep -i ipaddress

# launch management-ui
management-ui/launch.sh

# Open browser with content
/usr/bin/open -a "/Applications/Google Chrome.app"  'http://192.168.99.100:9000/' # Management-ui 
/usr/bin/open -a "/Applications/Google Chrome.app"  'http://demo.res.ch:8080/' # demo
