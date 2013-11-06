Stuff
=====
usefull scripts/thoughts etc

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
