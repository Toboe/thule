find /mnt/ftp/torrents/downloads -iname '*' -print | sed -n -E -e 's/.*.avi$/&/p' -e 's/.*.m4b/&/p'  -e 's/.*.mkv$/&/p' -e 's/.*vob/&/p' -e 's/.*m4v/&/p' -e 's/.*mp4/&/p' -e 's/.*VOB/&/p' -e 's/.*mp3/&/p' 
#cvlc --http-host 192.168.1.1:8081
#cvlc -sI http -sout udp://192.168.1.29 "/mnt/ftp/Movies/"
#cvlc --podcast-urls=http://www.echo.msk.ru/programs/citizen/rss-audio.xml

#vlc /mnt/ftp/torrents/play.m3u --http-host 192.168.1.1:8081 -I http --sout udp://192.168.1.2

#vlc -v /mnt/ftp/torrents/play.m3u --sout '#standard{access=udp{ttl=15},mux=ts{tsid=22,pid-video=23,pid-audio=24,pid-pmt=25,use-key-frames},dst=[multcast ip]}' --random --loop --volume 100

