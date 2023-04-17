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
qbt_cache_tracker_list_subscription="${qbt_cache_tracker_list_subscription:-/tmp/.qbt_cache_tracker_list_subscription}"

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
    # cache
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

########## FUNCTIONS ##########

if [[ ! $@ =~ ^\-.+ ]]; then
    echo "Arguments must be passed with - in front."
    $0 -h
    exit 0
fi

mode=""
hash=""
cache_time=""
list_pattern=""

while getopts ":hm:p:H:t:" opt; do
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
            echo "  -H <hash>     Specify a hash of a torrent"
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
            echo "    -m list -p tracker -h <hash>"
            echo "  Get trackers by subscription"
            echo "    -m get"
            echo "  Get trackers by subscription, But get cached data within the time range"
            echo "    -m get -t <second>"
            echo "  Get trackers by subscription, And add all trackers to the torrent with specified hash"
            echo "    -m add -h <hash>"
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
                    echo "Need <hash> sepcify"
                    exit 2
                fi
                get_torrent_trackers "$hash"
                echo "$tracker_list" | $jq_executable --raw-output ''
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
            echo "Need <hash> sepcify"
            exit 2
        fi
        add_torrent_trackers "$hash" "$($0 -m get -t "${cache_time:-43200}")"
        exit 0
        ;;
    * )
        echo "unknow mode \"$mode\""
        exit 2
        ;;
esac
