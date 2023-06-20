#!/bin/bash
# 
# Update trackers for active torrents with low download speed.
#

: ${qbt_trackers_update_torrent_num:=10}

# Source library of functions
source /qbittorrent-web-api-tools/lib/qb.shlib
source /qbittorrent-web-api-tools/lib/qb.web-api.shlib

# Source tool library of functions
source /tasks/lib/tasks.tools.shlib

# get add_trackers
get_app_preferences && 
qbt_add_tracker="$(echo "$qbt_app_preferences" | $jq_executable ".add_trackers" -r)" || exit $EXIT_ERROR
qbt_add_tracker_urls="$(lines_join '%0A' "$qbt_add_tracker")"
if [ -z "$qbt_add_tracker_urls" ]; then
    exit $EXIT_SKIP
fi

# get active torrents
get_torrents "filter=active&sort=dlspeed" && 
qbt_active_torrents="$(echo "$qbt_torrents" | $jq_executable 'sort_by(.upspeed) | .[]' -c | head -n $qbt_trackers_update_torrent_num \
| $jq_executable '. | {name,hash,state,dlspeed,upspeed}' -c)" || exit $EXIT_ERROR

# torrent trackers remove
qbs_tracker_num_old=0
qbs_tracker_num_remove=0
qbs_tracker_num_new=0
while read qbt_torrent; do
    qbt_torrent_hash="$(echo "$qbt_torrent" | $jq_executable '.hash' -r)"
    # old
    qbt_torrent_trackers_old="$(get_torrent_trackers "$qbt_torrent_hash" && echo "$qbt_torrent_trackers" | $jq_executable '.[]' -c)" || exit $EXIT_ERROR
    ((qbs_tracker_num_old+=$(lines_number "$qbt_torrent_trackers_old")))
    # remove
    qbt_remove_trackers="$(echo "$qbt_torrent_trackers_old" | $jq_executable '. | select(.status == 4) | select(.num_peers <= -1)' -c)" || exit $EXIT_ERROR
    ((qbs_tracker_num_remove+=$(lines_number "$qbt_remove_trackers")))
    qbt_remove_tracker_urls="$(echo "$qbt_remove_trackers" | $jq_executable '.url' -r | lines_join '|')"
    remove_torrent_trackers "$qbt_torrent_hash" "$qbt_remove_tracker_urls" || exit $EXIT_ERROR
    # add
    add_torrent_trackers "$qbt_torrent_hash" "$qbt_add_tracker_urls" || exit $EXIT_ERROR
    # new
    qbt_torrent_trackers_new="$(get_torrent_trackers "$qbt_torrent_hash" && echo "$qbt_torrent_trackers" | $jq_executable '.[]' -c)"
    ((qbs_tracker_num_new+=$(lines_number "$qbt_torrent_trackers_new")))
    # sleep
done <<< "$qbt_active_torrents"

# stats
echo "update tracker: REMOVE,ADD=$qbs_tracker_num_remove,$(lines_number "$qbt_add_tracker")x$(lines_number "$qbt_active_torrents") | \
OLD,NEW=$qbs_tracker_num_old,$qbs_tracker_num_new"
