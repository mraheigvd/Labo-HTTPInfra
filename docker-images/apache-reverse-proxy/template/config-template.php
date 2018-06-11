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
