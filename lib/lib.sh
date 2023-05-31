#!/bin/bash

help() {
    echo 'This is a tool for getting forecast in your cli.'
    echo 'USAGE: app.sh -[sSdh] [-c config_file]'
    echo 's - silent mode'
    echo 'S - Super silent mode'
    echo 'd - debug mode'
    echo 'h - print help'
    echo 'c config_file - specify which config file to use'
    echo '(default config file is config.env)'
}

# $1 - MSG
# $2 - LOG_LEVEL (DEBUG, INFO, ERROR)
log() {
    local msg=''
    if [[ $2 == 'DEBUG' ]]; then
        if [[ $DEBUG -eq 0 ]]; then
            return
        else
            msg="$(date +%FT%X) [$2] $1"
            echo "$msg" >&4
        fi
    fi

    if [[ $2 == 'INFO' ]]; then
        if [[ $SILENT ]]; then
            msg="$(date +%FT%X) [$2] $1"
            echo "$msg" >&5
        fi
        if [[ $SUPER_SILENT ]]; then
            return
        fi
    fi

    if [[ $2 == 'ERROR' ]]; then
        msg="$(date +%FT%X) [$2] $1"
        echo "$msg" >&6
        exit 1
    fi
}

cleanup() {
    if [[ -f $1 ]]; then
        rm -f "$1"
    fi
    IPID=$(jobs -l | grep "loader_icon" | awk '{ print $2;}') || true
    kill "$IPID" 2>/dev/null || true
}

test_fork() {
    # shellcheck disable=SC2155
    local rand_sleep=$(seq 5 10 | sort -R | head -n 1)
    sleep "$rand_sleep"
    echo 200 > "$1"
}

loader_icon() {
    if [[ $SILENT -eq 1 ]] || [[ $SUPER_SILENT -eq 1 ]]; then
        return
    fi
    echo -n "Processing"
    while true; do
        echo -n '.'
        sleep 1
    done
}

# $1 - city
# $2 - forecast days (0,1,2)
get_weather()
{
    local url="https://wttr.in/$1?$2QFnTA"
    log "url: $url" "DEBUG"
    local curl_exit_code=0
    curl -s "$url" -o "$TMPFILE" || curl_exit_code=$(echo $?)
    if [[ curl_exit_code -ne 0 ]]; then
        log "curl exit code($curl_exit_code)" "DEBUG"
        log "Cannot get weather" "ERROR"
    fi
}
