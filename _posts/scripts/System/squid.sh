sort -r -n +4 -5 access.log | awk '{print $5, $7}' | head -25
Как мне найти наибольший объект в моем кеше?

 


#######
purge -n -a -s -c /etc/squid/squid.conf -C /tmp/MP3s/ -e '\.mp3|\.wav'
purge -n -a -s -c /etc/squid/squid.conf -C /tmp/MP3s/ -e '\.mp3$'
Вытаскиваем только *.mp3
I've had limited success messing with this line:

'#awk '{print $7}' /var/log/squid/access.log | grep www.example.com | xargs -n 1 squidclient -m PURGE

purge -n -a -s -c /etc/squid/squid.conf -C /tmp/MP3s/ -e '\.mp3$'

/usr/local/bin/sarg -l /var/log/squid/access.log 


cat /var/log/squid/access.log|awk '{print $7}'|grep -o "\.[a-z]\{1,5\}$"|sort|uniq


 find /cache | while read a; do (file $a | grep PNG)&& cp $a /tmp/$a.png; done
