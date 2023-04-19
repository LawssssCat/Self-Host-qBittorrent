**docker:**
```
https://hub.docker.com/r/linuxserver/qbittorrent
```

**usage:**
```bash
cp .env .env.local
docker-compose --env-file .env.local up -d
```

**tracker script:**
```bash
$ bash script/qbittorrent_webapi_cli.sh -h
Usage: script/qbittorrent_webapi_cli.sh [OPTIONS...]

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

Update all subscribed trackers to the new torrent

```bash
/script/qbittorrent_webapi_cli.sh -m add -H "%I"
```

Update all subscribed trackers to all torrent

```bash
/script/qbittorrent_webapi_cli.sh -m add -H all
```

Show all active leech peers

```bash
/script/qbittorrent_webapi_cli.sh -m list -p peer -H anti_leech
```

Ban all leech peers and show the number of banned peers

```bash
/script/qbittorrent_webapi_cli.sh -m ban -P anti_leech
```

Show all banned leech peers

```bash
/script/qbittorrent_webapi_cli.sh -m list -p banpeer
```

Combo

```bash
/script/qbittorrent_webapi_cli.sh -m ban -P anti_leech && /script/qbittorrent_webapi_cli.sh -m list -p banpeer | wc -l
```

**environment in the .env file:**

`qbt_tracker_list_subscription` -- tracker subscription
```
https://github.com/ngosang/trackerslist
https://github.com/XIU2/TrackersListCollection
https://newtrackon.com/list
https://acgtracker.com/
https://github.com/DeSireFire/animeTrackerList
```
