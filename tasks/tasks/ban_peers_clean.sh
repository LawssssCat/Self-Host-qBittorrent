#!/bin/bash

# Source library of functions
source /qbittorrent-web-api-tools/lib/qb.shlib
source /qbittorrent-web-api-tools/lib/qb.web-api.shlib

# Source tool library of functions
source /tasks/lib/tasks.tools.shlib

# 1. clean
set_app_preferences '{"banned_IPs":""}' || {
    task_title_push "fail banned_IPs: [$qbt_webapi_response_status] $qbt_webapi_response_error"
    task_fatal
}

# 2. print stats
task_title_push "clean banned_IPs"
task_final
