#!/usr/bin/env bash

LOGFILE="$HOME/Desktop/Cheaters_DEBUG.txt"


# xargs strips leading/trailing whitespace and quotes. tr removes () chars
# usage: OUTPUT=$(alf_remove_spesh "$OUTPUT")
function alf_remove_spesh(){

    local result=`echo "$1" | xargs | tr -d '()'`
    echo "$result"
}

alf_guess_path(){

    if [ -n "$HOME" ]; then
        cd "$HOME"
    else
        if home_path="$(alf_dir_resolve ~)"; then
           cd "$home_path"
        else
            alf_error "Cannot find HOME or ~"
            return 1
        fi
    fi

    declare -a potentials=($(find . -type f  -name '.*' -maxdepth 1  -exec grep -sl 'export PATH' {} \; | grep -v hist | grep -v orig))

    if [ "${#potentials[@]}" -lt "1" ]; then
        alf_error 'No profiles to source'
        return 1
    fi

    longestPath="0"
    longestPathStr=""

    for ((i=0; i<${#potentials[@]}; ++i));
    do
    #echo "animal $i: ${tmp[$i]}";
    #paths=("${paths[@]}" "$(which ${uniq[$i]})")
    #echo "animal $i: ${potentials[$i]}";

    declare -a path_comps=($(grep "export PATH" ${potentials[$i]} )) #| tr -s ':' ' ' | tr -s '=' ' '))

    if [ "${#path_comps[@]}" -lt "1" ]; then
        alf_error 'No export PATHS found'
        return 1
    fi

    #echo "path $path";
    #$(dirname $path)

        for ((ii=0; ii<${#path_comps[@]}; ++ii));
            do
            #echo "aniimal $ii: ${tmp[$ii]}";
                #echo "animal $ii: ${path_comps[$ii]}";

            #paths=("${paths[@]}" "$(whiich ${uniiq[$ii]})")
            if grep '^PATH' <<<${path_comps[$ii]} &> /dev/null; then

               # echo "start $ii: ${path_comps[$ii]}";

                TMP_PATH=${path_comps[$ii]}

                #echo "tp = $TMP_PATH"
                #echo "tp = ${#TMP_PATH}"
                #echo "lp = $longestPath"


                if [ "${#TMP_PATH}" -gt "$longestPath" ]; then
                  #  echo "new longest"

                    longestPath=${#TMP_PATH}
                    longestPathStr=$TMP_PATH

                   # echo "new longeststr: $longestPathStr"
                   # echo "new longest: $longestPath"
                fi

            fi

            #TMP_PATH=""

            #echo "path $path";
            #$(dirname $path)
            done

done

if [ "${#longestPathStr}" -gt "0" ]; then
    printf $longestPathStr
else
    alf_error 'No PATHS found'
    return 1
fi

}


alf_dir_resolve()
{
    # don't quote $1 here, we will really only use to expand ~
    cd $1 2>/dev/null || return $?    # cd to desired directory; if fail, quell any error messages but return exit status
    echo "`pwd -P`" # output full, link-resolved path
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
alf_get_cmd_path() {

    if [ $# -gt 1 ] 
    then
        alf_error 'Usage: alf_get_all_types CMD'
        return 1
    fi

    if grep -v '^[-0-9a-zA-Z\/]*$' <<<$1 &> /dev/null;
    then     
        alf_error 'Usage: alf_get_all_types CMD - no spaces/regex'
        return 1;
    fi

    # for later .....
    # declare -A args
    # args[0]="nil"
    # args[1]="nil"
    # args[2]=" | head -1 | awk '{ print \$2 }'"
    # args[3]=" | awk '{ print \$3 }'"
    # args[4]=" | head -1  | awk '{ print \$4 }'"
    # args[5]=" -h | tail -r | tail -2 | head -1 |  awk '{ print \$4 }'"

    # versionCmd="--version"

    # declare -A cmds
    # cmds[0]="nil"
    # cmds[1]=""
    # cmds[2]="php"
    # cmds[3]="git"
    # cmds[4]="grep any GNU"
    # cmds[5]="7z"
    # cmds[5]="7za 7zr"
    # echo ${cmds[@]}



    if ! TMP_PATH2="$(alf_guess_path)"; then
        alf_error "Cannot alf_guess_path, setting to defaults"
        TMP_PATH2="PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/bin:/usr/sfw/bin"
    fi

    #TMP_PATH2=$(alf_guess_path)
    #echo "path2 is $TMP_PATH2"
    ##echo "path is $PATH"

    # this sets the PATH env var
    eval $TMP_PATH2

    #echo "path is $PATH"

    local retVal
    local count

    # get all types of $1
    declare -a ALL_TYPES=$(type -ap "$1")

    # should use ${#ALL_TYPES[@]} to get the
    # number of elements in the array
    # but if it's empty, this seems to return 1
    # so check the Number of characters in the 
    # first element of the array instead
    count=${#ALL_TYPES}

    # none found, return error
    if [ $count = "0" ]; then
        return 1
    fi

    # sometimes we get dupes, remove
    declare -a uniq=($(printf "%s\n" "${ALL_TYPES[@]}" | sort -u))

    count=${#uniq[@]} 

    # just got one?, return it
    if [ $count -eq 1 ]; then
        retVal="${uniq[0]}"
    else
        # otherwise look up the one with the greatest version number
        # if it's git (for the moment)
        if grep  -v '.*git$' <<<$1  &> /dev/null;
        then     
            retVal="${uniq[0]}"
        else

            local latestVersion
            local greatestCmd

            for index in ${!uniq[*]}
            do
                greatestCmd=${uniq[$index]}
                newlatestVersion="$(${uniq[$index]} --version | awk '{ print $3 }')"

                if [ -z "$newlatestVersion" ]; then
                        # default to first version
                        retVal="${uniq[0]}"
                        break
                fi

                if [[ "$newlatestVersion" > "$latestVersion" ]]; then
                    latestVersion="$newlatestVersion"
                    greatestCmd="${uniq[$index]}"
                fi
            done

            retVal="$greatestCmd"
        fi
    fi

    printf $retVal
}

# Test whether a command exists
alf_type_exists() {
    if [ $(type -P "$1") ]; then
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

# must be in the dir,and takes a URL
alf_git_init_repo() {

    if [ $# -eq 0 ]
    then
        alf_error "Repo URL param required"
        return 99
    fi

    main_git_repo="$1"

    if $(alf_check_url "$main_git_repo"); then
        return 0
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

    #echo "git_state = $git_state" >>  "$LOGFILE"

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
