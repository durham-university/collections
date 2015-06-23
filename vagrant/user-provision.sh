#!/bin/sh

echo "gem: --no-rdoc --no-ri" > ~/.gemrc

gem install bundler rails

cd /opt/sufia

bundle install

rake db:migrate

rake jetty:clean
rake sufia:jetty:config

# Move fcrepo4-data directory to local file system
mkdir /tmp/fcrepo4-data
ln -s /tmp/fcrepo4-data jetty/

rake jetty:start

# Downloads and imports languages and funders local authorities
rake authority_import:all
