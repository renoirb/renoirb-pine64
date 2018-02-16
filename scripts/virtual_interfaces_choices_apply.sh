#!/bin/bash

LOCALIP=1.1.1.1
REMOTEIPS=(2.2.2.2 3.3.3.3 4.4.4.4)

# existing local device where $LOCALIP is attached
LOCAL_DEV=vmbr0

# New bridge device where $VXLAN_DEV devices will be attached
BRIDGE_DEV=vxbr0

# Will set up one vxlan* device per remote IP.
# For example, with two remote IPs (three servers in total), we will set up vxlan0 and vxlan1 devices,
# attached to BRIDGE_DEV (vxbr0)
VXLAN_DEV=vxlan

# Port used for vxlan
PORT=4789

# If set to 1 - only print commands we would run
DRYRUN=1

# No need to change anything below
function vxrun() {
    COMMAND=$@
    if [ "$DRYRUN" -eq 1 ] ; then
        echo $COMMAND
    else
        $COMMAND
    fi
}

function vxlan_check() {
    brctl show $BRIDGE_DEV 2>&1 | grep -q 'No such device'
    if [ $? -ne 0 ] ; then
        echo "vxlan already set up?"
        exit 1
    fi
    ip addr | grep -q " $VXLAN_DEV"
    if [ $? -eq 0 ] ; then
        echo "vxlan already set up?"
        exit 1
    fi
}

function vxlan_start() {
    # first, check if we have any vxlan devices or interfaces
    vxlan_check

    VXLAN_DEVICES=$((${#REMOTEIPS[@]} - 1))

    which brctl >/dev/null
    if [ $? -ne 0 ] ; then
        vxrun echo brctl command not found
        exit 1
    fi

    # If there is more than one remote IP, we have to add ebtables rules to prevent looping
    if [ "${#REMOTEIPS[@]}" -gt 1 ] ; then
        # Check if ebtables is installed
        which ebtables >/dev/null
        if [ $? -ne 0 ] ; then
            vxrun echo ebtables command not found
            exit 1
        fi
        # Our vxlan* devices must not pass traffic to each other
        for i in $(seq 0 $VXLAN_DEVICES) ; do
            for j in $(seq 0 $VXLAN_DEVICES) ; do
                if [ $i -ne $j ] ; then
                    vxrun ebtables -A FORWARD -i ${VXLAN_DEV}${i} -o ${VXLAN_DEV}${j} -j DROP
                fi
            done
        done
    fi

    # Add bridge
    vxrun brctl addbr $BRIDGE_DEV
    #vxrun brctl stp $BRIDGE_DEV on
    vxrun ip link set up $BRIDGE_DEV

    # Add vxlan* devices
    for VXLAN_DEVICE in $(seq 0 $VXLAN_DEVICES) ; do
        vxrun ip link add ${VXLAN_DEV}${VXLAN_DEVICE} type vxlan id ${VXLAN_DEVICE} remote ${REMOTEIPS[$VXLAN_DEVICE]} local $LOCALIP dev $LOCAL_DEV dstport $PORT
        vxrun ip link set up dev ${VXLAN_DEV}${VXLAN_DEVICE}
        vxrun brctl addif $BRIDGE_DEV ${VXLAN_DEV}${VXLAN_DEVICE}
    done
}

function vxlan_stop() {
    vxrun ip link set down $BRIDGE_DEV
    vxrun brctl delbr $BRIDGE_DEV
    # List all vxlan devices
    VXLAN_SETS=$(ip addr | awk -F: "/$VXLAN_DEV/ {print \$2}")
    for VXLAN_SET in $VXLAN_SETS ; do
        vxrun ip link set down $VXLAN_SET
        vxrun ip link del $VXLAN_SET
    done
    # We assume ebtables are only used for our vxlan setup script
    ebtables -F
}

function vxlan_status() {
    echo vxlan bridge:
    brctl show $BRIDGE_DEV
    echo
    echo vxlan interfaces:
    ip link show | grep -A 1 $VXLAN_DEV
    echo
    ebtables -L
}

MODE=$1
set -u
# start, stop, restart
if [ "$MODE" == "start" ] ; then
    vxlan_start
elif [ "$MODE" == "stop" ] ; then
    vxlan_stop
elif [ "$MODE" == "restart" ] ; then
    vxlan_stop
    vxlan_start
elif [ "$MODE" == "status" ] ; then
    vxlan_status
else
    echo " * Usage: $0 {start|stop|restart|status}"
    exit 1
fi
