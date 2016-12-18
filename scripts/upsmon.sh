#!/bin/bash

echo 199 > /sys/class/gpio/export
echo 200 > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio199/direction
echo in > /sys/class/gpio/gpio200/direction

get_ac_status() {
    ac1=`cat /sys/class/gpio/gpio199/value`
    ac2=`cat /sys/class/gpio/gpio200/value`

    if [ "0$ac1" -eq 1 -o "0$ac2" -eq "1" ]; then
        export ACJACK="on"
    else
        export ACJACK="off"
    fi
}

cnt=0
while :
do
    get_ac_status
    echo $ACJACK - $cnt
    if [ "$ACJACK" == "off" ]; then
        cnt=$(( cnt + 1 ))
    else
	cnt=0
    fi
    if [ $cnt -ge 1440 ]; then
        cnt=0
        shutdown -P now
    fi

    sleep 1;
done
