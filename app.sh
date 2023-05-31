#!/bin/bash

# Подключаем модули
# shellcheck disable=SC1091
source lib/lib.sh

set -eEuTo pipefail
# (!) SC2064 Будь внимательнее с кавычками (!)
trap 'log "($?) on line:$LINENO" "ERROR"' ERR
trap 'cleanup $TMPFILE' SIGTERM TERM EXIT

# Настроим дефолты
LOGFILE='log/app.log'
CONFIGFILE='config.env'
TMPFILE='/tmp/cli-weather.temp'
DEBUG=0
SILENT=0
SUPER_SILENT=0

# Перенаправляем stderr и stdout во временный поток
# 4 - для DEBUG
# 5 - для STDOUT
# 6 - для STDERR
exec 4>>$LOGFILE 5>>$LOGFILE 6>>$LOGFILE
exec 2>&6
exec 7>&1

# Вычитываем аргументы
while getopts ":sSdhc:" ARG; do
# shellcheck disable=SC2034
  case "$ARG" in 
    S)  SUPER_SILENT=1;;
    s)  SILENT=1
        exec 1>&5
        ;;
    d)  DEBUG=1;;
    h)  help
        exit 0;;
    c)  CONFIGFILE=$OPTARG;;
    :)  log "Argument missing" "ERROR"
        exit 1;;
    \?) log "Incorrect option" "ERROR"
        exit 1
        ;;
  esac
done

if [[ ! -f $CONFIGFILE ]]; then
    log "Config file doesn't exist" "ERROR"
    exit 1
fi
# shellcheck disable=SC2046
export $(grep -v '^\s*#' "$CONFIGFILE" | xargs)
log "CITY=$CITY" "DEBUG"
log "FORECASTDAYS=$FORECASTDAYS" "DEBUG"


exec 5>&-
exec 1>&7 7>&-

# ------ Payload ------

touch "$TMPFILE" # Просто так создаем файл в учебных целях, чтобы клинапу было что прибирать
#test_fork $TMPFILE &
get_weather $CITY $FORECASTDAYS &
FPID=$(jobs -p)
loader_icon &
IPID=$(jobs -l | grep "loader_icon" | awk '{ print $2;}')
wait "$FPID"
kill "$IPID" 2>/dev/null || true

# ---------------------
if [[ $SILENT -eq 0 ]] && [[ $SUPER_SILENT -eq 0 ]]; then
    echo ""
fi
cat $TMPFILE