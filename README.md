## Getting Started

Download qbittorrent-web-api-tools

```bash
git submodule init
git submodule update
git submodule foreach git pull
```

Specify download path

```bash
qbittorrent_download_path="/path/to/dir" # change
docker volume create --opt type=none --opt o=bind --opt device=${qbittorrent_download_path} qbittorrent-download 
```

Boot up Qbittorrent

```bash
docker up -d
```

Update tracker

```bash
docker compose exec qbittorrent /tasks/update_tracker.sh
```

## Usage

Task

```bash
# Update subscribed trackers from net
# env: qbt_tracker_fetch_urls
docker compose exec qbittorrent /tasks/update_tracker.sh

# Ban peers by matching pattern
# env: qbt_peer_ban_pattern
docker compose exec qbittorrent /tasks/ban_peers.sh

# Clean up ban list of peers
docker compose exec qbittorrent /tasks/clean_banned_peers.sh
```

Config

```bash
+ ./env                       —— tasks (and docker) environment
+ ./tasks/config/crontabs/abc —— tasks schedule
```

Logs

```bash
+ docker compose logs
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

