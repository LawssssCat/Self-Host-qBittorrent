#!/bin/bash
RED='\e[1;31m' # 红
GREEN='\e[1;32m' # 绿
RES='\e[0m' # 清除颜色
echo -e "[anti-leech] $0 ... ${GREEN}running${RES}"
while true; do
    sleep 10
    echo $(echo "[Anti-leech] " && \
    /script/qbittorrent_webapi_cli.sh -m ban -P anti_leech && \
    /script/qbittorrent_webapi_cli.sh -m list -p banpeer | wc -l) >> /config/qBittorrent/logs/qbittorrent.log
done
echo -e "[anti-leech] $0 ... ${RED}down${RES}"