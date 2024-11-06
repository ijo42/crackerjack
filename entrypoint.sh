#!/bin/sh

cd /opt/web/crackerjack

sudo -Eu cj -- flask db migrate
sudo -Eu cj -- flask db upgrade

exec "$@"