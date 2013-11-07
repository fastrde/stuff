#!/bin/sh

CFG_DATA_URL=http://download.geofabrik.de/europe/germany/nordrhein-westfalen/duesseldorf-regbez-latest.osm.pbf #LOCATION OF OSM-DATA-FILE
CFG_USERNAME=gis        #POSTGRES-DATABASE-USERNAME
CFG_APACHENAME=www-data #APACHE-USERNAME
CFG_PASSWORD=gis        #POSTGRES-DATABASE-USER-PASSWORD
CFG_DATABASE=gis        #POSTGRES-DATABASE-NAME
CFG_HOSTNAME=localhost  #POSTGRES-DATABASE-HOSTNAME
CFG_PORT=5432           #POSTGRES-DATABASE-PORT

echo "CONFIGURE FIRST!"; exit; #THEN REMOVE THIS LINE

#FOR THE FIRST INSTALL SET ALL TO 1

CREATE_GIS_USER=1      #SHOULD I CREATE A SYSTEM-USER FOR THE DATABASE?
INSTALL_ADD_APT=1      #SHOULD I ADD THE NEEDED PPA REPOSITORIES?
INSTALL_BOOST=1        #SHOULD I INSTALL BOOST?
INSTALL_DEPS=1         #SHOULD I INSTALL DEPENDENCIES?
INSTALL_POSTGIS=1      #SHOULD I INSTALL POSTGIS?
INSTALL_OSM2PGSQL=1    #SHOULD I INSTALL OSM2PGSQL?
INSTALL_MAPNIK=1       #SHOULD I INSTALL MAPNIK?
INSTALL_MODTILE=1      #SHOULD I INSTALL MOD_TILE?
INSTALL_STYLESHEET=1   #SHOULD I INSTALL THE OSM MAPNIK-STYLESHEET?

CONFIGURE_STYLESHEET=1 #SHOULD I CONFIGURE THE STYLESHEET?
CONFIGURE_RENDERD=1    #SHOULD I CONFIGURE RENDERD?
CONFIGURE_MOD_TILE=1   #SHOULD I CONFIGURE MOD_TILE?

TUNE_POSTGRES=1        #SHOULD I TWEAK POSTGRES-DB? (HAVE A LOOK AT THE SETTINGS!)

IMPORT_DATA=1          #SHOULD I IMPORT DATA TO THE DB? (CAN TAKE SOME TIME)

START_TILESERVER=1     #SHOULD I ADD THE INIT-SCRIPTS ETC. FOR THE TILESERVER

if [ $CREATE_GIS_USER -eq 1 ]; then
  adduser $CFG_USERNAME --gecos ",,," --disabled-password
  echo "$CFG_USERNAME:$CFG_PASSWORD"|chpasswd
fi

if [ $INSTALL_ADD_APT -eq 1 ]; then
  apt-get -y install software-properties-common
fi

if [ $INSTALL_BOOST -eq 1 ]; then
  echo "[+] installing Boost";
  add-apt-repository -y ppa:mapnik/boost
  apt-get -y update
  apt-get -y install libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-python-dev libboost-regex-dev libboost-system-dev libboost-thread-dev
fi

if [ $INSTALL_DEPS -eq 1 ]; then
  echo "[+] installing Dependencies";
  apt-get -y install subversion git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libpq-dev libbz2-dev proj munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libpng12-dev libtiff4-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont
fi

if [ $INSTALL_POSTGIS -eq 1 ]; then
  echo "[+] installing PostGIS";
  apt-get -y install postgresql-9.1-postgis postgresql-contrib postgresql-server-dev-9.1
  su - postgres -c "createuser -D -R -S $CFG_USERNAME"	
  su - postgres -c "createdb -E UTF8 -O $CFG_USERNAME $CFG_DATABASE"	
  su - postgres -c "psql -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql -d $CFG_DATABASE"
  su - postgres -c "psql -d $CFG_DATABASE -c \"ALTER TABLE geometry_columns OWNER TO $CFG_USERNAME; ALTER TABLE spatial_ref_sys OWNER TO $CFG_USERNAME;\""
  su - postgres -c "psql -d $CFG_DATABASE -c \"ALTER ROLE $CFG_USERNAME PASSWORD '$CFG_PASSWORD'\""
fi

if [ $INSTALL_OSM2PGSQL -eq 1 ]; then
  echo "[+] installing osm2pgsql";
  cd /tmp
  git clone git://github.com/openstreetmap/osm2pgsql.git
  cd osm2pgsql
  ./autogen.sh
  ./configure
  make && make install
  su - postgres -c "psql -f /usr/local/share/osm2pgsql/900913.sql -d $CFG_DATABASE" 
fi

if [ $INSTALL_MAPNIK -eq 1 ]; then
  echo "[+] installing Mapnik";
  cd /tmp
  git clone git://github.com/mapnik/mapnik
  cd mapnik
  git branch 2.0 origin/2.0.x
  git checkout 2.0
  python scons/scons.py configure INPUT_PLUGINS=all OPTIMIZATION=3 
  SYSTEM_FONTS=/usr/share/fonts/truetype/
  python scons/scons.py && python scons/scons.py install
  ldconfig
fi

if [ $INSTALL_MODTILE -eq 1 ]; then
  echo "[+] installing mod_tile";
  cd /tmp
  git clone git://github.com/openstreetmap/mod_tile.git
  cd mod_tile
  ./autogen.sh
  ./configure
  make && make install && make install-mod_tile
  ldconfig
fi

if [ $INSTALL_STYLESHEET -eq 1 ]; then
  echo "[+] installing OSM Mapnik-Stylesheet";
  cd /tmp
  svn co http://svn.openstreetmap.org/applications/rendering/mapnik mapnik-style
  cd mapnik-style
  ./get-coastlines.sh /usr/local/share
fi

if [ $CONFIGURE_STYLESHEET -eq 1 ]; then
  echo "[+] cunfigure OSM Mapnik-Stylesheet";
  cd /tmp/mapnik-style/inc
	
  sed '{
         s/%(symbols)s/symbols/
         s/%(epsg)s/900913/
         s/%(world_boundaries)s/\/usr\/local\/share\/world_boundaries/
         s/%(prefix)s/planet_osm/
  }' settings.xml.inc.template > settings.xml.inc

  sed "{
         s/%(password)s/$CFG_PASSWORD/
         s/%(host)s/$CFG_HOSTNAME/
         s/%(port)s/$CFG_PORT/
         s/%(user)s/$CFG_USERNAME/
         s/%(dbname)s/$CFG_DATABASE/
         s/%(estimate_extent)s/false/
         s/%(extent)s/-20037508,-19929239,20037508,19929239/
  }" datasource-settings.xml.inc.template > datasource-settings.xml.inc
  cp fontset-settings.xml.inc.template fontset-settings.xml.inc
  cp -r /tmp/mapnik-style /usr/share
fi

if  [ $CONFIGURE_RENDERD -eq 1 ]; then
  echo "[+] cunfigure renderd";
  if [ ! -f /tmp/renderd.conf.template ]; then
    cp /usr/local/etc/renderd.conf /tmp/renderd.conf.template
  fi
  sed "{
         s/;socketname=/socketname=/	
         /^plugins_dir=/ s/lib64/lib/
         /^font_dir=/    s/=.*$/=\/usr\/share\/fonts\/truetype\/ttf-dejavu/
         /^XML=/         s/XML=.*$/XML=\/usr\/share\/mapnik-style\/osm.xml/
         /^HOST=/        s/HOST=.*$/HOST=$CFG_HOSTNAME/
  }" /tmp/renderd.conf.template > /usr/local/etc/renderd.conf
fi

if  [ $CONFIGURE_MOD_TILE -eq 1 ]; then
  echo "[+] cunfigure mod_tile";
  if [ ! -f /tmp/apache_site_default ]; then
    cp /etc/apache2/sites-available/default /tmp/apache_site_default 
  fi
  mkdir /var/run/renderd
  chown $CFG_APACHENAME /var/run/renderd
  mkdir /var/lib/mod_tile
  chown $CFG_APACHENAME /var/lib/mod_tile
  echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" > /etc/apache2/conf.d/mod_tile
  sed '/^\tServerAdmin/ s/^\(.*\)$/\1\n\n\tLoadTileConfigFile \/usr\/local\/etc\/renderd.conf\n\tModTileRenderdSocketName \/var\/run\/renderd\/renderd.sock\n\tModTileRequestTimeout 0\n\tModTileMissingRequestTimeout 30\n/' /tmp/apache_site_default > /etc/apache2/sites-available/default
  /etc/init.d/apache2 restart
fi

if  [ $TUNE_POSTGRES -eq 1 ]; then
  echo "[+] tweak postgresql";
  if [ ! -f /tmp/postgresql.conf.template ]; then
    cp /etc/postgresql/9.1/main/postgresql.conf /tmp/postgresql.conf.template 
  fi
  if [ ! -f /tmp/sysctl.conf.template ]; then
    cp /etc/sysctl.conf /tmp/sysctl.conf.template 
  fi
  sed '{
         s/^shared_buffers =.*$/shared_buffers = 128MB/
         s/^#checkpoint_segments =.*$/checkpoint_segments = 20/
         s/^#maintenance_work_mem =.*$/maintenance_work_mem = 256MB/
         s/^#autovacuum =.*$/autovacuum = off/	
  }' /tmp/postgresql.conf.template > /etc/postgresql/9.1/main/postgresql.conf

  cp /tmp/sysctl.conf.template /etc/sysctl.conf
  echo "# Increase kernel shared memory segments - needed for large databases" >> /etc/sysctl.conf
  echo "kernel.shmmax=268435456" >> /etc/sysctl.conf
  sysctl -w kernel.shmmax=268435456
fi

if  [ $IMPORT_DATA -eq 1 ]; then
  echo "[+] import data";
  curl $CFG_DATA_URL > /tmp/data.osm.pbf
  su - postgres -c "osm2pgsql --slim -d $CFG_DATABASE -C 1024 --number-processes 3 /tmp/data.osm.pbf"
fi

if [ $START_TILESERVER -eq 1 ]; then
  echo "[+] configure init-scripts";
  sed '{
         s/^DAEMON=.*$/DAEMON=\/usr\/local\/bin\/$NAME/
         s/^DAEMON_ARGS=.*$/DAEMON_ARGS="-c \/usr\/local\/etc\/renderd.conf"/	
  }' /tmp/mod_tile/debian/renderd.init > /etc/init.d/renderd
  chmod 755 /etc/init.d/renderd
  ln -s /etc/init.d/renderd /etc/rc2.d/S20renderd
fi 

