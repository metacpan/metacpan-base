#!/bin/bash

script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
pid="$$"
uwsgi_ini="/etc/uwsgi.ini"

if [[ "$PLACK_ENV" == "development" ]]; then
    if [[ -e '/etc/uwsgi-development.ini' ]]; then
        uwsgi_ini="/etc/uwsgi-development.ini"
    fi
    (
        set -m
        "$script_dir/watcher.sh" "$pid" lib *.conf &
    )
fi

exec /usr/bin/uwsgi \
    --plugins psgi \
    --http-socket-modifier1 5 \
    --ini /etc/uwsgi.ini \
    "$@" \
    --psgi app.psgi
