#!/bin/bash

# env
source ./set-env.sh

# Source library of functions
source ../lib/qb.shlib
source ../lib/qb.web-api.shlib

# ready
echo "=========== the searching params ==========="
: ${example__search_params:="filter=active"}
echo "$example__search_params"

# run
echo "=========== the list of torrents ==========="
get_torrents "$example__search_params" && {
    echo "response status:"
    echo "$qbt_webapi_response_status"
    echo "response body:"
    echo "$qbt_webapi_response_body"
} || {
    echo "response status:"
    echo "$qbt_webapi_response_status"
    echo "error message:"
    echo "$qbt_webapi_response_error"
    exit $EXIT_ERROR
} >&2
example__torrents="$qbt_webapi_response_body"

# check
echo "=========== select a torrent ==========="
example_torrent_json="$(echo "$example__torrents" | $jq_executable '.[]' -c | head -n 1)" || exit $EXIT_ERROR
if [ -z "$example_torrent_json" ]; then
    echo "Unfound torrents. Please ensure that at least one torrent is active." >&2
    exit $EXIT_SKIP
fi
echo "$example_torrent_json" | $jq_executable '.'

echo "=========== parse torrent hash ==========="
echo "$example_torrent_json" | $jq_executable ".hash" -r || exit $EXIT_ERROR

export example_torrent_json
