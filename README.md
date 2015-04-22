# sockseeker
Perl script to find open SOCKS 4/5 hosts

* supply range
* random seek

Uses Geo::IP to display country code of SOCKS host

### random seek
this will seek an ip randomly

### range seek
will seek the supplied range from 1st to last

# Usage

Seek a range
```
$ ./sockseeker --range=69.x.x.x/16 --port=1080 --timeout=10 --threads=100
SOCKS4 [US] (103ms) 69.x.x.13:1080
SOCKS5 [RU] (223ms) 69.x.x.24:1080
SOCKS5 [CH] (153ms) 69.x.x.47:1080
SOCKS4 [US] (13ms)  69.x.x.98:1080
...etc
```

Seek random hosts
```
$ ./sockseeker --port=1337 --timeout=10 --threads=100
SOCKS4 [DE] (33ms) 101.x.2.x:1337
SOCKS5 [IR] (513ms) 77.x.x.24:1337
SOCKS5 [GB] (251ms) x.x.43.47:1337
SOCKS4 [ZA] (32ms)  x.134.x.98:1337
.....etc

```

# License
GPLv3 (See LICENSE)
