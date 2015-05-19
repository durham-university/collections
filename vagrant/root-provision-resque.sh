#!/bin/sh

# Copy service files
cp /vagrant/etc/systemd/system/opt-sufia-wait.service /etc/systemd/system/opt-sufia-wait.service
cp /vagrant/etc/systemd/system/resque-pool.service /etc/systemd/system/resque-pool.service

# Enable opt-sufia-wait service so that it starts on boot
systemctl enable opt-sufia-wait.service

# Enable resque-pool service so that it starts on boot
systemctl enable resque-pool.service

# Start resque-pool now
systemctl start resque-pool.service
