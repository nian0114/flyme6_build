#!/system/bin/sh

FILE_INFO=/data/local/tmp/file.info

function traverse_dir {
    local root=$1
    # Using "-Z" to get the selable
    ls -a -Z ${root} | sed '/drwxr-xr-x u:object_r:system_file:s0        \./d' | sed '/drwxrwxrwt u:object_r:rootfs:s0             \.\./d' | sed '/^.*rfs_system.*/d' | while read line
    do
        name=${line##* }
        if [ "${line:0:1}" = "d" ]; then # directory
            traverse_dir ${root}/${name}
        fi

        echo "$line ${root:1}" >> ${FILE_INFO}
    done
}

echo "Traversing /system to retrieve filesystem_info ..."
traverse_dir "/system"
echo "Traversing /system to retrieve filesystem_info done"
