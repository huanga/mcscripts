var express = require("express");
var dns = require('dns');
var net = require('net');
var app = express();
var Memcached = require('memcached');

// maxKeySize: 250       => keep keys shorter than 250 characters
// maxExpiration: 300000 => 5 minutes cache life
// keyCompression: true  => compress keys if they exceed maxKeySize
var memcached = new Memcached("127.0.0.1:11211", {maxKeySize:250,maxExpiration:300000,keyCompression:true});
memcached.on('failure', function( details ){ sys.error( "Server " + details.server + "went down due to: " + details.messages.join( '' ) ) });
memcached.on('reconnecting', function( details ){ sys.debug( "Total downtime caused by server " + details.server + " :" + details.totalDownTime + "ms")});

function clean_string(str) {
	if (str == undefined) { return ""; }
	return(str.replace(/\u0000/g,''));
}

function mcslp(server, port, req, res) {
	var log_time = new Date();
	var log_timestamp = log_time.getFullYear() + "-" + (log_time.getMonth()+1) + "-" + log_time.getDate() + " " + log_time.getHours() + ":" + log_time.getMinutes() + ":" + log_time.getSeconds();
	var start_time = (new Date()).getTime();
	var client = net.createConnection(port, server);
	client.setTimeout(10000, function(evt) {
		console.log("[" + log_timestamp + "] Timed-out on query for: " + server + ":" + port + ", by: " + req.ip);
		client.destroy();
		var result = { error : "Server down, or firewall filtered." };
		res.send(JSON.stringify(result));
	});
	client.on('connect', function() {
		buf = new Buffer(2);
		buf[0] = 0xFE;
		buf[1] = 0x01;
		client.write(buf);
	}).on('data', function(data) {
		var end_time = (new Date()).getTime();
		data = data.toString();
		data = data.split('\x00\x00');
		
		var result = {
			protocol	: clean_string(data[1]),
			server_ver	: clean_string(data[2]),
			motd		: clean_string(data[3]),
			online_count	: clean_string(data[4]),
			slots		: clean_string(data[5]),
			ping		: (end_time - start_time),
			checktime	: start_time
		};
		var memcache_key = server + ":" + port;
		memcached.set(memcache_key, result, 30, function( err, result ){ if (err) { console.log(err); }});
		res.send(JSON.stringify(result));
		end_time = null;
		start_time = null;
		console.log("[" + log_timestamp + "] Processed query for: " + server + ":" + port + ", by: " + req.ip);
	}).on('error', function(err) {
		var result = { error : "Server down, or firewall filtered." };
		res.send(JSON.stringify(result));
	});
}

function lookup_via_cache(server, port, req, res) {
	var memcache_key = server + ":" + port;
	memcached.get(memcache_key, function( err, result ) {
		if (err) {
			// memcache server error
			mcslp(server, port, req, res);
		} else if (result == false) {
			// not in records
			mcslp(server, port, req, res);
		} else {
			// already in cache
			result.cached = true;
			res.send(JSON.stringify(result));
		}
	});
}

app.get('/', function(req, res){
	var server = req.query["server"];
	var port   = req.query["port"];

	if ((port != undefined) && (server != undefined)) {
		// When people provide both, they probably want the A record instead of SRV!
		lookup_via_cache(server, port, req, res);
	} else {
		dns.resolve('_minecraft._tcp.' + server, 'SRV', function(err, address) {
			if (err) {
				if (port == undefined) { port = 25565; }
				lookup_via_cache(server, port, req, res);
			} else {
				address.forEach(function (a) {
					server = a.name;
					port = a.port;
					lookup_via_cache(server, port, req, res);
				}); 
			}
		});
	}
});

// Listen on port 31948
app.listen(31948);
