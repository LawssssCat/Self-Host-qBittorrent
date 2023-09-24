#!/bin/bash

# env
source ./set-env.sh

# Source library of functions
source ../lib/qb.shlib
source ../lib/qb.web-api.shlib

# ready
echo "=========== set preference ==========="
: ${example__banned_IPs_mock:-} # e.g. 0.0.0.11\n0.0.0.22
echo "\"$example__banned_IPs_mock\""

# run
echo "=========== set preference ==========="
set_app_preferences '{"banned_IPs":"'$example__banned_IPs_mock'"}' && {
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
echo "=========== get preference ==========="
get_app_preferences  || {
    echo "response status:"
    echo "$qbt_webapi_response_status"
    echo "error message:"
    echo "$qbt_webapi_response_error"
    exit $EXIT_ERROR
} >&2
example__banned_IPs_app="$(echo "$qbt_webapi_response_body" | $jq_executable ".banned_IPs" -r)" || exit $EXIT_ERROR
echo "\"$example__banned_IPs_app\""

echo "=========== check preference ==========="
if [ "$example__banned_IPs_app" == "$(echo -e "$example__banned_IPs_mock")" ]; then
    echo "Ok"
else
    echo "Fail" >&2
    exit $EXIT_ERROR
fi
