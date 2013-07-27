find . -iname '*' -print | sed -n -E -e 's/.*mp3/&/p' -e 's/.*wav/&/p' -e 's/.*wma/&/p' > appo.m3u
#find . -iregex '.*\.\(mp3\|wav\|wma\)' -print > app.m3u
