#!/bin/bash

function primary_isp() {
	route add default dev ppp0
}

function fallback_isp() {
	route add default gw 192.168.0.1
}

function clear_default() {
	route delete default
}

# Uses a global array variable.  Must be compact (not a sparse array).
# Bash syntax.
function shuffle() {
       local i tmp size max rand
       # $RANDOM % (i+1) is biased because of the limited range of $RANDOM
       # Compensate by using a range which is a multiple of the array size.
       size=${#array[*]}
       max=$(( 32768 / size * size ))

       for ((i=size-1; i>0; i--)); do
          while (( (rand=$RANDOM) >= max )); do :; done
          rand=$(( rand % (i+1) ))
          tmp=${array[i]} array[i]=${array[rand]} array[rand]=$tmp
       done
}

function random_host() {
    array=('8.8.8.8' '8.8.4.4' '195.5.62.1' '80.92.65.2' '98.139.183.24' '94.100.180.202' '103.224.182.210' '67.215.92.219' '72.52.6.254' '216.58.214.1' '62.140.243.1' '151.101.0.1' '104.16.81.1' '104.160.182.1')
    shuffle
    echo $array
}

function current_isp() {
    rt=$(netstat -rn|egrep '^0.0.0.0')
    if [ "$(echo $rt|grep usb0)" != "" ]; then
	echo "fallback"
    elif [ "$(echo $rt|grep ppp0)" != "" ]; then
	echo "primary"
    else
	echo "nonet"
    fi
}

function run_switch() {
    case $(current_isp) in
	primary)
		echo 'Switching from primary ISP...'
		clear_default
		fallback_isp
		;;
	fallback)
		echo 'Switching from secondary ISP...'
		clear_default
		primary_isp
		;;
	nonet)
		echo 'No network! Trying primary isp...'
		primary_isp
		if [ $? -ne 0 ]; then
		    echo 'Trying secondary isp...'
		    fallback_isp
		fi
		;;
	*)
		echo 'What?'
		;;
    esac
}

limit=3
while :; do
    sleep 10
    ping -c 1 $(random_host)
    if [ $? -eq 0 ]; then
	if [ $cnt -gt 0 ]; then
		cnt=$(( cnt - 1 ))
		echo 'Ping ok, decreasing counter...'
	fi
	continue
    fi
    cnt=$(( cnt + 1 ))
    if [ $cnt -ge ${limit} ]; then
	cnt=0
	echo "Limit ${limit} reached, running ISP switch..."
	run_switch
    fi
done
