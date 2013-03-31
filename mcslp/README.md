MCSLP (MinecCraft Server List Ping) Checker

-------------------------------------------

Author: Andy Huang { mc: huang_a @ mc.chiisana.net (not an email); r: /u/chiisana; t: @AndyHuang  }

Checks the server status of a given server. Performs SRV record lookup as needed. When results are obtained, cache the record into memcached for 30 seconds so it doesn't hammer the server.

NO WARRANTY OF ANY SORTS, IMPLIED OR SPECIFIED. IF I SAY I WILL PROVIDE WARRANTY, I AM PROBABLY DRUNK AND AM NOT BE TAKEN SERIOUSLY!

Requires following npm modules:

* express
* memcached
