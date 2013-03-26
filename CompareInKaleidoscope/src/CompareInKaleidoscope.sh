#!/bin/bash

source utils.sh

WF=CompareInKaleidoscope.workflow

KS=/Applications/Kaleidoscope.app

# check Kaleidoscope.app is installed
alf_file_exists $KS
RC=$?

if [ $RC -ne 0 ]
then
	OUTPUT="Kaleidoscope is NOT installed"
	alf_error $OUTPUT
	echo "ERROR $OUTPUT"
	exit
fi

output=`automator $WF 2>&1`
RC=$?

if [ $RC -ne 0 ]
then
	OUTPUT="$output - $PWD/$WF"
	alf_error "$OUTPUT"
	echo "ERROR $OUTPUT"
else
	OUTPUT="Ran $WF"
	alf_success $OUTPUT
	# don't display a notification on success
	#echo "$OUTPUT"
fi