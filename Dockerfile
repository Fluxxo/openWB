FROM debian:buster-slim
ARG DEBIAN_FRONTEND=noninteractive
COPY entrypoint.sh /entrypoint.sh
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN useradd -ms /bin/bash pi \
    && apt-get update \
	&& apt-get install -y --no-install-recommends \
		apt-utils \
		ca-certificates \
		cron \
		curl \
		iproute2 \
		iputils-ping \
		net-tools \
		python3 \
		python3-dev \
        sudo

RUN apt-get -q -y install nano vim bc apache2 php php-gd php-curl php-xml php-json libapache2-mod-php jq i2c-tools git mosquitto mosquitto-clients socat python-pip python3-pip sshpass
#RUN sudo && rm -r /var/lib/apt/lists/* && c_rehash 
RUN printf "[global]\nextra-index-url=https://www.piwheels.org/simple\n" > /etc/pip.conf
RUN pip install -U pymodbus 
#RUN pip install Adafruit_MCP4725
RUN pip3 install paho-mqtt

COPY ./web/files/mosquitto.conf /etc/mosquitto/conf.d/openwb.conf

RUN echo 'upload_max_filesize = 300M' > /etc/php/7.3/apache2/conf.d/20-uploadlimit.ini
RUN echo 'post_max_size = 300M' >> /etc/php/7.3/apache2/conf.d/20-uploadlimit.ini

RUN apt-get update && \
    apt-get install -yq tzdata && \
    ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN echo "i2c-dev" >> /etc/modules && \
	echo "i2c-bcm2708" >> /etc/modules && \
	echo "snd-bcm2835" >> /etc/modules && \
	echo "dtparam=i2c1=on" >> /etc/modules && \
	echo "dtparam=i2c_arm=on" >> /etc/modules

RUN printf "* * * * * /var/www/html/openWB/regel.sh >> /var/log/openWB.log 2>&1\n\
* * * * * sleep 10 && /var/www/html/openWB/regel.sh >> /var/log/openWB.log 2>&1\n\
* * * * * sleep 20 && /var/www/html/openWB/regel.sh >> /var/log/openWB.log 2>&1\n\
* * * * * sleep 30 && /var/www/html/openWB/regel.sh >> /var/log/openWB.log 2>&1\n\
* * * * * sleep 40 && /var/www/html/openWB/regel.sh >> /var/log/openWB.log 2>&1\n\
* * * * * sleep 50 && /var/www/html/openWB/regel.sh >> /var/log/openWB.log 2>&1\n" | crontab - 
RUN echo "pi ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/010_pi-nopasswd
RUN echo "www-data ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/010_pi-nopasswd

RUN chmod +x /entrypoint.sh
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]