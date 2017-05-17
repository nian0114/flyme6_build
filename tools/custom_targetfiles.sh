#!/bin/bash

TARGET_FILES_DIR=$1
VENDOR_FILES_DIR=`pwd`/vendor

SYSTEM_DIR=$TARGET_FILES_DIR/SYSTEM
META_DIR=$VENDOR_FILES_DIR/META

RECOVERY_LINK=`pwd`/../../build/tools/releasetools/recoverylink.py

cp -f $META_DIR/linkinfo.txt $SYSTEM_DIR
python $RECOVERY_LINK $TARGET_FILES_DIR
rm -f $SYSTEM_DIR/linkinfo.txt
