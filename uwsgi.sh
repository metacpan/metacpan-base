#!/bin/bash

script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [[ "$PLACK_ENV" == "development" ]]; then
    pid="$$"
    (
        set -m
        "$script_dir/watcher.sh" "$pid" lib *.conf &
    )
fi

exec /usr/bin/uwsgi \
    --plugins psgi \
    --http-socket-modifier1 5 \
    --ini "/etc/uwsgi.ini" \
    "$@" \
    --psgi app.psgi
