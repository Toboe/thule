awk 'NR==2' buildinstructins
find . -iname '*' -print | sed -n -E -e 's/.*mp3/&/p' -e 's/.*wav/&/p' -e 's/.*wma/&/p' > appo.m3u
#find . -iregex '.*\.\(mp3\|wav\|wma\)' -print > app.m3u

VIM:

 each time you hit Ctrl-W, you delete the word to the left of the cursor
hit Ctrl-U.  Everything to the left of the cursor will be deleted, leaving you with:

