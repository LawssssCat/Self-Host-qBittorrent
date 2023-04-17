usage:
```bash
docker-compose --env-file .env.local up -d
```

docker:
```
https://hub.docker.com/r/linuxserver/qbittorrent
```

tracker:
```
https://github.com/ngosang/trackerslist
https://github.com/XIU2/TrackersListCollection
https://newtrackon.com/list
https://acgtracker.com/
https://github.com/DeSireFire/animeTrackerList
```

tracker script:
```bash
$ bash script/qbittorrent_webapi_tracker_cli.sh -h
Usage: script/qbittorrent_webapi_tracker_cli.sh [OPTIONS...]

  -l            List mode
  -a            Add mode
  -g            Generate mode
  -p <pattern>  Specify a property pattern of listing torrents
  -H <hash>     Specify a hash of a torrent (Use ',' to split mutiple hash)
  -t <second>   Specify a time to cache
  -h            Display this help

Example:
  List all torrent info
    -m list
  List all torrent name
    -m list -p name
  List all torrent hash
    -m list -p hash
  List all trackers of the torrent with specified hash
    -m list -p tracker -h <hash>
  Get trackers by subscription
    -m get
  Get trackers by subscription, But get cached data within the time range
    -m get -t <second>
  Get trackers by subscription, And add all trackers to the torrent with specified hash
    -m add -H <hash>
    -m add -H <hash1>,<hash2>
  Get trackers by subscription, And add all trackers to all torrent
    -m add -H all
```

tracker script in web ui: Options/Downloads/Run external program/Run external program on torrent added

```bash
/script/qbittorrent_webapi_tracker_cli.sh -m add -H "%I"
```