#!/bin/bash

function getHelp () {
cat <<-END
Usage: $(basename "$0") [-h] [-c -t]
  -h
    Display this help
  -c
    Amount of accounts to get per pull (e.g. -c 5)
  -k
    They API Key (e.g. -k "asde8(")
  -t
    The minimum time between pulls in hours (default=10)
  -a
    The maximum age of accounts that would get pulled (default=4)
  -s
    The Script to run (e.g. -s "python3.6  /pathToMonocle/scripts/import_accounts.py --level 30 #FILE#") Make shure to include #FILE#!)
END
}

## func - Loads Accoutns and run import script
function getAccs () {
    URL="http://ptc.shuffletanker.com/Lemon/GetLevel30?extraction_API=$KEY&amount=$GETCOUNT"
    BACKUPDIR="$DIR/api.log"
    DATA="$(curl $URL -s)"
    echo -e "$DATA" > "$BACKUPDIR"
    if [[ $DATA == *"\"ok\":false"* ]]
    then
      echo "[$LOGTIME] Failed to get accs"
    else
      DATA=${DATA//\{\"ok\":true,\"message\":\"/}
      DATA=${DATA//\"\}/}
      DATA=${DATA//;/\\n}
      TEMPDIR="$DIR/tmp.txt"
      BACKUPDIR="$DIR/pulled_accs.txt"
      SCRIPT=${SCRIPT//#FILE#/$TEMPDIR}
      echo -e "$DATA" > "$TEMPDIR"
      echo -e "$DATA" >> "$BACKUPDIR"
      echo "[$LOGTIME] Reloading Accs..."
      $SCRIPT
      echo "[$LOGTIME] Reloaded Accs"
      echo "$TIMESTAMPNOW" > "$SCRIPTDIR"
      rm -f $TEMPDIR

      LOGDIR="$DIR/reload.log"
      echo "$LOGTIME" >> "$LOGDIR"

    fi
}

## Init ##
LOGTIME=$(date)
GETCOUNT=0
KEY="none"
MINTIME=10
MAXAGE=3
SCRIPT="none"
while getopts "h c:k:a:t:s:" opts; do
    case ${opts} in
        h)
            getHelp
            exit
            ;;
        c)        
            GETCOUNT=${OPTARG}
            ;;
        k)
            KEY=${OPTARG}
            ;;
        a)
            MAXAGE=${OPTARG}
            ;;
        t)
            MINTIME=${OPTARG}
            ;;
        s)
            SCRIPT=${OPTARG}
            ;;
    esac 
done 

## Check Config ##
RUNABLE=1
if [ 1 -gt $GETCOUNT ]; then
  echo -e "Level 30 count not specified (use -h for help)"
  RUNABLE=0
fi    
if [ $KEY == "none" ]; then
  echo -e "Key not specified (use -h for help)"
  RUNABLE=0
fi
if [[ $SCRIPT == "none" ]]; then
  echo -e "Import Script not specified (use -h for help)"
  RUNABLE=0
fi

## Run (or not) ##
if [ $RUNABLE -gt 0 ]
then
  LASTPULL="none"
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  SCRIPTDIR="$DIR/last_pull.txt"
  if [ -f $SCRIPTDIR ]
  then
    LASTPULL=$(cat $SCRIPTDIR)
  fi

  TIMESTAMPNOW="$(date --utc "+%s")"
  AGE=$[$TIMESTAMPNOW - $LASTPULL]
  MINTIMEHOUR=$[3600 * $MINTIME]
  if (( !$LASTPULL == "none" )) && (( $AGE < $MINTIMEHOUR )) # To early. Waiting
    then
    echo "[$LOGTIME] Recently Pulled - Nothing to do yet"
    exit
  fi

  COUNT="$(curl http://ptc.shuffletanker.com/Lemon/GetStock -s)"
  if [ $COUNT -ge $GETCOUNT ] # Check if enough accs to pull
  then
    DATE="$(curl http://ptc.shuffletanker.com/Lemon/GetOldestTimestamp?count=$GETCOUNT  -s)"
    TIMESTAMP="$(date --utc -d "$DATE" "+%s")"
    TIMESINCELAST=$[$TIMESTAMPNOW - $TIMESTAMP]
    MAXAGEHOUR=$[3600 * $MAXAGE]

    if (( $TIMESINCELAST > $MAXAGEHOUR )) # Check if accs are older than max age
    then
       echo "[$LOGTIME] Accs are old - Waiting for new ones"
       exit
    fi
    getAccs
  else
    echo "[$LOGTIME] Not enough accs - Waiting for new ones"
  fi
fi
