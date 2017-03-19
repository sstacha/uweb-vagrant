#!/bin/bash
# script to back up and archive files NOTE: ideally would call svn or git commit to keep in version control
# example1: archive httpd.conf -> will archive httpd.conf with current directory to archive directory preserving directory structure
# example2: archive -c httpd.conf -> will replace the current archive file in the current dir location with the existing file preserving directory structure
# the idea being you can re-create a server and then lay down the current files to replace configurations easily

CURDIR=$(pwd)

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

# Initialize our own variables:
_opt_verbose=false
_opt_current=false
_opt_restore=false
_opt_sync=false
_full_file=""
_full_pwd=""

debug () {
		if [ "$_opt_verbose" = "true" ] ; then
        	# log all messages
        	echo $1;
        fi
}

show_help() {
    echo "usage: archive [-h?][-v][-c][-r]" 
    echo "     -h/?: show usage help"
    echo "     -v: show verbose logging"
    echo "     -c: archive to current folder as well as dated folder"
    echo "     -r: make dated backup of all files in current archive then restore to external locations"
    echo "     -s: sync all current files with the current location contents if they differ"
    echo "          NOTE: primarily thinking it will be used by cron to keep the archive current folder up to date on a server if someone forgets to archive current changes"
    echo "          NOTE: this may not be what we want since it will "always" make sure the current file is current"
    echo "          TODO: implement when needed"
    echo " no option: only archive file or directory items to the dated folder"
}

# determine if the path is relative and if so adds the pwd or passed parameter; we need to do operations on absolute files
get_absolute_file() {
    # echo "gaf _full_file: $_full_file"
    # echo "gaf _opt_file: $_opt_file"
    # get the current directory for use
    _gaf_curdir=$(pwd)    
    # echo "gaf curdir: $_gaf_curdir"
    # echo "gaf optfile: $_opt_file"
    # if the option passed doesn't start with a slash then append the cwd
    if [[ ${_opt_file:0:1} == "/" ]] ;then 
        echo $_opt_file 
    else
        echo "$_gaf_curdir/$_opt_file"
    fi
}

# used to get the non-archived file version if someone gives a restore for an archived file or directory
get_pwd_file() {
    # pwd is special; we want to strip the dated or current archive folder out if it is there and add on the pwd if necessary
    # first determine if we are working in the archive_current or archive_dated directories
    tmp_file="$(get_absolute_file)"
#    debug "[get_pwd_file] tmp_file: $tmp_file"
#    debug "[get_pwd_file] full_file: $_full_file"
#    debug "[get_pwd_file] archive_dir: $ARCHIVE_DIR"
    grp_archive="$(echo $_full_file | grep $ARCHIVE_DIR)"
#    debug "[get_pwd_file] grp_archive: $grp_archive"
    if [[ "$(echo $_full_file | grep $ARCHIVE_DIR)" != "" ]]; then
        # take everything left and send it out; that is the abs from /
#        debug "[get_pwd_file] passed archive dir..."
        if [[ "$(echo $_full_file | grep $ARCHIVE_CURRENT)" != "" ]]; then
            _tmp_len=${#ARCHIVE_CURRENT}
            tmp_file=${_full_file:_tmp_len}
        elif [[ "$(echo $_full_file | grep $ARCHIVE_DATED)" != "" ]]; then
            _tmp_len=${#ARCHIVE_DATED}
            tmp_file=${_full_file:_tmp_len}
#        else
#            debug "[get_pwd_file] archive directory was passed but not current or dated directories"
        fi
    fi
#    debug "[get_pwd_file] returning from function: $tmp_file"
    echo "$tmp_file"
}

archive_to_dated_delete() {
    # if directory we need to do a loop otherwise we just do one file
    if [[ -d "$_full_file" ]]; then
        # write code to loop and save each one
        debug "looping and saving each file in dir [$_full_file]"
    else
        # copy the file requested to the archive location keeping the directory structure
        try mkdir -p $ARCHIVE_DIR$CURDIR
        dtf=`date +%Y%m%d%H%M%S`
        try cp -a $_opt_file $ARCHIVE_DIR$CURDIR/$_opt_file.$dtf
        echo archived $ouput_file to $ARCHIVE_DIR$CURDIR/$_opt_file.$dtf
    fi

}
_archive() {
    debug "called archive function"
    # if directory we need to do a loop otherwise we just do one file
    if [[ -d "$_full_file" ]]; then
        echo "You have requested to back up all files in directory [$_full_file]."
        echo "NOTE: this is not recursive; it will only apply to files in this direcotry not any subdirectories"
        echo " "
        echo 'Are you sure you want to archive all the files in this directory? [y/N]'
        read _user_answer
        debug "user answer: [$_user_answer]"

        if [[ "$_user_answer" != "y" && "$_user_answer" != "Y" ]]; then
            echo "done"
            exit 0
        fi
        # write code to loop and save each one
        debug "saving each file in [ $_full_file ]"
        # we always want to do a dated backup
        echo "archiving to dated..."
        echo "     from: $_full_file"
        echo "     to: $ARCHIVE_DATED$_full_pwd"
        echo "TODO: list each file replaced"
        # if current we want to do a current overrite
        debug '$_opt_current: '$_opt_current
        if [ "$_opt_current" = "true" ]; then
            echo 'archiving to current...'
            echo "     from: $_full_file"
            echo "     to: $ARCHIVE_CURRENT$_full_pwd"

    #        try mkdir -p $CURRENT_DIR$CURDIR
    #        cp -a $_opt_file $CURRENT_DIR$CURDIR/$_opt_file
    #        echo "archived $_opt_file to $CURRENT_DIR$CURDIR/$_opt_file"
    #        echo "To restore all current files: sudo cp -pR $ARCHIVE_CURRENT/* /"
    #        echo "To restore a single file replace * and the destination with the path and filename for the file"
        fi
    elif [[ -f "$_full_file" ]]; then
        debug "saving [ $_full_file ]"
        # we always want to do a dated backup
        echo "archiving to dated..."
        echo "     from: $_full_file"
        echo "     to: $ARCHIVE_DATED$_full_pwd"
        echo "TODO: list each file replaced"
        # if current we want to do a current overrite
        debug '$_opt_current: '$_opt_current
        if [ "$_opt_current" = "true" ]; then
            echo 'archiving to current...'
            echo "     from: $_full_file"
            echo "     to: $ARCHIVE_CURRENT$_full_pwd"
    #        try mkdir -p $CURRENT_DIR$CURDIR
    #        cp -a $_opt_file $CURRENT_DIR$CURDIR/$_opt_file
    #        echo "archived $_opt_file to $CURRENT_DIR$CURDIR/$_opt_file"
    #        echo "To restore all current files: sudo cp -pR $ARCHIVE_CURRENT/* /"
    #        echo "To restore a single file replace * and the destination with the path and filename for the file"
        fi
    else
        echo "[ $_full_file ] not found!"
    fi

}
_restore() {
    debug "called restore function"
    # NOTE: we check for exactness in dated folder first then current; make function?
    debug "opt_restore is true; determining if we are restoring everything in the archive, one file or directory in the archive or everything in a folder or one file or directory in current folder or the archive"
    debug ""
    echo "test: restore dated file to location, dated dir to location, current file to location current dir to location"
    # if the file argument is blank then we want to prompt and restore everything in the directory as long as we have the current working directory in the archive; do a makedir -p to ensure each subdirectory exists first
    if [[ "$_opt_file" = "" ]]; then
        # ask if they want to really do this since this will be pretty destructive
        echo "You have requested to restore all files in directory [$_full_file] from your current archive folder.  This will restore every file found in the current archive as long as it exists.  It will also create a dated archive of each file first if you need it again."
        echo "NOTE: this is not recursive; it will only apply to files in this direcotry not any subdirectories"
        echo " "
        echo 'Are you sure you want to replace all the files in this directory? [y/N]'
        read _user_answer
        debug "user answer: [$_user_answer]"

        if [[ "$_user_answer" != "y" && "$_user_answer" != "Y" ]]; then
            echo "done"
            exit 0
        fi

        # if we are still here then they want to replace all the files so lets do it
        echo "Backing up and restoring all files in [$_full_file] if they exist in the current archive folder..."
        # loop through each current folder files and make a dated backup of each one to get back to and restore each file to this directory preserving permissions

        echo "date archiving each existing file in [$_full_file]..."
        echo "TODO: list each file date archived"

        echo "restoring..."
        echo "     from: $ARCHIVE_CURRENT$_full_pwd if it exists"
        echo "     to: [$_full_file]"
        echo "TODO: list each file replaced"

    else
        # if the file argument is the current archive directory then prompt and replace all files in the archive out to their respective locations; do a makedir -p to make sure it exists first
        if [[ "$_opt_file" == "$ARCHIVE_CURRENT" ]]; then
            # ask if they want to really do this since this will be pretty destructive
            echo "You have requested to restore all files currently in your current archive directory out to their repective locations.  This will restore every file found in the current archive overwriting anything that is currently there.  It will also create a dated archive of each file found first in case you need it later."
            echo "NOTE: this is recursive; it will apply to every file and direcotry/subdirectory in the current archive folder"
            echo " "
            echo 'Are you sure you want to replace or overwrite all the files in your current archive to their respective locations? [y/N]'
            read _user_answer
            debug "user answer: [$_user_answer]"

            if [[ "$_user_answer" != "y" && "$_user_answer" != "Y" ]]; then
                echo "done"
                exit 0
            fi

            # if we are still here then they want to replace all the files out to their respective locations so lets do it
            echo "Backing up and restoring all current archived files to their repective directories..."
            # loop through each current archive folder files and make a dated backup of each one to get back to and restore each file to this directory preserving permissions

            echo "date archiving each existing file in the current archive if it exists..."
            echo "TODO: list each file date archived"

            echo "restoring..."
            echo "     from: $ARCHIVE_CURRENT"
            echo "     to: each files respective locations"
            echo "TODO: list each file replaced"

        # if the file argument is something inside the archive directory (equality already checked) then just restore that archived file or folder out to its location
        elif [[ "$(echo $_full_file | grep $ARCHIVE_DIR)" != "" ]]; then
            if [[ -d "$_full_file" ]]; then
                # ask if they want to really do this
                echo "You have requested to restore all files in directory [$_full_file]"
                echo 'Are you sure? [y/N]'
                read _user_answer
                debug "user answer: [$_user_answer]"

                if [[ "$_user_answer" != "y" && "$_user_answer" != "Y" ]]; then
                    debug "Bailing then, excute again passing the file name you want to archive."
                    echo " "
                    echo "done"
                    exit 0
                fi
                # loop through each file and send it to its location preserving permissions
                echo "date archiving each existing file in the current archive if it exists..."
                echo "TODO: list each file date archived"

                echo "restoring..."
                echo "     from: $_full_file"
                echo "     to: $_full_pwd"
                echo "TODO: list each file replaced"
                echo "TODO: if the file was a dated folder file then strip the extension before restoring"

            elif [[ -f "$_full_file" ]]; then
                # just replace the file requesteed from the archive directory to the current one
                echo "date archiving each existing file in the current archive if it exists..."
                echo "TODO: list each file date archived"

                echo "restoring..."
                echo "     from: $_full_file"
                echo "     to: $_full_pwd"
                echo "$_full_pwd"
                echo "TODO: if the file was a dated folder file then strip the extension before restoring"
            else
                echo "[ $_full_file ] not found!"
            fi

        else
            # only thing left should be files or directories inside of the working directory; if the archive exists restore it
            if [[ -d "$_full_file" ]]; then
                # ask if they want to really do this
                echo "You have requested to restore all files in directory [$_full_file]"
                echo 'Are you sure? [y/N]'
                read _user_answer
                debug "user answer: [$_user_answer]"

                if [[ "$_user_answer" != "y" && "$_user_answer" != "Y" ]]; then
                    debug "Bailing then, excute again passing the file name you want to archive."
                    echo " "
                    echo "done"
                    exit 0
                fi
                # loop through each file and send it to its location preserving permissions
                echo "date archiving each existing file in the current archive if it exists..."
                echo "TODO: list each file date archived"

                echo "restoring..."
                echo "     from: $_full_file"
                echo "     to: $_full_pwd"
                echo "TODO: list each file replaced"
            elif [[ -f "$_full_file" ]]; then
                # just replace the file requesteed from the archive directory to the current one
                echo "date archiving each existing file in the current archive if it exists..."
                echo "TODO: list each file date archived"

                echo "restoring..."
                echo "     from: $_full_file"
                echo "     to: $_full_file"
                echo "$_full_file"
            else
                echo "[ $_full_file ] not found!"
            fi
        fi
    fi
}

# parse all options suing getargs...
# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

while getopts "h?vcf:rs" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  _opt_verbose=true
        ;;
    c)  _opt_current=true
        ;;
    r)  _opt_restore=true
        ;;
    s)  _opt_sync=true
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

_opt_file=$@
debug "options: "
debug "verbose:$_opt_verbose"
debug "current:$_opt_current"
debug "restore:$_opt_restore"
debug "argument: $_opt_file"
debug ""

if [[ "$_opt_file" == "." ]]; then
    _opt_file=""
fi
_full_file=$(get_absolute_file)
_full_pwd=$(get_pwd_file )
_full_archive_current=$ARCHIVE_CURRENT$_full_pwd
_full_archive_dated=$ARCHIVE_DATED$_full_pwd

debug "opt file: $_opt_file"
debug "full file: $_full_file"
debug "full pwd file: $_full_pwd"
debug "full archive current: $_full_archive_current"
debug "full archive dated: $_full_archive_dated"

dirs_exist=0
# check that we have appropriate directories or bail
if [ -f "$ARCHIVE_DIR" ]; then
	if [ -f "$CURRENT_DIR" ]; then
		dirs_exist = 1
	fi
fi
if [ $dirs_exist ]; then
	debug 'archive and current directories exist; continuing...'
else
	echo 'ERROR: archive and current directory does not exist'
	echo "run: sudo mkdir -p $ARCHIVE_DIR"
	echo "run: sudo mkdir -p $CURRENT_DIR"
	echo "run: sudo chown -R ubuntu:_developer $ARCHIVE_DIR"
	echo "run: sudo chown -R ubuntu:_developer $CURRENT_DIR"
	echo "run: sudo chmod -R 775 $ARCHIVE_DIR"
	echo "run: sudo chmod -R 775 $CURRENT_DIR"
	echo " then try archiving your file again"
	exit 1
fi		

# ---- begin option validation checks ----
debug "full file: $_full_file"

# validate that there are not combinations of options that do not make sense
# it does not make sense to allow archiving current and restoring current at the same time.  r should not be used
#   with c or s
if [[ ("$_opt_current" = "true" && "$_opt_restore" = "true") || ("$_opt_sync" = "true" && "$_opt_restore" = "true") ]]; then
    echo "You have requested to both archive current files and restore current files at the same time.  This does not make sense and is probably an error.  If this was truly your intention please enter each command separately."
    exit 1
fi
# it does not make sense to sync and archive current at the same time; sync requires file from current_achive and current 
#   requires external file outside the archive directory
if [[ "$_opt_current" = "true" && "$_opt_sync" = "true" ]]; then
    echo "You have requested to sync all current files and sync a current file or directory.  This does not make sense since the first case uses the archive directory to specify which files and the second uses an external directory.  Retry with one or the other."
    exit 1
fi
# ---- end option validation checks ----

debug "passed option validation checks"
debug " "

# essentially, based on options, we are either restoring files or archiving files
if [ "$_opt_restore" = "true" ]; then
    debug "restoring..."
    _restore
else
    debug "archiving..."
    # if we are archiving or archiving current do not allow files in the archive directory.  while this might be legitimate in very rare case it is almost always an error.  Let them do copys manually instead
    if [[ "$(echo $_full_file | grep $ARCHIVE_DIR)" != "" ]]; then
        echo "You have requested to archive a file in the archive directory.  This is not allowed as it can cause problems.  If you want to copy things in the archive directory please copy them manually."
        exit 1
    fi
    _archive
fi
echo " "
echo "done"