#!/bin/bash

# env
source ./set-env.sh

# Source library of functions
source ../lib/qb.shlib
source ../lib/qb.web-api.shlib

# ready
echo "=========== mock trackers ==========="
: ${example__trackers:="
http://tracker.electro-torrent.pl/announce
http://1337.abcvg.info/announce
https://trackme.theom.nz:443/announce
https://tr.abiir.top/announce
https://tracker.gbitt.info/announce
udp://tracker.sylphix.com:6969/announce
"}
echo "\"$example__trackers\""

# run
echo "=========== json add_trackers ==========="
example__preferences_json="$($jq_executable --null-input \
    --arg add_trackers "$example__trackers" \
    '{"add_trackers":$add_trackers}')" || exit $EXIT_ERROR
echo "$example__preferences_json"

echo "=========== set add_trackers ==========="
set_app_preferences "$example__preferences_json" && {
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
echo "=========== get add_trackers from app ==========="
get_app_preferences || {
    echo "response status:"
    echo "$qbt_webapi_response_status"
    echo "error message:"
    echo "$qbt_webapi_response_error"
    exit $EXIT_ERROR
} >&2
example__add_trackers_now=$(echo "$qbt_webapi_response_body" | $jq_executable ".add_trackers" -r) || exit $EXIT_ERROR
echo "\"$example__add_trackers_now\""

echo "=========== check ==========="
example__add_trackers_num="$(lines_number "$example__trackers")"
example__add_trackers_now_num="$(lines_number "$example__add_trackers_now")"
if [ "$example__add_trackers_num" -eq "$example__add_trackers_now_num" ]; then
    echo "ok!"
else 
    echo "exception! FETCH,NOW=$example__add_trackers_num,$example__add_trackers_now_num" >&2
    exit $EXIT_ERROR
fi
