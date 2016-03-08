#!/bin/bash

#
# blue_lock.sh for Bluetooth Proximity Detector
#
# 16/02/16 18:11 - Made by pasteu_e
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#



# Variables you may need to modify.

# DEVICE is the mac address of the bluetooth device
# LOGFILE_PATH is the path for the logfile
# CHECK_INTERVAL is the refresh rate of the main loop
# TOOFAR is the rssi code from the command "hcitool rssi [MAC:ADDR]
# LOCK_CMD and UNLOCK_CMD is the command to lock/unlock your computer
# HCITOOL is the path of the "hcitool" binary

DEVICE="3C:BB:FD:5C:3D:A8"
LOGFILE_PATH="/home/pasteu_e/.blue_lock_log.txt"
CHECK_INTERVAL=2
TOOFAR=-1
LOCK_CMD='/usr/bin/cinnamon-screensaver-command -l'
UNLOCK_CMD='/usr/bin/cinnamon-screensaver-command -d'
HCITOOL="/usr/bin/hcitool"


ISITANUMBER='^-?[0-9]+([.][0-9]+)?$'
DATE=`date +%Y-%m-%d:%H:%M:%S`
GLOBALSTAT=1

function check_connection()
{
    for s in `$HCITOOL con`
    do
	if [ $s == $DEVICE ]
	then
	    return 1
	fi
    done
    return 0
}

function try_to_connect()
{
    if [[ $GLOBALSTAT == 0 ]]
    then
	echo "$DATE : Problem detected. Unknown state -> Locking for security reason" >> $LOGFILE_PATH
        $LOCK_CMD > /dev/null 2>&1
    fi
    echo -e "disconnect $DEVICE" | bluetoothctl > /dev/null 2>&1
    sleep 2
    echo -e "connect $DEVICE" | bluetoothctl > /dev/null 2>&1
    sleep 4
}

function get_rssi()
{
    name=`$HCITOOL name $DEVICE`
    rssi=$($HCITOOL rssi $DEVICE | sed -e 's/RSSI return value: //g')

    if [[ $rssi =~ $ISITANUMBER && $rssi -le $TOOFAR ]]
    then
	echo "$DATE : Monitoring $name ---> [$DEVICE] has left proximity" >> $LOGFILE_PATH
	$LOCK_CMD > /dev/null 2>&1
    elif [[ $rssi =~ $ISITANUMBER && $rssi -ge $[$TOOFAR+1] ]]
    then
	echo "$DATE : Monitoring $name ---> [$DEVICE] is within proximity" >> $LOGFILE_PATH
	$UNLOCK_CMD > /dev/null 2>&1
    else
	echo "$DATE : Problem detected. Unknown state -> Locking for security reason" >> $LOGFILE_PATH
	$LOCK_CMD > /dev/null 2>&1
    fi    
}

echo "" >> $LOGFILE_PATH
echo "" >> $LOGFILE_PATH
echo "" >> $LOGFILE_PATH
echo "" >> $LOGFILE_PATH
echo "" >> $LOGFILE_PATH
echo "Log from $DATE" >> $LOGFILE_PATH
echo "" >> $LOGFILE_PATH

while [ true ]
do
    DATE=`date +%H:%M:%S`
    check_connection
    if [ $? == 0 ]
    then
	echo "$DATE : Try to connect to [$DEVICE]" >> $LOGFILE_PATH
	try_to_connect
	GLOBALSTAT=1
    else
	GLOBALSTAT=0
	get_rssi
    fi
    sleep $CHECK_INTERVAL
done
