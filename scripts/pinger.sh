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
    array=('8.8.8.8' '8.8.4.4' '195.5.62.1' '80.92.65.2' '98.139.183.24' '94.100.180.202' '97.74.104.218' '103.224.182.210' '67.215.92.219' '104.81.104.241' '72.52.6.254' '200.49.130.140')
    shuffle
    echo $array
}

function current_isp() {
    rt=$(netstat -rn|grep default)
    if [ "$(echo $rt|grep usb0)" != "" ]; then
	echo "fallback"
    elif [ "$(echo $rt|grep ppp0)" != "" ]; then
	echo "primary"
    else
	echo "nonet"
    fi
}

while :; do
    sleep 10
    ping -c 1 $(random_host)
    if [ $? -eq 0 ]; then
	continue
    fi
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
done
