#!/bin/sh

cd ${CRACKERJACK_DESTINATION}

sudo -Eu cj -- flask db migrate
sudo -Eu cj -- flask db upgrade

exec "$@"