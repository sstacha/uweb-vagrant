#!/bin/bash
# script to optimize images

inotifywait -m /home/ubuntu/website/docroot -e create -e modify -e delete -e moved_to -e moved_from |
    while read path action file; do
        
        echo "'$action' -> ['$path''$file']"
        # do something with the file
    done