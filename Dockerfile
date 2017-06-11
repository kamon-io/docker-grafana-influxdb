FROM	ubuntu:14.04

ENV GRAFANA_VERSION 4.3.2
ENV INFLUXDB_VERSION 0.9.5.1

# Prevent some error messages
ENV DEBIAN_FRONTEND noninteractive

#RUN		echo 'deb http://us.archive.ubuntu.com/ubuntu/ trusty universe' >> /etc/apt/sources.list
RUN		apt-get -y update && apt-get -y upgrade

# ---------------- #
#   Installation   #
# ---------------- #

# Install all prerequisites
RUN 	apt-get -y install wget nginx-light supervisor curl

#RUN 	apt-get -y install software-properties-common
#RUN		add-apt-repository -y ppa:chris-lea/node.js && apt-get -y update
#RUN		apt-get -y install python-django-tagging python-simplejson python-memcache python-ldap python-cairo \
#			python-pysqlite2 python-support python-pip gunicorn nodejs git openjdk-7-jre build-essential python-dev

# Install Grafana to /src/grafana
RUN		mkdir -p src/grafana && cd src/grafana && \
			wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-${GRAFANA_VERSION}.linux-x64.tar.gz -O grafana.tar.gz && \
			tar xzf grafana.tar.gz --strip-components=1 && rm grafana.tar.gz


# Install InfluxDB
RUN		wget http://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
			dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && rm influxdb_${INFLUXDB_VERSION}_amd64.deb

# ----------------- #
#   Configuration   #
# ----------------- #

# Configure InfluxDB
ADD		influxdb/config.toml /etc/influxdb/config.toml 
ADD		influxdb/run.sh /usr/local/bin/run_influxdb
# These two databases have to be created. These variables are used by set_influxdb.sh and set_grafana.sh
ENV		PRE_CREATE_DB data grafana
ENV		INFLUXDB_HOST localhost:8086
ENV		INFLUXDB_GRAFANA_USER grafana
ENV		INFLUXDB_GRAFANA_PW grafana
ENV		ROOT_PW root

# Configure Grafana
ADD             ./grafana/config.ini /etc/grafana/config.ini
ADD		grafana/run.sh /usr/local/bin/run_grafana
ADD		./configure.sh /configure.sh
ADD		./set_grafana.sh /set_grafana.sh
ADD		./set_influxdb.sh /set_influxdb.sh
RUN 		/configure.sh

# Configure nginx and supervisord
ADD		./nginx/nginx.conf /etc/nginx/nginx.conf
ADD		./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ----------- #
#   Cleanup   #
# ----------- #

RUN		apt-get autoremove -y wget curl && \
			apt-get -y clean && \
			rm -rf /var/lib/apt/lists/* && rm /*.sh

# ---------------- #
#   Expose Ports   #
# ---------------- #

# Grafana
EXPOSE	3000

# InfluxDB Admin server
EXPOSE	8083

# InfluxDB HTTP API
EXPOSE	8086

# InfluxDB HTTPS API
EXPOSE	8084

# -------- #
#   Run!   #
# -------- #

CMD		["/usr/bin/supervisord"]
