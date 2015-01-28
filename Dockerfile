FROM	ubuntu:14.04

ENV GRAFANA_VERSION 1.9.1

RUN		echo 'deb http://us.archive.ubuntu.com/ubuntu/ trusty universe' >> /etc/apt/sources.list
RUN		apt-get -y update
RUN		apt-get -y upgrade


# ---------------- #
#   Installation   #
# ---------------- #

# Install all prerequisites
RUN 	apt-get -y install software-properties-common
RUN		add-apt-repository -y ppa:chris-lea/node.js
RUN		apt-get -y update
RUN		apt-get -y install  python-django-tagging python-simplejson python-memcache python-ldap python-cairo  \
			python-pysqlite2 python-support python-pip gunicorn supervisor nginx-light nodejs \
			git wget curl openjdk-7-jre build-essential python-dev

# Install Grafana to /src/grafana
RUN		mkdir -p src/grafana && cd src/grafana && \
			wget http://grafanarel.s3.amazonaws.com/grafana-${GRAFANA_VERSION}.tar.gz -O grafana.tar.gz && \
			tar xzf grafana.tar.gz --strip-components=1 && rm grafana.tar.gz

# Install InfluxDB
RUN		apt-get update && \
			DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends curl ca-certificates && \
			curl -s -o /tmp/influxdb_latest_amd64.deb https://s3.amazonaws.com/influxdb/influxdb_latest_amd64.deb && \
			dpkg -i /tmp/influxdb_latest_amd64.deb && \
			rm /tmp/influxdb_latest_amd64.deb && \
			rm -rf /var/lib/apt/lists/*
 
# ----------------- #
#   Configuration   #
# ----------------- #

# Configure InfluxDB
ADD		influxdb/config.toml /etc/influxdb/config.toml 
ADD		influxdb/RUN.sh /usr/local/bin/RUN_influxdb
RUN		chmod 0755 /usr/local/bin/RUN_influxdb

# Configure Grafana
ADD		./grafana/config.js /src/grafana/config.js
#ADD	./grafana/scripted.json /src/grafana/app/dashboards/default.json

# Configure nginx and supervisord
ADD		./nginx/nginx.conf /etc/nginx/nginx.conf
ADD		./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ---------------- #
#   Expose Ports   #
# ---------------- #

# Grafana
EXPOSE	80

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
