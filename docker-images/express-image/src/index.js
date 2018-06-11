var ip = require('ip');
var CURRENT_CONTAINER_IP=ip.address();


var Chance = require('chance');
var chance = new Chance();

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
    var q = [ { "quote": quotes[Math.floor(Math.random() * quotes.length)], "container_ip": CURRENT_CONTAINER_IP } ];
    return q;
}
