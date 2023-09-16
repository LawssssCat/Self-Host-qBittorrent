
qbittorrent web-api: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)

jq tutorial: https://jqlang.github.io/jq/tutorial/

## Usage

load functions

```bash
# env
: ${qbt_host:="http://127.0.0.1"}
: ${qbt_port:="8080"}
: ${qbt_username:="admin"}
: ${qbt_password:="adminadmin"}

# Source library of functions
source ../lib/qb.shlib
source ../lib/qb.web-api.shlib
```

---

call functions

e.g. fetch tracker from net and set it to app preference "add_trackers". —— `add_trackers_set.sh`

e.g. ban peers that look like they are from XunLei —— `ban_peers_add.sh`

e.g. clean banned peers —— `ban_peers_clean.sh`

```bash
set_app_preferences '{"banned_IPs":""}'
```

## Test

```bash
$ cd ./test
$ ./test-example.sh
 · EXAMPLE_0: add_trackers_set.sh ..............................  SUCCESS
 · EXAMPLE_1: app_preferences_get.sh ...........................  SUCCESS
 · EXAMPLE_2: ban_peers_add.sh .................................  SUCCESS
 · EXAMPLE_3: ban_peers_clean.sh ...............................  SUCCESS
 · EXAMPLE_4: torrent_peers_get.sh .............................  SUCCESS
 · EXAMPLE_5: torrent_trackers_add.sh ..........................  SUCCESS
 · EXAMPLE_6: torrent_trackers_get.sh ..........................  SUCCESS
 · EXAMPLE_7: torrent_trackers_remove.sh .......................  SUCCESS
 · EXAMPLE_8: torrents_get.sh ..................................  SUCCESS
```

## Alternate

+ https://github.com/fedarovich/qbittorrent-cli —— qbt cli 
+ https://github.com/Jorman/Scripts/blob/master/AddqBittorrentTrackers.sh —— tracker subscription
