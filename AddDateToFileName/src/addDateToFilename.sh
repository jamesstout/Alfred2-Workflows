#!/bin/bash
 
source utils.sh

Q={query}
 
WF=addDateToFilename.workflow
 
output=`automator $WF 2>&1`
RC=$?

if [ $RC -ne 0 ]
then
	OUTPUT="$output - $PWD/$WF"
	OUTPUT=$(alf_remove_spesh "$OUTPUT")
	alf_error "$OUTPUT"
	echo "ERROR $OUTPUT"
else
	OUTPUT=$(alf_remove_spesh "$output")
	OUTPUT="Added date to $Q - Filename now $OUTPUT"
	alf_success "$OUTPUT"
	echo "SUCCESS $OUTPUT"
fi