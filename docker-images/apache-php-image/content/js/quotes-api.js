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
                $("#container-ip").text("Container ip : " + quotes[0].container_ip);
            }           
        });
    };
    
    loadQuotes();
    setInterval(loadQuotes, 5000);
});
