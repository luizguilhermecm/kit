
export DEBUG=1

if [ $DEBUG -eq 0 ] 
then
	print "$(date "+%Y%m%d_%Hh%Mm%Ss")" "\\t" "[DEBUG_MODE] ON" 
fi

SHLOG="$SHDIR/log_kit_sh.txt"

logit () {
	print "$(date "+%Y%m%d_%Hh%Mm%Ss")" "\\t" "$@" 
	print "$(date "+%Y%m%d_%Hh%Mm%Ss")" "\\t" "$@" >> "$SHLOG"
}

logit "[kit_log]"
