from        ubuntu:14.04
run         echo 'deb http://us.archive.ubuntu.com/ubuntu/ trusty universe' >> /etc/apt/sources.list
run         apt-get -y update
run         apt-get -y upgrade


# ---------------- #
#   Installation   #
# ---------------- #

# Install all prerequisites
run apt-get -y install software-properties-common
run     add-apt-repository -y ppa:chris-lea/node.js
run     apt-get -y update
run     apt-get -y install  python-django-tagging python-simplejson python-memcache python-ldap python-cairo  \
                            python-pysqlite2 python-support python-pip gunicorn supervisor nginx-light nodejs \
                            git wget curl openjdk-7-jre build-essential python-dev


# Install Grafana
run     mkdir /src/grafana && cd /src/grafana &&\
        wget http://grafanarel.s3.amazonaws.com/grafana-1.7.0.tar.gz &&\
        tar xzvf grafana-1.7.0.tar.gz --strip-components=1 && rm grafana-1.7.0.tar.gz

# Install InfluxDB
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends curl ca-certificates && \
  curl -s -o /tmp/influxdb_latest_amd64.deb https://s3.amazonaws.com/influxdb/influxdb_latest_amd64.deb && \
  dpkg -i /tmp/influxdb_latest_amd64.deb && \
  rm /tmp/influxdb_latest_amd64.deb && \
  rm -rf /var/lib/apt/lists/*

 
# ----------------- #
#   Configuration   #
# ----------------- #

# Configure InfluxDB
ADD influxdb/config.toml /etc/influxdb/config.toml 
ADD influxdb/run.sh /usr/local/bin/run_influxdb
RUN chmod 0755 /usr/local/bin/run_influxdb

# Configure Grafana
add     ./grafana/config.js /src/grafana/config.js
#add     ./grafana/scripted.json /src/grafana/app/dashboards/default.json

# Configure nginx and supervisord
add     ./nginx/nginx.conf /etc/nginx/nginx.conf
add     ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf



# ---------------- #
#   Expose Ports   #
# ---------------- #

# Grafana
expose  80

# InfluxDB Admin server
EXPOSE 8083

# InfluxDB HTTP API
EXPOSE 8086

# InfluxDB HTTPS API
EXPOSE 8084



# -------- #
#   Run!   #
# -------- #

cmd     ["/usr/bin/supervisord"]
