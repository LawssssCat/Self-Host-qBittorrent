#!/bin/bash
# 
# Update trackers for active torrents with low download speed.
#

: ${qbt_trackers_update_torrent_num:=10}
: ${qbt_torrent_pt_tag:=pt}
: ${qbt_torrent_pt_category:=pt}

# Source library of functions
source /qbittorrent-web-api-tools/lib/qb.shlib
source /qbittorrent-web-api-tools/lib/qb.web-api.shlib

# Source tool library of functions
source /tasks/lib/tasks.tools.shlib

# 1. get add_trackers
get_app_preferences || {
    task_title_push "fail get app preferences: [$qbt_webapi_response_status] $qbt_webapi_response_error"
    task_fatal
}
qbt_add_trackers="$(echo "$qbt_webapi_response_body" | $jq_executable ".add_trackers" -r 2>&1)" || {
    task_title_push "fail parse json: $qbt_add_trackers"
    task_fatal
}
debug "add_trackers: $qbt_add_trackers"
qbt_add_trackers_url="$(lines_join '%0A' "$qbt_add_trackers")"
if [ -z "$qbt_add_trackers_url" ]; then
    task_skip
fi

# 2. get active torrents
# sort priority: dlspeed(0-1),upspeed(0-1),progress(0-1),last_activity(1-0)
get_torrents "filter=active&sort=last_activity&reverse=true" || {
    task_title_push "fail get torrents: [$qbt_webapi_response_status] $qbt_webapi_response_error"
    task_fatal
}
debug "active_torrents: $qbt_webapi_response_body"
qbt_active_torrents="$( (echo "$qbt_webapi_response_body" \
    | $jq_executable 'sort_by(.progress) | sort_by(.upspeed) | sort_by(.dlspeed) | .[]' -c \
    | grep -E -v '\"tags\":\"([^"]*, |)?('$qbt_torrent_pt_tag')(, [^"]*|)?\"' \
    | grep -E -v '\"category\":\"('$qbt_torrent_pt_category'\")' \
    | head -n $qbt_trackers_update_torrent_num) 2>&1)" || {
        task_title_push "fail parse json: $qbt_active_torrents"
        task_fatal
    }
debug "sorted-active_torrents: $qbt_active_torrents"

# 3. torrent trackers remove & add
qbt_remove_trackers_total=0
while read qbt_torrent; do
    qbt_torrent_hash="$(echo "$qbt_torrent" | $jq_executable '.hash' -r)"
    # trackers
    get_torrent_trackers "$qbt_torrent_hash" || {
        task_message_push "fail get app preferences: [$qbt_webapi_response_status] $qbt_webapi_response_error"
        continue
    }
    qbt_remove_trackers="$(echo "$qbt_webapi_response_body" | $jq_executable '.[] | select(.status == 4) | select(.num_peers <= -1)' -c 2>&1 )" || {
        task_message_push "fail parse torrent_trackers"
        continue
    }
    debug "remove: $qbt_remove_trackers"
    # remove
    qbt_remove_tracker_urls="$(echo "$qbt_remove_trackers" | $jq_executable '.url' -r | lines_join '|')"
    remove_torrent_trackers "$qbt_torrent_hash" "$qbt_remove_tracker_urls" || {
        task_message_push "fail remove trackers: $qbt_torrent_hash <--> [$qbt_webapi_response_status] $qbt_webapi_response_error"
        continue
    }
    ((qbt_remove_trackers_total+=$(lines_number "$qbt_remove_trackers")))
    # add
    add_torrent_trackers "$qbt_torrent_hash" "$qbt_add_trackers_url" || {
        task_message_push "fail add trackers: $qbt_torrent_hash <--> [$qbt_webapi_response_status] $qbt_webapi_response_error"
        continue
    }
done <<< "$qbt_active_torrents"

# 4. print stats
task_title_push "update torrent_trackers: REMOVE,ADD=$qbt_remove_trackers_total,$(lines_number "$qbt_add_trackers")x$(lines_number "$qbt_active_torrents")"
task_final
