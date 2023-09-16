#!/bin/bash

# env
source ./set-env.sh

# Source library of functions
source ../lib/qb.shlib
source ../lib/qb.web-api.shlib

# ready
echo "=========== mock trackers ==========="
: ${example__mock_trackers:="
http://tracker.electro-torrent.pl/announce
http://1337.abcvg.info/announce
https://trackme.theom.nz:443/announce
https://tr.abiir.top/announce
https://tracker.gbitt.info/announce
udp://tracker.sylphix.com:6969/announce
"}
echo "\"$example__mock_trackers\""

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
echo "=========== remove torrent trackers ==========="
example__torrent_hash="$(echo "$example_torrent_hashs" | head -n 1)"
example__mock_trackers="$(echo "$example__mock_trackers" | lines_trim)"
remove_torrent_trackers "$example__torrent_hash" "$(lines_join '|' "$example__mock_trackers")" && {
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

# check
echo "=========== check ==========="
get_torrent_trackers "$example__torrent_hash" || {
    echo "response status:"
    echo "$qbt_webapi_response_status"
    echo "error message:"
    echo "$qbt_webapi_response_error"
    exit $EXIT_ERROR
} >&2
example__torrent_trackers="$(echo "$qbt_webapi_response_body" | $jq_executable ".[]" -c)"
while read example__mock_tracker; do
    if ! echo "$example__torrent_trackers" | grep "$example__mock_tracker"; then
        continue
    fi
    echo "find $example__mock_tracker" >&2
    exit $EXIT_ERROR
done <<< "$example__mock_trackers"
echo "ok"
