#!/bin/bash

# Source library of functions
source /qbittorrent-web-api-tools/lib/qb.shlib
source /qbittorrent-web-api-tools/lib/qb.web-api.shlib

# Source tool library of functions
source /tasks/lib/tasks.tools.shlib

# match
get_matching_peers "$qbt_peer_ban_pattern" && 
ban_ids="$(echo "$qbt_mached_peers" | $jq_executable ".key" -r)" || exit 1

# ban
if [ -n "$ban_ids" ]; then
    add_ban_peers "$ban_ids" || exit 1
else
    exit 222 # skip
fi

# result
get_app_preferences && 
banned_ids="$(echo "$qbt_app_preferences" | $jq_executable ".banned_IPs" -r)" || exit 1

# print
echo "ban peers: BAN,BANNED=$(lines_number "$ban_ids"),$(lines_number "$banned_ids")"
