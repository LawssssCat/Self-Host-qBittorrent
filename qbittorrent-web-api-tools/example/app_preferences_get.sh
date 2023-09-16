#!/bin/bash

# env
source ./set-env.sh

# Source library of functions
source ../lib/qb.shlib
source ../lib/qb.web-api.shlib

echo "=========== get app preferences ==========="
get_app_preferences && {
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
example__app_preferences=$qbt_webapi_response_body

echo "=========== json parse: web_ui info ==========="
echo "$example__app_preferences" | $jq_executable "{web_ui_address,web_ui_port}" || {
    echo "Fail: not a json format."
    exit $EXIT_ERROR
} >&2

echo "=========== json parse: pick add_trackers_enabled ==========="
echo "$example__app_preferences" | $jq_executable "{add_trackers_enabled,add_trackers}"
