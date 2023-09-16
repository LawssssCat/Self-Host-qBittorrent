#!/bin/bash

# env
source ./set-env.sh

# Source library of functions
source ../lib/qb.shlib
source ../lib/qb.web-api.shlib

# ready
if [ -z "$example_torrent_hashs" ]; then
    echo "=========== get a torrent ==========="
    source torrents_get.sh >/dev/null
    example_torrent_hashs="$(echo "$example_torrent_json" | $jq_executable '.hash' -r)"
    if [ -n "$example_torrent_hashs" ]; then
        echo "ok"
    else
        echo "fail" >&2
        exit $EXIT_ERROR
    fi
fi

echo "=========== the list of torrent hash ==========="
example_torrent_hashs="$(lines_trim "$example_torrent_hashs")"
echo "$example_torrent_hashs"

# run
echo "=========== the list of trackers of torrent hash ==========="
for h in $example_torrent_hashs; do 
    echo "hash: $h"
    get_torrent_trackers "$h" || {
        echo "response status:"
        echo "$qbt_webapi_response_status"
        echo "error message:"
        echo "$qbt_webapi_response_error"
        exit $EXIT_ERROR
    } >&2
    example_torrent_trackers_json="$qbt_webapi_response_body"
    echo "$example_torrent_trackers_json" | $jq_executable ".| to_entries[]" -c || exit $EXIT_ERROR
done
