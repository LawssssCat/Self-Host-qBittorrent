#!/bin/bash

########## CONFIGURATIONS ##########
# Host on which qBittorrent runs
qbt_host="${qbt_host:-http://127.0.0.1}"
# Port -> the same port that is inside qBittorrent option -> Web UI -> Web User Interface
qbt_port="${qbt_port:-8081}"
# Username to access to Web UI
qbt_username="${qbt_username:-admin}"
# Password to access to Web UI
qbt_password="${qbt_password:-adminadmin}"

# Subscribed trackers
if [ -n "$(echo $qbt_tracker_list_subscription)" ]; then
    # convert the string variable in .env to array
    qbt_tracker_list_subscription=(${qbt_tracker_list_subscription[@]})
else
    qbt_tracker_list_subscription=(
        "https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt"
    )
fi
# static trackers
if [ -n "$(echo $qbt_tracker_list_static)" ]; then
    # convert the string variable in .env to array
    qbt_tracker_list_static=(${qbt_tracker_list_static[@]})
else
    qbt_tracker_list_static=()
fi
# file path to caching trackers
qbt_cache_tracker_list_subscription="${qbt_cache_tracker_list_subscription:-/tmp/.qbt_cache_tracker_list_subscription}"

# peer ban pattern that used by 'grep -E'
qbt_peer_ban_pattern="${qbt_peer_ban_pattern:-Xunlei|\"key\"\:\"[^\"]*\:15000\".*\"country_code\"\:\"cn\"|QQDownload|TorrentStorm}"

########## CONFIGURATIONS ##########

jq_executable="$(command -v jq)"
curl_executable="$(command -v curl)"

########## FUNCTIONS ##########

get_cookie () {
    if [[ -z "$qbt_cookie" ]]; then
        qbt_cookie=$($curl_executable --silent --fail --show-error \
            --header "Referer: ${qbt_host}:${qbt_port}" \
            --cookie-jar - \
            --data "username=${qbt_username}&password=${qbt_password}" ${qbt_host}:${qbt_port}/api/v2/auth/login)
    fi
}

get_app_preference () {
    get_cookie
	preference=$(echo "$qbt_cookie" | $curl_executable --silent --fail --show-error \
		--cookie - \
		--request GET "${qbt_host}:${qbt_port}/api/v2/app/preferences")
}

get_torrent_list () {
	get_cookie
	torrent_list=$(echo "$qbt_cookie" | $curl_executable --silent --fail --show-error \
		--cookie - \
		--request GET "${qbt_host}:${qbt_port}/api/v2/torrents/info")
}

get_torrent_trackers () {
	get_cookie
	tracker_list=$(echo "$qbt_cookie" | $curl_executable --silent --fail --show-error \
		--cookie - \
		--request GET "${qbt_host}:${qbt_port}/api/v2/torrents/trackers?hash=${1}")
}

get_subscription_trackers () {
    tmp_tracker_list=""
    # subscription & cache trackers
    if [ ! -z "$1" ] && [ -f "$qbt_cache_tracker_list_subscription" ]; then
        limit_date=$(date -d "-$1 second" +%s)
        cache_date=$(head -n1 "$qbt_cache_tracker_list_subscription")
        cache_list=$(cat "$qbt_cache_tracker_list_subscription" | sed -n '1!p')
        if [ "$cache_date" -gt "$limit_date" ]; then
            tmp_tracker_list=$(echo $cache_list) # echo to a line
        fi
    fi
    if [ -z "$tmp_tracker_list" ]; then
        for j in "${qbt_tracker_list_subscription[@]}"; do
            tmp_tracker_list+=$($curl_executable -sS $j)
            tmp_tracker_list+=$'\n'
        done
        # cache
        mkdir -p "${qbt_cache_tracker_list_subscription%/*}" -p
        cat > "$qbt_cache_tracker_list_subscription" << EOF
$(date +%s)
${tmp_tracker_list}
EOF
    fi
    # static trackers
    for j in "${qbt_tracker_list_static[@]}"; do
        tmp_tracker_list+=$j
        tmp_tracker_list+=$'\n'
    done
    # list | unique | rows
    tracker_list=$(echo "$tmp_tracker_list" | awk '{for (i=1;i<=NF;i++) if (!a[$i]++) printf("%s%s",$i,FS)}{printf("\n")}' | xargs | tr ' ' '\n')
	tracker_list_num=$(echo "$tracker_list" | wc -l)
}

add_torrent_trackers () {
    get_cookie
    tracker_list=$(echo "$2" | sed ':a;$!N;s/\n/\%0A/;ta')
    tracker_list_num=$(echo "$2" | wc -l)
    echo "$qbt_cookie" | $curl_executable --silent --fail --show-error \
        -d "hash=${1}&urls=${tracker_list}" \
        --cookie - \
        --request POST "${qbt_host}:${qbt_port}/api/v2/torrents/addTrackers"
    echo -e "$?,$tracker_list_num,$1"
}

get_torrent_peers () {
    get_cookie
    peer_list=$(echo "$qbt_cookie" | $curl_executable --silent --fail --show-error \
		--cookie - \
		--request GET "${qbt_host}:${qbt_port}/api/v2/sync/torrentPeers?hash=${1}")
}

ban_torrent_peers () {
    get_cookie
    scenarios=$(echo "$qbt_cookie" | $curl_executable --silent --fail --show-error \
        -d "peers=${1}" \
		--cookie - \
		--request POST "${qbt_host}:${qbt_port}/api/v2/transfer/banPeers")
    echo "$?,$(echo "$1" | tr "\|" "\n" | wc -l),$1"
}

########## FUNCTIONS ##########

if [[ ! $@ =~ ^\-.+ ]]; then
    echo "Arguments must be passed with - in front."
    $0 -h
    exit 0
fi

mode=""
hash=""
peer=""
cache_time=""
list_pattern=""

while getopts ":hm:p:H:t:P:" opt; do
    case "$opt" in
        m )
            mode="$OPTARG"
            ;;
        p )
            list_pattern="$OPTARG"
            ;;
        H )
            hash="$OPTARG"
            ;;
        t )
            cache_time="$OPTARG"
            ;;
        P )
            peer="$OPTARG"
            ;;
        : )
            echo "Invalid option: -${OPTARG} requires an argument" 1>&2
            exit 2
            ;;
        \? )
            echo "Unknow option: -${OPTARG}" 1>&2
            exit 2
            ;;
        h | * )
            echo "Usage: $0 [OPTIONS...]"
            echo ""
            echo "  -l            List mode"
            echo "  -a            Add mode"
            echo "  -g            Generate mode"
            echo "  -p <pattern>  Specify a property pattern of listing torrents"
            echo "  -H <hash>     Specify a hash of a torrent (Use ',' to split mutiple hash)"
            echo "  -P <peer>     Specify a peer with a colon-separated "host:port" (Use '|' to split mutiple peers)"
            echo "  -t <second>   Specify a time to cache"
            echo "  -h            Display this help"
            echo ""
            echo "Example:"
            echo "  List all torrent info"
            echo "    -m list"
            echo "  List all torrent name"
            echo "    -m list -p name"
            echo "  List all torrent hash"
            echo "    -m list -p hash"
            echo "  List all trackers of the torrent with specified hash"
            echo "    -m list -p tracker -H <hash>"
            echo "  List all peers of the torrent with specified hash"
            echo "    -m list -p peer -H <hash>"
            echo "  List all peers of All torrent"
            echo "    -m list -p peer -H all"
            echo "  List all leech peers of All torrent"
            echo "    -m list -p peer -H anti_leech"
            echo "  List all banned peers"
            echo "    -m list -p banpeer"
            echo "  Get trackers by subscription"
            echo "    -m get"
            echo "  Get trackers by subscription, But get cached data within the time range"
            echo "    -m get -t <second>"
            echo "  Get trackers by subscription, And add all trackers to the torrent with specified hash"
            echo "    -m add -H <hash>"
            echo "    -m add -H <hash1>,<hash2>"
            echo "  Get trackers by subscription, And add all trackers to all torrent"
            echo "    -m add -H all"
            echo "  Ban peers"
            echo "    -m ban -P <peer1>|<peer2>"
            echo "  Ban all leech peers"
            echo "    -m ban -P anti_leech"
            exit 0
            ;;
    esac
done
shift $((OPTIND -1))

case "$mode" in
    list )
        case "${list_pattern:-all}" in
            all )
                get_torrent_list
                echo "$torrent_list" | $jq_executable --raw-output '.[]'
                ;;
            tracker )
                if [ -z "$hash" ]; then
                    echo "Need: -H <hash>"
                    exit 2
                fi
                get_torrent_trackers "$hash"
                echo "$tracker_list" | $jq_executable --raw-output ''
                ;;
            peer )
                if [ -z "$hash" ]; then
                    echo "Need: -H <hash>"
                    exit 2
                fi
                if [[ "$hash" == "all" ]]; then
                    hash="$($0 -m list -p hash | tr " " ",")"
                fi
                if [[ "$hash" == "anti_leech" ]]; then
                    $0 -m list -p peer -H all | grep -E "$qbt_peer_ban_pattern"
                    exit 0
                fi
                hash_list="$(echo "$hash" | tr "," " ")"
                for h in $hash_list; do
                    get_torrent_peers "$h"
                    echo "$peer_list" | $jq_executable -c '.peers | to_entries[]'
                done
                ;;
            banpeer )
                get_app_preference
                echo "$preference" | $jq_executable --raw-output '.banned_IPs'
                ;;
            * )
                get_torrent_list
                echo "$torrent_list" | $jq_executable --raw-output '.[] .'$list_pattern
                ;;
        esac
        exit 0
        ;;
    get )
        get_subscription_trackers "$cache_time"
        echo "$tracker_list"
        exit 0
        ;;
    add )
        if [ -z "$hash" ]; then
            echo "Need: -H <hash>"
            exit 2
        fi
        if [[ "$hash" -eq "all" ]]; then
            hash="$($0 -m list -p hash | tr " " ",")"
        fi
        hash_list=($(echo "$hash" | tr "," " "))
        for h in "${hash_list[@]}"; do 
            add_torrent_trackers "$h" "$($0 -m get -t "${cache_time:-43200}")"
        done
        exit 0
        ;;
    ban )
        if [ -z "$peer" ]; then
            echo "Need: -P <peer>"
            exit 2
        fi
        if [[ "$peer" == "anti_leech" ]]; then
            peer=$($0 -m list -p peer -H anti_leech | awk 'match($0,/"key"\:"[^"]*"/) { print substr($0,RSTART+7,RLENGTH-8)}' | sed ":a;$!N;s/\n/|/;ta")
        fi
        ban_torrent_peers "$peer"
        exit 0
        ;;
    * )
        echo "unknow mode \"$mode\""
        exit 2
        ;;
esac
