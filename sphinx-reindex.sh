#!/bin/sh

set -e

# Download sample 100k file if missing
if [ ! -f /data/input/data.tsv -a ! -f /data/input/data.tsv.gz ]; then
    mkdir -p /data/input/
    curl -L -s https://github.com/OSMNames/OSMNames/releases/download/v1.1/planet-latest-100k.tsv.gz \
        -o /data/input/planet-latest-100k.tsv.gz
    ln /data/input/planet-latest-100k.tsv.gz /data/input/data.tsv.gz
fi

# Index files, only if not exists, or forced by the script
if [ ! -f /data/index/ind_name_prefix_0.spa -o "$1" = "force" ]; then
    mkdir -p /data/index/
    set +e
    /usr/bin/indexer -c /etc/sphinxsearch/sphinx.conf --rotate --all
    rc=$? && [ $rc -eq 1 ] && exit $rc
    set -e
    touch /tmp/osmnames-sphinxsearch-data.timestamp
fi

# Start sphinx job in supervisor
if [ -z "`pidof searchd`" ]; then
    supervisorctl -c /etc/supervisor/supervisord.conf start sphinx
fi
