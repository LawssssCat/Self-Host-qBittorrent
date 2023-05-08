#!/bin/bash
#
# Ban leech peers that are recognized by the regex expression periodically.
#
RED='\e[1;31m' # 红
GREEN='\e[1;32m' # 绿
RES='\e[0m' # 清除颜色

check_id="$(date +%Y%m%d%H%M%S)|$$"
check_time_total=${1:-60} # second
check_interval=${2:-10} # second
check_times=$(($check_time_total/$check_interval))
file_log="/config/qBittorrent/logs/qbittorrent.log"
file_id="/tmp/qbittorrent-anti_leech-rid"

echo -e "[anti-leech] $0 - $check_id ${GREEN}running${RES}"
for (( i=1; i<=$check_times; i++ )); do
    if [ "$i" -eq 1 ]; then
        echo "$check_id" > "$file_id" || break
    fi
    sleep $check_interval
    check_id_now="$(cat "$file_id")" || break
    if [ ! "$check_id_now" == "$check_id" ]; then
        break
    fi
    {
        echo "[Anti-leech] $0 - $check_id|$check_time_total|$check_interval|$i|$check_times|$(date +%Y%m%d%H%M%S) --" \
        "$(/script/qbittorrent_webapi_cli.sh -m ban -P anti_leech)" \
        "$(/script/qbittorrent_webapi_cli.sh -m list -p banpeer | wc -l)"
    } >>$file_log 2>&1 || break
done
echo -e "[anti-leech] $0 - $check_id ${RED}down${RES}"
