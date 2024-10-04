#!/bin/bash

echo "Starting entrypoint script: $0 $*"

if [ "$1" = "relay" ]
then
    if [ -f /etc/opensvc/cluster.conf ]
    then
        echo "Skip relay bootstrap from /config (cluster.conf already exists)"
        exec om daemon start --foreground
    fi

    echo "Configuring OpenSVC with cluster name: ${HOSTNAME}"
    om cluster create --kw "cluster.name=${HOSTNAME}" --kw "cluster.secret=$(sed -e s/-//g /proc/sys/kernel/random/uuid)" --kw cluster.nodes=${HOSTNAME} --kw disks.schedule=@0 --kw packages.schedule=@0 --kw patches.schedule=@0 --kw sysreport.schedule=@0 --kw asset.schedule=@0 --kw checks.schedule=@0 --kw compliance.schedule=@0


    if ls /config/ssl/* >/dev/null 2>&1
    then
        echo "Processing configuration file for system/sec/cert"
        om system/sec/cert create
	for file in $(ls /config/ssl/* 2>/dev/null)
        do
            echo "Processing configuration file: $file"

            key=$(basename "$file")
            om system/sec/cert add --key "$key" --from "$file"
        done
    fi

    for file in $(ls /config/users/* 2>/dev/null)
    do
        RELAY_USER=$(basename $file)

        echo "Processing configuration file: $file"

        echo $RELAY_USER | egrep -q "^[a-zA-Z]\w*$" || {
            echo "Unsupported characters in user name $RELAY_USER"
        }

        om "system/usr/$RELAY_USER" create --kw grant=heartbeat || {
            echo "Failed to create user $RELAY_USER."
            exit 1
        }

        om "system/usr/$RELAY_USER" add --key password --from "$file" || {
            echo "Failed to set password for user $RELAY_USER."
            exit 1
        }
    done

    for file in $(ls /config/cluster/* 2>/dev/null)
    do
        key=$(basename "$file")
	om cluster set --kw "$key=$(cat $file)" --local
    done

    exec om daemon start --foreground
else
    exec "$@"
fi
