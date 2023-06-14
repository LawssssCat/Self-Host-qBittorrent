## Usage

Specify download path

```bash
qbittorrent_download_path="/path/to/dir" # change
docker volume create --opt type=none --opt o=bind --opt device=${qbittorrent_download_path} qbittorrent-download 
```

Boot up Qbittorrent

```bash
docker up -d
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

### Qbittorrent

+ Options Explanation - <https://github.com/qbittorrent/qBittorrent/wiki/Explanation-of-Options-in-qBittorrent>
+ QBittorrent Settings - <https://www.rapidseedbox.com/blog/qbittorrent-settings>

