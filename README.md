# proxsee
Threaded application to find open proxies
* http transparent
* http anonymous
* socks4
* socks5

Seeking can be performed randomly, or ranged.
GeoIP country codes are displayed when an open proxy is found

Your mileage may vary with the '--threads' option. Start with 50, and if your system doesn't come to a halt, try increasing it only then.

# Usage Examples

Seek a range
```
$ ./sockseeker --range=69.x.x.x/16 --port=1080 --timeout=10 --threads=100
SOCKS4 [US] (103ms) 69.x.x.13:1080
Anonymous HTTP [RU] (223ms) 69.x.x.24:1080
SOCKS5 [CH] (153ms) 69.x.x.47:1080
SOCKS4 [US] (13ms)  69.x.x.98:1080

...
```

Seek random hosts
```
$ ./sockseeker --port=1337 --timeout=10 --threads=100
SOCKS5 [DE] (33ms) 101.x.2.x:1337
Transparent HTTP [IR] (513ms) 77.x.x.24:1337
SOCKS5 [GB] (251ms) x.x.43.47:1337
Anonymous HTTP [ZA] (32ms)  x.134.x.98:1337

...

```

# License
GPLv3 (See LICENSE)
