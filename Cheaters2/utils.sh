#!/usr/bin/env bash

LOGFILE="$HOME/Desktop/Cheaters_DEBUG.txt"


# xargs strips leading/trailing whitespace and quotes. tr removes () chars
# usage: OUTPUT=$(alf_remove_spesh "$OUTPUT")
function alf_remove_spesh(){

    local result=`echo "$1" | xargs | tr -d '()'`
    echo "$result"
}

# check if a file/folder/link exists
alf_file_exists() {
    if [ -e "$1" ]; then
      return 0
    fi
    return 1
}

# check if a directory exists
alf_dir_exists() {
    if [ -d "$1" ]; then
      return 0
    fi
    return 1
}

# add -t param to tag log in syslog
loggerCmd="logger -t 'Alfred Workflow'"

# Success logging
alf_success() {
    eval $loggerCmd "SUCCESS: $@"
}

# debug logging
alf_debug() {
    eval $loggerCmd "DEBUG: $@"
}

# error logging
alf_error() {
    eval $loggerCmd "ERROR: $@"
}

# get present working dir
PWD=`pwd`

alf_is_git_repo() {
    $(git rev-parse --is-inside-work-tree &> /dev/null)
}

# Test whether a command exists
alf_type_exists() {
    if [ $(type -P $1) ]; then
      return 0
    fi
    return 1
}

alf_get_git_branch() {
    local branch_name

    # Get the short symbolic ref
    branch_name=$(git symbolic-ref --quiet --short HEAD 2> /dev/null) ||
    # If HEAD isn't a symbolic ref, get the short SHA
    branch_name=$(git rev-parse --short HEAD 2> /dev/null) ||
    # Otherwise, just give up
    branch_name="(unknown)"

    printf $branch_name
}

alf_get_is_master_branch(){
    local branch=$(alf_get_git_branch)

    if [ "$branch" = "master" ]; then
        return 0
    fi
    
    return 1
}

# must be in th dir,and takes a URL
alf_git_init_repo() {

    if [ $# -eq 0 ]
    then
        alf_error "Repo URL param required"
        return 99
    fi

    main_git_repo="$1"

    if $(alf_check_url "$main_git_repo"); then

        git init -q
        git remote add origin $main_git_repo
        git fetch -q origin master
        # Reset the index and working tree to the fetched HEAD
        git reset -q --hard FETCH_HEAD
        # Remove any untracked files
        #git clean -fd
    else
        return 1
    fi

}

# Git status information
alf_git_status() {
    local git_state uc us ut st
    git update-index --really-refresh  -q &>/dev/null

    # Check for uncommitted changes in the index
    if ! $(git diff --quiet --ignore-submodules --cached); then
        uc="+"
    fi

    # Check for unstaged changes
    if ! $(git diff-files --quiet --ignore-submodules --); then
        us="!"
    fi

    # Check for untracked files
    if [ -n "$(git ls-files --others --exclude-standard)" ]; then
        ut="?"
    fi

    # Check for stashed files
    if $(git rev-parse --verify refs/stash &>/dev/null); then
        st="$"
    fi

    git_state=$uc$us$ut$st

    #git_state=""
    echo $git_state

}

# check check to see if the URl exists
# retCodes:
# 99 - missing param
# 88 - problem with URL
# 0 - all good
alf_check_url(){

    if [ $# -eq 0 ]
    then
        alf_debug "URL param required"

        return 99
    fi

    url="$1"

    # curl comes with OS X right?
    # curl params: fsLI 
    # f = Fail silently
    # s = Silent or quiet mode
    # L = Follow a redirects
    # I = Fetch the HTTP-header only - we just want to see the url exists

    if alf_type_exists "curl"; then
        alf_debug "using curl"

        curl -fsLI -o "/dev/null" "$url"

        RC=$?

        if [ $RC -ne 0 ] 
        then
            OUTPUT="$url Unavailable, please check"
            alf_error $OUTPUT
            #echo "ERROR $OUTPUT"
            return 1

        else
            return 0
        fi
    elif alf_type_exists "cURL"; then
        alf_debug "using cURL"
        cURL -fsLI -o "/dev/null" "$url"

        RC=$?

        if [ $RC -ne 0 ] ; then
            OUTPUT="$url Unavailable, please check"
            alf_error $OUTPUT
            #echo "ERROR $OUTPUT"
            return 1
        else
            return 0
        fi
    elif alf_type_exists "wget"; then # not sure wget comes as standard but we'll try it anyway: -q = quiet, -S headers only
        alf_debug "using wget";
        wget -S -q "$url" 2>/dev/null
        RC=$?

        if [ $RC -ne 0 ] ; then
            OUTPUT="$url Unavailable, please check"
            alf_error $OUTPUT
            #echo "ERROR $OUTPUT"
            return 1
        else
            return 0
        fi       
    fi

}


# Git status information
alf_git_no_changes() {

    local git_state=$(alf_git_status)

    echo "git_state = $git_state" >>  "$LOGFILE"

    if [ "$git_state" = "" ]; then

        return 0
    else
        return 1
    fi
}


alf_is_main_git_repo() {

    if [ -z "$1" ]; then
        OUTPUT="URL NOT set, cannot continue"
        alf_error $OUTPUT
        return 1
    fi

    local main_git_repo="$1"
    local remote_origin_url=$(git config --get remote.origin.url)

    #echo "$main_git_repo"  >>  "$LOGFILE"
    #echo "$remote_origin_url"  >>  "$LOGFILE"

    if [ "$main_git_repo" = "$remote_origin_url" ]; then

    #echo "main repo: $remote_origin_url" >>  "$LOGFILE"
        return 0
    else
        return 1
    fi
}

alf_git_overwrite() {

user_response=$(osascript <<EOF
tell application "System Events"
    activate
    set userCanceled to false
    try
        set alertResult to display alert "Your git repo has local changes, do you want to over-write them?" ¬
            message "Your local changes will be LOST if you click YES" ¬
            buttons {"No", "Yes"} as warning ¬
            default button "No" cancel button "No" giving up after 5
    on error number -128
        set userCanceled to true
    end try

    if userCanceled then
        set alertResult to "NO"
    else if gave up of alertResult then
        set alertResult to "NO"
    else if button returned of alertResult is "Yes" then
        set alertResult to "YES"
    end if
end tell

EOF)

echo "$user_response"

}
