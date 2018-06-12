# Labo-HTTPInfra
RES course - Final big lab

This is a simple report for showing the choices and configurations of our solution.

# Step 1: Static HTTP server with apache httpd

Simple Docker container with PHP 5.6 and default apache.

The container is very simple and will simply serve the local content directory on top of apache at /var/www/html.

```
FROM php:5.6-apache

RUN apt-get update && \
 apt-get install -y vim

COPY content/ /var/www/html/
```

PHP will be used later for showing the current container IP.

# Step 2: Dynamic HTTP server with express.js

In order to be more creative we decided to write a simple API which sends random famous quotes.

Below the js script used for that with express framework :

```js
var express = require('express');
var app = express();

app.get('/', function(req, res){
    res.send(getQuotes());
});

app.listen(3000, function(){
    console.log('Accepting HTTP requests on port 3000!');
});

function getQuotes(){
    
    var quotes = [
        " « I could either watch it happen or be a part of it. » ",
        " « When something is important enough, you do it even if the odds are not in your favor. » ",
        " « You shouldn't do things differently just because they're different. They need to be... better. » ",
        " « Failure is an option here. If things are not failing, you are not innovating enough. » ",
        " « The starting point of all achievement is desire. » ",
        " « Nothing in the world is more common than unsuccessful people with talent. » ",
        " « Don't be afraid to give up the good to go for the great. » ",
        " « I have not failed. I've just found 10,000 ways that won't work. » "
    ];
    
    console.log(quotes);
    var q = [ { "quote": quotes[Math.floor(Math.random() * quotes.length)]} ];
    return q;
}
```

For that, we created a docker container with this configuration :


```
FROM node:4.4

RUN apt-get update && \
 apt-get install -y vim

COPY src /opt/app

WORKDIR /opt/app/
RUN npm install

CMD ["node", "/opt/app/index.js"]
```

At the build we install node js dependecies and at the run we sympla run node ../index.js

# Step 3: Reverse proxy with apache (static configuration)


For using the hostname, you must provide an IP alias at : ```/etc/hosts```

Add this line : (the first IP is gived by : ```docker-machine ip```)

```bash
192.168.99.100  demo.res.ch
```

All apache configurations are stored under a conf directory which contains a sites-available directory with these files:

- 000-default.conf :

```
<VirtualHost *:80>
</VirtualHost>
```

- 001-reverse-proxy.conf :

```
<VirtualHost *:80>
    ServerName demo.res.ch
    
    ProxyPass "/api/quotes/" "http://172.17.0.3:3000/"
    ProxyPassReverse "/api/quotes/" "http://172.17.0.3:3000/"
    
    ProxyPass "/" "http://172.17.0.2:80/"
    ProxyPassReverse "/" "http://172.17.0.2:80/" 
</VirtualHost>
```

Now, we can test our apache server by simply using curl/postman/broser within the docker machine like that :

```
docker-machine ssh
telnet 172.17.0.3 3000
```

when it's done, we have to build our Docker container with this basic dockerfile :

```
#specify apache version
FROM php:5.6-apache

COPY conf/ /etc/apache2/

RUN a2enmod proxy proxy_http
RUN a2ensite 000-* 001-*
```

Now, we can simply test our apache server by calling demo.res.ch and demo.res.ch/api/quotes

# Step 4: AJAX requests with JQuery

We will do simple ajax requests with jQuery libraries. For that we downloaded an HTML template website from https://startbootstrap.com/ and added it to a content directory.

Here is the Dockerfile associated which run php 5.6 and apache :

```
FROM php:5.6-apache

RUN apt-get update && \
 apt-get install -y vim

COPY content/ /var/www/html/
```

On content directory we added a quote-api.js file at content/js/ with the following content :

```js
$(function() {
    console.log("Loading quotes");
    
    function loadQuotes(){
        $.getJSON("/api/quotes/", function(quotes){
            console.log(quotes);
            var message = "No quotes !";
	        console.log(quotes.length);
            if(quotes.length > 0){
                message = quotes[0];
                console.log("Message : " + quotes[0].quote);
                $("#quote").text(quotes[0].quote);
            }           
        });
    };
    
    loadQuotes();
    setInterval(loadQuotes, 5000);
});
```

Every 5 seconds, we consume quotes through the api exposes with express container.

Last but not least, we edited the content/index.html in order to add our script at the end of body (lazy loading) :

```html
    <script src="js/quotes-api.js"></script>
```

# Step 5: Dynamic reverse proxy configuration

For this part we had some difficulties with the version of apache2-foreground quoted on the webcasts.
So we decided to get the last version of apache2-foreground from the docker hub.

The reverse proxy configuration receive informations through the env variables by using php inside it and overwrite the 001-reverse-proxy.conf :

```
<?php 
    $STATIC_APP = getenv('STATIC_APP');
    $DYNAMIC_APP = getenv('DYNAMIC_APP');
?>

<VirtualHost *:80>
    ServerName demo.res.ch
    
    ProxyPass '/api/quotes/' 'http://<?php print "$DYNAMIC_APP" ?>/'
    ProxyPassReverse '/api/quotes/' 'http://<?php print "$DYNAMIC_APP" ?>/'
    ProxyPass '/' 'http://<?php print "$STATIC_APP" ?>/'
    ProxyPassReverse '/' 'http://<?php print "$STATIC_APP" ?>/' 
</VirtualHost>
```

# Load balancing: multiple server nodes (0.5pt)

For adding the load balancing between apache servers we changed the configuration like that :

```
<?php
  $dynamic_app1 = getenv('DYNAMIC_APP1');
  $dynamic_app2 = getenv('DYNAMIC_APP2');
  $static_app1 = getenv('STATIC_APP1');
  $static_app2 = getenv('STATIC_APP2');
?>

<VirtualHost *:80>
    ServerName demo.res.ch
    
    <Proxy "balancer://quotesset">
        BalancerMember 'http://<?php print "$dynamic_app1"?>'
        BalancerMember 'http://<?php print "$dynamic_app2" ?>'
    </Proxy>
    
    <Proxy "balancer://webserverset">
        BalancerMember 'http://<?php print "$static_app1" ?>/'
        BalancerMember 'http://<?php print "$static_app2" ?>/'
    </Proxy>
    
    ProxyPass '/api/quotes/' 'balancer://quotesset/'
    ProxyPassReverse '/api/quotes/' 'balancer://quotesset/'
    
    ProxyPass '/' 'balancer://webserverset/'
    ProxyPassReverse '/' 'balancer://webserverset/' 
</VirtualHost>
```

After changing the configuration, we need to enable some apache modules used for the load balancing :

```
RUN a2enmod proxy_balancer status lbmethod_byrequests headers
```

# Load balancing: round-robin vs sticky sessions (0.5 pt)

We configured a sticky session for statics containers. For that we followed this procedure : https://cwiki.apache.org/confluence/display/OFBIZ/Sticky+session+load+balancing+with+Apache+and+mod_balancer

So we edited the config-template.php file of apache-reverse-proxy :

```
<?php
  $dynamic_app1 = getenv('DYNAMIC_APP1');
  $dynamic_app2 = getenv('DYNAMIC_APP2');
  $static_app1 = getenv('STATIC_APP1');
  $static_app2 = getenv('STATIC_APP2');
?>

<VirtualHost *:80>
    ServerName demo.res.ch

    #sticky session
    Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED
    
    <Proxy "balancer://quotesset">
        BalancerMember 'http://<?php print "$dynamic_app1"?>'
        BalancerMember 'http://<?php print "$dynamic_app2" ?>'
    </Proxy>
    
    <Proxy "balancer://webserverset">
	# Make it with a foreach in order to add dynamicaly members
        BalancerMember 'http://<?php print "$static_app1" ?>/' route=1
        BalancerMember 'http://<?php print "$static_app2" ?>/' route=2
	ProxySet stickysession=ROUTEID
    </Proxy>
    
    ProxyPass '/api/quotes/' 'balancer://quotesset/'
    ProxyPassReverse '/api/quotes/' 'balancer://quotesset/'
    
    ProxyPass '/' 'balancer://webserverset/'
    ProxyPassReverse '/' 'balancer://webserverset/' 
</VirtualHost>
```

The changes are :

```
Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED
```

and we added the route id at webserverset proxy balancer :

```
<Proxy "balancer://webserverset">
    # Make it with a foreach in order to add dynamicaly members
    BalancerMember 'http://<?php print "$static_app1" ?>/' route=1
    BalancerMember 'http://<?php print "$static_app2" ?>/' route=2
    ProxySet stickysession=ROUTEID
</Proxy>
```

Then we enabled the module header on the Dockerfile :

```
RUN a2enmod proxy_balancer status lbmethod_byrequests headers
```

Now, if we open a browser and request the page we can see via the header (which show the container IP) that we're always redirected at the same container IP with sticky session.

# Management UI (0.5 pt)

For this part we simply used an opensource docker image called portainer.io.
This container allow you to easily manage docker hosts through a good UI.

For that we created a simple shell script which deploy Portainer :

```bash
#!/bin/bash
docker volume create portainer_data
docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
```



