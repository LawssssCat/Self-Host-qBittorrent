#!/bin/bash

: ${qbt_peer_ban_pattern:=Xunlei|\-XL}

# Source library of functions
source /qbittorrent-web-api-tools/lib/qb.shlib
source /qbittorrent-web-api-tools/lib/qb.web-api.shlib

# Source tool library of functions
source /tasks/lib/tasks.tools.shlib

# 1. match band peers
function get_matching_peers {
    local pattern_peer="$1"
    # torrents
    get_torrents "filter=active" || {
        task_title_push "fail get torrent: [$qbt_webapi_response_status] $qbt_webapi_response_error"
        task_fatal
    }
    local qbt_torrent_hashs=""
    qbt_torrent_hashs="$(echo "$qbt_webapi_response_body" | $jq_executable ".[].hash" -r 2>&1)" || {
        task_title_push "$qbt_torrent_hashs"
        task_fatal
    }
    # peers
    local tmp_mached_peers=""
    local tmp_error_count=0
    for h in $qbt_torrent_hashs; do 
        get_torrent_peers "$h" || {
            task_message_push "fail get torrent: $h <--> [$qbt_webapi_response_status] $qbt_webapi_response_error"
            continue
        }
        local tmp_get_torrent_peers_raw="$qbt_webapi_response_body"
        local tmp_get_peers=""
        tmp_get_peers="$(echo "$tmp_get_torrent_peers_raw" | $jq_executable ".peers | to_entries[]" -c 2>&1)" || {
            ((tmp_error_count++))
            task_message_push "fail parse torrent-1: $h <--> $tmp_get_peers"
            task_message_push "raw torrent: $tmp_get_torrent_peers_raw"
            continue
        }
        tmp_get_peers="$(echo "$tmp_get_peers" | grep -E "$pattern_peer")" || {
            continue
        }
        tmp_get_peers="$(echo "$tmp_get_peers" | $jq_executable ".key" -r 2>&1)" || {
            ((tmp_error_count++))
            task_message_push "fail parse torrent-2: $h <--> $tmp_get_peers"
            task_message_push "raw torrent: $tmp_get_torrent_peers_raw"
            continue
        }
        tmp_mached_peers+="$tmp_get_peers"
        tmp_mached_peers+=$'\n'
    done
    qbt_mached_error_count="$tmp_error_count"
    qbt_mached_peers="$(echo "$tmp_mached_peers" | lines_trim | lines_unique)" 
}
get_matching_peers "$qbt_peer_ban_pattern"
qbt_banned_IPs_add="$qbt_mached_peers"
if [ -z "$qbt_banned_IPs_add" ] && [ $qbt_mached_error_count -gt 0 ]; then
        task_message_push "No matching peers, but errors"
        task_fatal
fi

# 2. add banned_IPs
if [ -z "$qbt_banned_IPs_add" ] && [ $qbt_mached_error_count -eq 0 ]; then
        task_skip
fi
qbt_banned_IPs_add_params="$(lines_join '|' "$qbt_banned_IPs_add")"
debug "banned_IPs: $qbt_banned_IPs_add_params"
add_ban_peers "$qbt_banned_IPs_add_params" || {
    task_message_push "fail add banned_IPs: [$qbt_webapi_response_status] $qbt_webapi_response_error"
    task_fatal
}

# 3. get banned_IPs
get_app_preferences || {
    task_title_push "fail get app preferences: [$qbt_webapi_response_status] $qbt_webapi_response_error"
    task_fatal
}
qbt_app_banned_IPs="$(echo "$qbt_webapi_response_body" | $jq_executable ".banned_IPs" -r 2>&1)" || {
    task_title_push "fail parse json: $qbt_add_trackers"
    task_fatal
}

# 4. print stats
task_title_push "add banned_IPs: BAN,BANNED=$(lines_number "$qbt_banned_IPs_add"),$(lines_number "$qbt_app_banned_IPs")"
task_final
