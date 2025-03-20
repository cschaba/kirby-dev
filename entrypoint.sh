#!/bin/sh

memcached -d --user=www-data &

apache2ctl -D FOREGROUND
