Stuff
=====
usefull scripts/thoughts etc

ripple_phonegap3.patch (diff - patch File)
----------------------
- Download latest ripple version 

```
git clone https://git-wip-us.apache.org/repos/asf/incubator-ripple.git
```

- Download ripple_phonegap3.patch
- Copy ripple_phonegap3.patch in your ripple directory
- run ```patch -p1 < ripple_phonegap3.patch```
- run ```./configure``` to configure ripple (possibly you need sudo/root privileges)
- run ```jake```

To test it create a new phonegap hello world application, change in the new app directory and run ripple
(in my case it's located in /tmp/incubator-ripple)

```
phonegap create testRipple
cd testRipple
/tmp/incubator-ripple/bin/ripple emulate
```

now you should see "Device is Ready" in the emulator.

 

setup_tileserver_ubuntu12.04lts.sh
----------------------------------
This file downloads and sets up a complete tileserver.

It donwloads and configure
- BOOST
- POSTGIS
- OSM2PGSQL
- MAPNIK
- MODTILE
- RENDERD
- OSM MAPNIK-STYLESHEET

First install Ubuntu 12.04 LTS Server (with PostgreSQL), then Download this script and run it as root.
When it's finished you have to start the renderd by typing
```
/etc/init.d/renderd start
```
in the console and restart the apache server
```
/etc/init.d/apache2 restart
```
then you can generate your first tile by browsing to
```
http://localhost/osm_tiles/0/0/0.png
```
on that machine.

Thanks to http://switch2osm.org (http://switch2osm.org/serving-tiles/manually-building-a-tile-server-12-04/) for that great tutorial!
