#!/bin/bash

: ${qbt_tracker_fetch_urls:=https://cf.trackerslist.com/best.txt}

# Source library of functions
source /qbittorrent-web-api-tools/lib/qb.shlib
source /qbittorrent-web-api-tools/lib/qb.web-api.shlib

# Source tool library of functions
source /tasks/lib/tasks.tools.shlib

# old
get_app_preferences && 
tracker_old=$(echo "$qbt_app_preferences" | $jq_executable ".add_trackers" -r) || exit $EXIT_ERROR

# fetch
fetch_urls=($qbt_tracker_fetch_urls) && 
fetch_net_trackers "${fetch_urls[@]}" || exit $EXIT_ERROR # qbt_net_trackers
tracker_fetch="$(echo "$qbt_net_trackers")" 
# fetch error message
tracker_fetch_error=""
for ((i=0; i<${#qbt_net_exception_urls[@]}; i++)); do
    tracker_fetch_error+="Fail to fetch \"${qbt_net_exception_urls[$i]}\" with issue: ${qbt_net_exception_issues[$i]}"
    tracker_fetch_error+=$'\n'
done

# update
set_app_preferences "{\"add_trackers\":\"$(lines_join '\\n' "$qbt_net_trackers")\"}" || exit $EXIT_ERROR

# new
get_app_preferences && 
tracker_new=$(echo "$qbt_app_preferences" | $jq_executable ".add_trackers" -r) || exit $EXIT_ERROR

# print update stats
echo "tracker update: OLD,FETCH,NEW=$(lines_number "$tracker_old"),$(lines_number "$tracker_fetch"),$(lines_number "$tracker_new")"
# print fetch error
if [ -n "$tracker_fetch_error" ]; then
    echo "$(lines_trim "$tracker_fetch_error")" >&2
fi
