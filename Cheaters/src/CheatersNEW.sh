#!/usr/bin/env bash

source utils.sh
source workflowHandler.sh

VERSION="1.4"
DATADIR=$(getDataDir)
#echo "$DATADIR"

if [ -z "$DATADIR" ]; then
	OUTPUT="$DATADIR NOT set, cannot continue"
	alf_error $OUTPUT
	echo "ERROR $OUTPUT"
	exit 1
fi

if ! alf_dir_exists "$DATADIR" ; then
	if ! $(mkdir "$DATADIR" 2> /dev/null); then
		OUTPUT="Cannot create $DATADIR cannot continue"
		alf_error $OUTPUT
		echo "ERROR $OUTPUT"
		exit 1	
	fi	
fi

CHEATERSDIR="$DATADIR/cheaters"
# edit this line if you have your own fork
MAIN_REPO="https://github.com/ttscoff/cheaters"

#echo "$CHEATERSDIR"

# grab a copy of the current version
# for future use. If it doesn't exist it's just blank
PREV_VERSION=$(getPref "version" 1 "myprefs.txt")

if [ "$PREV_VERSION" = "" ]; then
	PREV_VERSION=$VERSION
fi

#echo "$PREV_VERSION"

# this creates the $DATADIR/
# ${HOME}/Library/Application Support/Alfred 2/Workflow Data/com.stouty.cheaters2 dir
# if it doesn't already exist
setPref "version" "$VERSION" 1 "myprefs.txt"

# we need two workflows
# one is an AppleScript that runs the other
# and then kills the "Automator Launcher"
# this stops the spinning automator gear in the menu bar
WF="$PWD/Cheaters.workflow"
WF2="$PWD/CheatersRunner.workflow"
#AS_RUNNER="$PWD/runner.scpt"
#AS_PROG="$PWD/prog.scpt"


# quick check to see they exist

if ! alf_file_exists "$WF" ; then
	OUTPUT="$WF NOT found, cannot continue"
	alf_error $OUTPUT
	echo "ERROR $OUTPUT"
	exit
fi

if ! alf_file_exists "$WF2" ; then
	OUTPUT="$WF2 NOT found, cannot continue"
	alf_error $OUTPUT
	echo "ERROR $OUTPUT"
	exit
fi

# check git is installed
if ! alf_type_exists git ; then
	OUTPUT="git is NOT installed, cannot continue"
	alf_error $OUTPUT
	echo "ERROR $OUTPUT"
	exit
fi

#alf_debug "git installed"


if alf_dir_exists "$CHEATERSDIR" ; then
	#alf_debug "cheaters dir exists"
	cd "$CHEATERSDIR"

	# check is git repo
	if ! alf_is_git_repo ; then
		OUTPUT="NOT a git repo, initialising..."
		$(alf_git_init_repo "$MAIN_REPO")
	else
		
		# if main repo remote, regardless of branch,  with changes
		# 	- leave as is
		# if main repo remote and local branch
		# 	- leave as is
		# if forked repo 
		# - leave as is

		if (! alf_is_main_git_repo "$MAIN_REPO" ); then
			alf_debug "NOT main repo remote - forked  - no action"
			# do nothing
		fi

		if (! alf_git_no_changes ); then
			alf_debug "repo has changes - no action"
			# do nothing
		fi

		if (! alf_get_is_master_branch ); then
			alf_debug "NOT master branch - no action"
			# do nothing
		fi

		# if main repo remote, master branch, with no changes
		if (alf_is_main_git_repo "$MAIN_REPO") &&  (alf_git_no_changes) && (alf_get_is_master_branch) ;
		then
			alf_debug "main repo remote, master branch, with no changes"
			alf_debug "Pull down the latest changes"
			alf_debug "git pull --rebase origin master"
			
    		git pull --rebase origin master
    	fi
    fi
else
	alf_debug "cheaters dir does NOT exist, creating"

	if ! $(mkdir "$CHEATERSDIR" 2> /dev/null); then
		OUTPUT="Cannot create $CHEATERSDIR cannot continue"
		alf_error $OUTPUT
		echo "ERROR $OUTPUT"
		exit 1
	else
		cd "$CHEATERSDIR"
		$(alf_git_init_repo "$MAIN_REPO")

		RC=$?
		if [ $RC -ne 0 ];
		then
			OUTPUT="Could not clone cheaters git repo"
			alf_error $OUTPUT
			echo "ERROR $OUTPUT"
			exit
		else
			alf_debug "cheaters git repo cloned to $CHEATERSDIR"
		fi
	fi
fi

#echo "file://$CHEATERSDIR/index.html $WF"

URL="'file://$CHEATERSDIR/index.html' \"$WF\""

alf_debug "Running: automator -i \"$URL\"  \"$WF2\""

output=$(automator -i "$URL" "$WF2"  2>&1)
RC=$?

output=$(alf_remove_spesh "$output")

if [ $RC -ne 0 ]
then
	OUTPUT="$output - $WF2"
	alf_error "$OUTPUT"
	echo "ERROR $OUTPUT"
else
	OUTPUT="Ran $WF2"
	alf_success $OUTPUT
	# don't display a notification on success
	#echo "$OUTPUT"
fi
