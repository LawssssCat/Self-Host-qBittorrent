#!/bin/bash
RED='\e[1;31m' # 红
GREEN='\e[1;32m' # 绿
RES='\e[0m' # 清除颜色
echo -e "[anti-leech] $0 ... ${GREEN}running${RES}"
log="/config/qBittorrent/logs/qbittorrent.log"
check_interval=${qbt_anti_leech_check_interval:-10} # second
while true; do
    sleep $check_interval
    echo $(
        echo "[Anti-leech] check every $check_interval second -- " && \
        /script/qbittorrent_webapi_cli.sh -m ban -P anti_leech 2>>$log && \
        (/script/qbittorrent_webapi_cli.sh -m list -p banpeer | wc -l) 2>>$log
    ) >> $log
done
echo -e "[anti-leech] $0 ... ${RED}down${RES}"