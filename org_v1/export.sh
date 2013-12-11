#!/bin/bash
# create the trec files

set -x

EMACS_NAME=org-trec-export
OUTPUT_DIR=$PWD/tmp_export

mkdir -p $OUTPUT_DIR

# Start up emacs
emacs --daemon=$EMACS_NAME

# Find the org files to export
locate .org | grep 'org$' | grep '/home/jbalint/' | grep -v '/home/jbalint/\.' | grep -v '/MobileOrg/' | while read orgfile ; do

	# Compute export file
	NEWFILE=${orgfile%.org}.txt
	NEWFILE=${NEWFILE#/home/jbalint/}
	NEWFILE=$OUTPUT_DIR/${NEWFILE//\//_}

	# Run export
	emacsclient -s $EMACS_NAME -e "(progn (find-file \"$orgfile\") (load-file \"$PWD/org_trec_export.el\") (org-export-to-file 'trec \"$NEWFILE\") (kill-buffer))"
done

# shutdown emacs
emacsclient -s $EMACS_NAME -e "(kill-emacs)"
