#!/bin/bash

# env
source ./set-env.sh

# Source library of functions
source ../lib/qb.shlib
source ../lib/qb.web-api.shlib

# ready
echo "=========== mock ban_peers ==========="
: ${example__ban_peers_mock:="
11.11.11.11:6881
22.22.22.22:6882
"}
echo "$example__ban_peers_mock"

# run
echo "=========== add ban_peers ==========="
add_ban_peers "$(lines_trim "$example__ban_peers_mock" | lines_join '|')" && {
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
echo "=========== get ban_peers ==========="
get_app_preferences || {
    echo "response status:"
    echo "$qbt_webapi_response_status"
    echo "error message:"
    echo "$qbt_webapi_response_error"
    exit $EXIT_ERROR
} >&2
example__ban_peers_now="$(echo "$qbt_webapi_response_body" | $jq_executable '. | {banned_IPs}')"
echo "$example__ban_peers_now"

echo "=========== check ==========="
example__ban_peers_exception=0
for example__ban_peers_mock_item in $(lines_trim "$example__ban_peers_mock"); do
    if [ -n "$(echo "$example__ban_peers_now" | grep "$(echo "$example__ban_peers_mock_item" | awk -F ':' '{print $1}')")" ]; then
        echo "ok" "$example__ban_peers_mock_item"
    else
        echo "fail" "$example__ban_peers_mock_item" >&2
        ((example__ban_peers_exception++))
    fi
done
if [ "$example__ban_peers_exception" -ne 0 ]; then
    exit $EXIT_ERROR
fi
