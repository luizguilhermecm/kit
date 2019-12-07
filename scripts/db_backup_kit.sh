#!/usr/bin/zsh

SHHOME="/home/kit/kit/uploads/snk/kit"
SHLOGDIR="$SHHOME/log"
SHLOG="$SHLOGDIR/db_backup.txt"

mkdir -p "$SHHOME"

log_it () {
	print "$(date "+%Y%m%d_%Hh%Mm%Ss")" "\\t" "$@" 
	print "$(date "+%Y%m%d_%Hh%Mm%Ss")" "\\t" "$@" >> "$SHLOG"
}

log_it "------------------------------"

DATENOW="$(date "+%Y%m%d_%Hh%Mm%Ss")"

FNAME="$SHHOME/$DATENOW""_kit.backup"

log_it "FNAME" $FNAME

log_it "basename" "$(basename $FNAME)"

pg_dump  --host localhost --port 5432 --username 'postgres' --format custom --verbose --file "$FNAME" --dbname kit 

return 0;
