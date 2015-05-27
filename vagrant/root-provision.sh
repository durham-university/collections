#!/bin/sh

yum -y install \
	java-1.7.0-openjdk \
	libreoffice-calc \
	libreoffice-draw \
	libreoffice-headless \
	libreoffice-impress \
	libreoffice-math \
	libreoffice-writer \
	mariadb-devel \
	openssl-devel \
	readline-devel \
	sqlite-devel \
	zlib-devel \
	ImageMagick \
	redis \
	ruby \
	ruby-devel \
	wget

# Download and set up FITS
wget -O /tmp/fits.zip http://projects.iq.harvard.edu/files/fits/files/fits-0.8.4.zip
unzip -d /opt/ /tmp/fits.zip
mv /opt/fits-0.8.4 /opt/fits
chmod a+x /opt/fits/fits.sh

# Enable redis service so that it starts on boot
systemctl enable redis.service

# Start redis now
systemctl start redis.service
