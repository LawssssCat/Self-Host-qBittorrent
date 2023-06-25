#!/bin/bash

: ${qbt_tracker_fetch_urls:=https://cf.trackerslist.com/best.txt}

# Source library of functions
source /qbittorrent-web-api-tools/lib/qb.shlib
source /qbittorrent-web-api-tools/lib/qb.web-api.shlib

# Source tool library of functions
source /tasks/lib/tasks.tools.shlib

# 1. fetch trackers from net
function fetch_net_trackers {
    local fetch_urls="$1"
    local tmp_trackers=""
    while read j; do
        local tmp_fetch_result=""
        tmp_fetch_result=$($curl_executable --silent --fail --show-error --connect-timeout 20 $j 2>&1) || {
            task_message_push "fail fetch tracker: \"$j\" <--> $tmp_fetch_result"
            continue
        }
        local tmp_fetch_trackers=""
        tmp_fetch_trackers="$(echo "$tmp_fetch_result" | grep -e '^http://' -e '^https://' -e '^udp://')" || {
            task_message_push "fail fetch tracker: \"$j\" <--> Unknown response \"$(echo "$tmp_fetch_result" | head -n 1)\""
            continue
        }
        tmp_trackers+="$tmp_fetch_trackers"
        tmp_trackers+=$'\n'
    done <<< "$fetch_urls"
    qbt_net_trackers="$(echo "$tmp_trackers" | lines_trim | lines_unique)"
}
fetch_net_trackers "$(lines_trim "$qbt_tracker_fetch_urls")"
debug "trackers: \n$qbt_net_trackers"
if [ -z "$qbt_net_trackers" ]; then
    task_title_push "fail to fetch trackers from net."
    task_fatal
fi

# 2. set add_trackers preferences
qbt_preferences_json="$($jq_executable --null-input --arg add_trackers "$qbt_net_trackers" '{"add_trackers":$add_trackers}' 2>&1)" || {
    task_title_push "$qbt_preferences_json"
    task_fatal
}
set_app_preferences "$qbt_preferences_json" || {
    task_title_push "fail set app preferences: [$qbt_webapi_response_status] $qbt_webapi_response_error"
    task_fatal
}

# 3. print stats
task_title_push "update add_trackers: $(lines_number "$qbt_net_trackers")"
task_final

