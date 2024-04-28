#!/bin/bash

set -euo pipefail

pid="$1"
shift

inotifywait --event create --event delete --event modify --event move \
    -m --format '%w%f' -r "$@" | \
while read modify; do
    printf '%s\n' "Detected change to $modify, reloading uWSGI..."
    kill -HUP "$pid"
done
