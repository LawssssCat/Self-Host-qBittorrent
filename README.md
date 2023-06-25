## Getting Started

Download qbittorrent-web-api-tools

```bash
git submodule init
git submodule update
```

Specify download path

```bash
qbittorrent_download_path="/path/to/dir" # change
docker volume create --opt type=none --opt o=bind --opt device=${qbittorrent_download_path} qbittorrent-download 
```

Create config path

```bash
mkdir ./data/qbittorrent/config -p
```

Create `.env` and custom environment variables

```bash
vim .env
```

Boot up Qbittorrent

```bash
docker-compose up -d
```

Update tracker

```bash
docker-compose exec qbittorrent /tasks/add_trackers_update.sh
```

> Click & Save `Options > BitTorrent > Automatically add these trackers to new downloads` in WebUI

## Usage

Task

```bash
# Update subscribed trackers from net
# env: qbt_tracker_fetch_urls
docker compose exec qbittorrent /tasks/add_trackers_update.sh

# Ban peers by matching pattern
# env: qbt_peer_ban_pattern
docker compose exec qbittorrent /tasks/ban_peers_add.sh

# Clean up ban list of peers
docker compose exec qbittorrent /tasks/ban_peers_clean.sh

# Update torrent trackers: remove unwork and add newly fetched trackers 
# env: qbt_trackers_update_torrent_num —— the number of torrents to update trackers
docker compose exec qbittorrent /tasks/torrent_trackers_update.sh
```

Config

```bash
+ ./env                       —— tasks (and docker) environment
+ ./tasks/config/crontabs/abc —— tasks schedule
```

Logs

```bash
+ docker compose logs -f -t --tail=100
+ ./data/qbittorrent/config/qBittorrent/logs/qbittorrent.log —— qbittorrent application runtime log
```

## Reference

### Docker

+ Docker - <https://hub.docker.com/r/linuxserver/qbittorrent>
+ Dockerfile - <https://github.com/linuxserver/docker-qbittorrent/blob/master/Dockerfile>
+ linuxserver/mods:universal-cron - <https://github.com/linuxserver/docker-mods/tree/universal-cron>

### Qbittorrent

+ Options Explanation - <https://github.com/qbittorrent/qBittorrent/wiki/Explanation-of-Options-in-qBittorrent>
+ QBittorrent Settings - <https://www.rapidseedbox.com/blog/qbittorrent-settings>

