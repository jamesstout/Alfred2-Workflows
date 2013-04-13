#!/bin/bash

source utils.sh
source workflowHandler.sh

VERSION="1.1"
DATADIR=$(getDataDir)
#echo "$DATADIR"

CHEATERSDIR="$DATADIR/cheaters"

#echo "$CHEATERSDIR"

# grab a copy of the current version
# for future use. If it doesn't exist it's just blank
PREV_VERSION=$(getPref "version" 1 "myprefs.txt")

if [ "$PREV_VERSION" = "" ]; then
	PREV_VERSION=$VERSION
fi

#echo "$PREV_VERSION"

# this creates the 
# ${HOME}/Library/Application Support/Alfred 2/Workflow Data/com.stouty.cheaters dir
# if it doesn't already exist
setPref "version" "$VERSION" 1 "myprefs.txt"

# we need two workflows
# one is an AppleScript that runs the other
# and then kills the "Automator Launcher"
# this stops the spinning automator gear in the menu bar
WF="$PWD/Cheaters.workflow"
WF2="$PWD/CheatersRunner.workflow"

# quick check to see they exist
if ! alf_file_exists $WF ; then
	OUTPUT="$WF NOT found, cannot continue"
	alf_error $OUTPUT
	echo "ERROR $OUTPUT"
	exit
fi

if ! alf_file_exists $WF2 ; then
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

if alf_file_exists "$CHEATERSDIR" ; then
	#alf_debug "cheaters dir exists"
	cd "$CHEATERSDIR"

	# check is git repo
	if ! alf_is_git_repo ; then
		OUTPUT="NOT a git repo"
		alf_error $OUTPUT
		echo "ERROR $OUTPUT"
		exit
	else
		#alf_debug "is a git repo"
		git_info=$(alf_git_status)

		# maybe use later
		#branch=$(alf_get_git_branch)

		#echo $branch

		#alf_debug "git_info = [$git_info]"

		if [ "$git_info" != "" ]
			then
				alf_debug "GIT not clean"
				# ask user if they want to reset
				git_overwrite=$(alf_git_overwrite)

				alf_debug "git_overwrite = [$git_overwrite]"

				if [ "$git_overwrite" == "YES" ]
				then
					alf_debug "git_overwrite = YES, updating"
					# this will just overwrite any uncommitted/stashed/tracked
					# files in the current branch to the local HEAD.
					# should this be FETCH_HEAD after a git fetch?
					git reset --hard HEAD
				else
					alf_debug "git_overwrite = NO, leaving"
				fi
		else
			alf_debug "GIT clean, updating"
			# not sure we need to do this
			# local branch should be up to date
			# could do something with origin/upstream remotes
			# but not at the moment
			git pull -q
		fi
	fi
else
	alf_debug "cheaters dir does NOT exist, cloning"
	# edit this line if you have your own fork
	git clone -q https://github.com/ttscoff/cheaters.git "$CHEATERSDIR"
	RC=$?

	if [ $RC -ne 0 ]
	then
		OUTPUT="Could not clone cheaters git repo"
		alf_error $OUTPUT
		echo "ERROR $OUTPUT"
		exit
	else
		alf_debug "cheaters git repo cloned"
		cd "$CHEATERSDIR"
	fi
fi

#echo "file://$CHEATERSDIR/index.html $WF"

output=`automator  -i "\"file://$CHEATERSDIR/index.html\" $WF" $WF2  2>&1 `
RC=$?

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
