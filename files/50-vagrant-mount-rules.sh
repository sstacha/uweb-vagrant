#!/usr/bin/env bash

# Start on mount
SUBSYSTEM=="bdi",ACTION=="add",RUN+="/usr/bin/screen -m -d bash -c 'sleep 5; /etc/init.d/nginx start'"
SUBSYSTEM=="bdi",ACTION=="add",RUN+="/usr/bin/screen -m -d bash -c 'sleep 5; service uwsgi start'"

# Stop on unmount
SUBSYSTEM=="bdi",ACTION=="remove",RUN+="/usr/bin/screen -m -d bash -c 'sleep 5; /etc/init.d/nginx stop'"
SUBSYSTEM=="bdi",ACTION=="remove",RUN+="/usr/bin/screen -m -d bash -c 'sleep 5; service uwsgi stop'"