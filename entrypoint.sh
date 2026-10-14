#!/bin/sh

echo "Starting entrypoint script: $0 $*"

USERS_DIR=/config/users
USR_DIR=/etc/opensvc/namespaces/system/usr

# sync_users makes the users of the relay the ones of $USERS_DIR, a file per
# user, named after it and holding its password: it creates the users added,
# changes the password of the ones changed, and deletes the ones whose file is
# gone, among the users holding the heartbeat grant only, which it creates.
#
# The daemon reads a user at each authentication, so a change applies to the
# running relay, with no restart.
sync_users() {
    rc=0
    for file in "$USERS_DIR"/*
    do
        [ -f "$file" ] || continue
        user=$(basename "$file")
        if ! echo "$user" | grep -Eq '^[a-zA-Z][a-zA-Z0-9_]*$'
        then
            echo "skip user $user: a user name is a letter followed by letters, digits or _"
            rc=1
            continue
        fi
        if [ ! -f "$USR_DIR/$user.conf" ]
        then
            echo "create user $user"
            if ! om "system/usr/$user" create --kw grant=heartbeat || ! om "system/usr/$user" key add --name password --from "$file"
            then
                echo "failed to create user $user"
                rc=1
            fi
            continue
        fi
        if [ "$(om "system/usr/$user" key decode --name password 2>/dev/null)" != "$(cat "$file")" ]
        then
            echo "change the password of user $user"
            om "system/usr/$user" key change --name password --from "$file" || {
                echo "failed to change the password of user $user"
                rc=1
            }
        fi
    done
    for conf in "$USR_DIR"/*.conf
    do
        [ -f "$conf" ] || continue
        user=$(basename "$conf" .conf)
        [ -f "$USERS_DIR/$user" ] && continue
        [ "$(om "system/usr/$user" config get --kw grant 2>/dev/null)" = "heartbeat" ] || continue
        echo "delete user $user: $USERS_DIR/$user is gone"
        om "system/usr/$user" delete --local || {
            echo "failed to delete user $user"
            rc=1
        }
    done
    return $rc
}

# watch_users syncs the users at each change of $USERS_DIR, in the background
# of the relay agent: the files are installed anew when the users change, and
# the events of one install are merged into one sync.
watch_users() {
    [ -d "$USERS_DIR" ] || return
    inotifyd - "$USERS_DIR:wymnd" | while read -r event
    do
        while read -r -t 1 event
        do
            :
        done
        sync_users
    done &
}

# bootstrap configures the relay agent from /config, unless it is already: a
# cluster of its own node, the certificate of ssl/, and the cluster keywords of
# cluster/.
bootstrap() {
    if [ -f /etc/opensvc/cluster.conf ]
    then
        echo "Skip relay bootstrap from /config (cluster.conf already exists)"
        return 0
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
            om system/sec/cert key add --name "$key" --from "$file"
        done
    fi

    for file in $(ls /config/cluster/* 2>/dev/null)
    do
        key=$(basename "$file")
        echo "update cluster config keyword $key ..."
        om cluster config update --local --set "$key=$(cat $file)"
    done
}

case "$1" in
relay)
    bootstrap || exit 1
    sync_users
    watch_users
    exec om daemon run
    ;;
sync-users)
    sync_users
    exit $?
    ;;
*)
    exec "$@"
    ;;
esac
