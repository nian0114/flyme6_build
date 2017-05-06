#!/bin/bash

USER=`whoami`
FILE_INFO=$META_DIR/file.info

function traverse_dir {
    local root=$1
    # Using "-Z" to get the selable
    ls -al -Z $root | sed 's/-\./-/g'| sed 's/-x\./-x/g' | sed "/$USER/d" | sed '/total/d' | awk '{printf("%s %-8s %-8s          %s %s %s %s %s\n",$1,$3,$4,$5,$10,$11,$12,$13)}' | sed '/s0 \./d' | sed 's/1014/dhcp/g' | sed 's/2000/shell/g' | sed 's/3003 /inet /g' | while read line
    do
        name=${line##* }
        if [ "${line:0:1}" = "d" ]; then # directory
            traverse_dir $root/$name
        fi

        echo "$line $root" >> $FILE_INFO
    done
}

echo "Traversing /system to retrieve filesystem_info ..."
traverse_dir "system"
echo "Traversing /system to retrieve filesystem_info done"
