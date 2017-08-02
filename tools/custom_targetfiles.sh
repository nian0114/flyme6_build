#!/bin/bash

function custom_flymeRes()
{
    if [ -f $SYSTEM_DIR/framework/flyme-res/flyme-res.apk ]; then
        mv $SYSTEM_DIR/framework/flyme-res/flyme-res.apk $SYSTEM_DIR/framework/flyme-res/flyme-res.jar
    fi
}

function clear_Ds()
{
    find $1 -name .DS_Store -exec rm -rf {} \;
}

TARGET_FILES_DIR=$1
VENDOR_FILES_DIR=`pwd`/vendor

SYSTEM_DIR=$TARGET_FILES_DIR/SYSTEM
META_DIR=$VENDOR_FILES_DIR/META

RECOVERY_LINK=`pwd`/../../build/tools/releasetools/recoverylink.py

cp -f $META_DIR/linkinfo.txt $SYSTEM_DIR
python $RECOVERY_LINK $TARGET_FILES_DIR
rm -f $SYSTEM_DIR/linkinfo.txt
custom_flymeRes
clear_Ds $TARGET_FILES_DIR
