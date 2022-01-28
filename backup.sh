#set -ex

# Configuration
SRC_DIRS=( "/home" )
BKPBASE="/mnt/bkp"
EXCLUDE_DIRS_FILE="/opt/tools/backcup/exclude_dirs.txt"
# -------------

timestamp=$(date "+%Y%m%d_%H-%M-%S")

logDir="$BKPBASE/log"
hisDir="$BKPBASE/history/$timestamp"
bkpDir="$BKPBASE/backup"

if [[ ! -d $BKPBASE ]]
then
    echo "Target directory $BKPBASE does not exist!"
    exit
fi

install -d $hisDir
install -d $bkpDir
install -d $logDir

# Save detailed log file
rsync -arun --relative --delete --itemize-changes --exclude-from="$EXCLUDE_DIRS_FILE" --out-format="%t  |  %i  |  %n" ${SRC_DIRS[@]} $bkpDir > $logDir/$timestamp

# Update history
echo "Saving Previous version of:"
while read p; do
    #echo $p
    IFS=" | " read -ra los <<< "$p"

    # If a file was modified / deleted, move it from bkpDir to hisDir.
    if [[ "${los[2]}" != *"+" && "${los[2]}" != ".d"* ]]
    then
        relPath="${los[@]:3}"
        echo "  - ${los[2]} | $relPath"

        # Create the dir if neccesary...
        mkdir -p "$hisDir/$(dirname "$relPath")"
        # and cp the file in there
        cp -rf "$bkpDir/$relPath" $hisDir/"$relPath"
    fi

done < $logDir/$timestamp


# Sync the actual backup folder
echo "Updating Backup in $BKPBASE:"
rsync -aru --relative --delete --exclude-from="$EXCLUDE_DIRS_FILE" --out-format="  - %i | %n" ${SRC_DIRS[@]} $bkpDir

# echo finishing date to a file in log/
echo "$(date "+%Y/%m/%d %H:%M:%S")" > $logDir/lastBackup.txt
