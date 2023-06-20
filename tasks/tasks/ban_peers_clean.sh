#!/bin/bash

# Source library of functions
source /qbittorrent-web-api-tools/lib/qb.shlib
source /qbittorrent-web-api-tools/lib/qb.web-api.shlib

# Source tool library of functions
source /tasks/lib/tasks.tools.shlib

# old
get_app_preferences && 
banned_ids_old="$(echo "$qbt_app_preferences" | $jq_executable ".banned_IPs" -r)" || exit $EXIT_ERROR

# clean
set_app_preferences '{"banned_IPs":""}' || exit $EXIT_ERROR

# new
get_app_preferences && 
banned_ids_new="$(echo "$qbt_app_preferences" | $jq_executable ".banned_IPs" -r)" || exit $EXIT_ERROR

# print

echo "clean banned peers: OLD,NEW=$(lines_number "$banned_ids_old"),$(lines_number "$banned_ids_new")"
