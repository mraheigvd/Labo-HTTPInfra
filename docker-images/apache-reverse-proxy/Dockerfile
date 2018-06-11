FROM php:5.6-apache

RUN apt-get update && \
 apt-get install -y vim
 
# THE proxy
COPY template /var/apache2/templates
COPY conf/ /etc/apache2/
COPY apache2-foreground /usr/local/bin/

RUN a2enmod proxy proxy_http
RUN a2ensite 000-* 001-*

# Load balancing purpose
RUN a2enmod proxy_balancer status lbmethod_byrequests headers

#docker build -t res/apache_rp .
#docker run -e STATIC_APP=172.17.0.2:80 -e STATIC_APP2=172.17.0.3:80 -e DYNAMIC_APP=172.17.0.4:3000 -e DYNAMIC_APP2=172.17.0.5:3000 -p 8080:80 res/apache_rp

