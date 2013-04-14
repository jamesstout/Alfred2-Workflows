#!/bin/bash

source utils.sh
source workflowHandler.sh

LOGFILE="$HOME/Desktop/Cheaters_DEBUG.txt"

$(env > "$LOGFILE")

VERSION="1.1"
DATADIR=$(getDataDir)
echo "\nDATADIR = $DATADIR" >>  "$LOGFILE"

CHEATERSDIR="$DATADIR/cheaters"

#echo "$CHEATERSDIR"

echo "CHEATERSDIR = $CHEATERSDIR" >>  "$LOGFILE"
echo "PWD = $PWD" >>  "$LOGFILE"
vers=$(bash --version)
echo "vers = $vers" >>  "$LOGFILE"

TYPE=$(type -a bash)
echo "TYPE = $TYPE" >>  "$LOGFILE"

WCH=$(which bash)
echo "WCH = $WCH" >>  "$LOGFILE"

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


echo "WF = $WF" >>  "$LOGFILE"
echo "WF2 = $WF2" >>  "$LOGFILE"



# quick check to see they exist
if ! alf_file_exists $WF ; then
	OUTPUT="$WF NOT found, cannot continue"

	echo "ERROR $OUTPUT" >>  "$LOGFILE"

	alf_error $OUTPUT

	echo "past wf alf_error" >>  "$LOGFILE"

	echo "ERROR $OUTPUT"
	exit
fi

if ! alf_file_exists $WF2 ; then
	OUTPUT="$WF2 NOT found, cannot continue"
	echo "ERROR $OUTPUT" >>  "$LOGFILE"

	alf_error $OUTPUT

	echo "past wf2 alf_error" >>  "$LOGFILE"

	echo "ERROR $OUTPUT"
	exit
fi

# check git is installed
if ! alf_type_exists git ; then
	OUTPUT="git is NOT installed, cannot continue"
	echo "ERROR $OUTPUT" >>  "$LOGFILE"

	alf_error $OUTPUT
	echo "ERROR $OUTPUT"
	exit
fi

#alf_debug "git installed"

echo "git installed" >>  "$LOGFILE"


if alf_file_exists "$CHEATERSDIR" ; then
	#alf_debug "cheaters dir exists"
	echo "cheaters dir exists" >>  "$LOGFILE"
	cd "$CHEATERSDIR"

	# check is git repo
	if ! alf_is_git_repo ; then
		OUTPUT="NOT a git repo"
		echo "$CHEATERSDIR NOT a git repo" >>  "$LOGFILE"

		alf_error $OUTPUT
		echo "ERROR $OUTPUT"
		exit
	else
		#alf_debug "is a git repo"
		echo "is a git repo" >>  "$LOGFILE"
		git_info=$(alf_git_status)

		# maybe use later
		#branch=$(alf_get_git_branch)

		#echo $branch

		#alf_debug "git_info = [$git_info]"

		if [ "$git_info" != "" ]
			then
				alf_debug "GIT not clean"
				echo "GIT not clean" >>  "$LOGFILE"
				# ask user if they want to reset
				git_overwrite=$(alf_git_overwrite)

				alf_debug "git_overwrite = [$git_overwrite]"

				echo "git_overwrite = [$git_overwrite]" >>  "$LOGFILE"

				if [ "$git_overwrite" == "YES" ]
				then
					alf_debug "git_overwrite = YES, updating"
					echo "git_overwrite = YES, updating" >>  "$LOGFILE"
					# this will just overwrite any uncommitted/stashed/tracked
					# files in the current branch to the local HEAD.
					# should this be FETCH_HEAD after a git fetch?
					git reset --hard HEAD
				else
					alf_debug "git_overwrite = NO, leaving"
					echo "git_overwrite = NO, leaving" >>  "$LOGFILE"
				fi
		else
			alf_debug "GIT clean, updating"
			echo "GIT clean, updating" >>  "$LOGFILE"
			# not sure we need to do this
			# local branch should be up to date
			# could do something with origin/upstream remotes
			# but not at the moment
			git pull -q
		fi
	fi
else
	echo "cheaters dir does NOT exist, cloning" >>  "$LOGFILE"
	alf_debug "cheaters dir does NOT exist, cloning"
	# edit this line if you have your own fork
	git clone -q https://github.com/ttscoff/cheaters.git "$CHEATERSDIR"
	RC=$?

	if [ $RC -ne 0 ]
	then
		OUTPUT="Could not clone cheaters git repo"
		echo "Could not clone cheaters git repo" >>  "$LOGFILE"
		alf_error $OUTPUT
		echo "ERROR $OUTPUT"
		exit
	else
		alf_debug "cheaters git repo cloned"
		echo "cheaters git repo cloned" >>  "$LOGFILE"
		cd "$CHEATERSDIR"
	fi
fi

echo "file://$CHEATERSDIR/index.html $WF" >>  "$LOGFILE"


output=`automator  -i "\"file://$CHEATERSDIR/index.html\" $WF" $WF2  2>&1 `
RC=$?

if [ $RC -ne 0 ]
then
	OUTPUT="$output - $WF2"
	echo "ERROR $OUTPUT" >>  "$LOGFILE"
	alf_error "$OUTPUT"
	echo "ERROR $OUTPUT"
else
	OUTPUT="Ran $WF2"
	echo "SUCCESS $OUTPUT" >>  "$LOGFILE"
	alf_success $OUTPUT
	# don't display a notification on success
	#echo "$OUTPUT"
fi
