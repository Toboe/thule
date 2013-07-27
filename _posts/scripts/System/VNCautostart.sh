#!/bin/sh
echo -n 'Start_autologin'
case "$1" in
start)
       # su -l ronin47 -c '/usr/local/bin/vncserver :1 -geometry 1024x600 -name ronin' 
	#su -l gingerking -c '/usr/local/bin/vncserver :2 -geometry 1024x600 -name Hail_to_the_King!' &>/dev/null	
 /home/vpnstart.sh	
;;
stop)
      su -l ronin47 -c '/usr/local/bin/vncserver -kill :1'
        ;;
stop2)
	su -l gingerking -c '/usr/local/bin/vncserver -kill :2'
	;;
*)
        echo "Usage: `basename $0` {start|stop}" >&2
        exit 64
        ;;
restart)
	su -l ronin47 -c '/usr/local/bin/vncserver -kill :1' &>/dev/null
	su -l ronin47 -c '/usr/local/bin/vncserver :1 -geometry 1024x600 -name ronin' &>/dev/null
	su -l gingerking -c '/usr/local/bin/vncserver -kill :2' &>/dev/null
	su -l gingerking -c '/usr/local/bin/vncserver :2 -geometry 1024x600 -name Hail_to_tge_king' &>/dev/null
;;

esac


exit 0
