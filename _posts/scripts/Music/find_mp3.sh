#!/bin/bash
echo " " 1>/tmp/mp3.log
count=0
cd /mnt/ftp/Music/
echo $PWD
sleep 5
echo " " > ./A1l_music.m3u
if [ "$1" = "--delete" ]
#if [ -n "$1"]
	then
        	echo "[Delete all M3U]"
                	for i in `find ./ -name "*.m3u" | grep m3u`
                		do
				echo $i;
				count=$(($count+1));
                		rm $i
                		done

	echo "Deleted" $count " m3u playlists"
        exit

else

#cd /mnt/ftp/Music
#echo " " > All_music.m3u
#for i in `ls -l ./ | grep ^d | awk '{print $9}' | grep -v "^\."`
for i in `find . -type d -maxdepth 1 | grep ^\./ | sed 's/\.\///g' | grep -v '^\.' | grep -v '^\AudioBooks'  `
  #| grep -v '^\Podcasts'`
#echo 'Music Sample lol' | tr ' ' '_'
	do
		echo $i
		#pwd

			err=$( ls -l $i 2>&1 >/dev/null)

			if  [ -n "$err" ] ; then
#			 echo $err
			continue
			fi
	#	sleep 1
    find $i \( -name "*.mp3" -o -name "*.MP3" \) -exec id3v2 --artist "$i" "{}" \;
		sdir=`echo $i"/"$i".m3u"`
#		sdir=`echo "$i"_playlist.m3u"`
		echo $count "-->"  $sdir
#		cd $i
#                echo $i
#count=0
count=$(($count+1))
#count='expr $count+1'
#((count++))
#inc count
echo $i " --->  " $count  1>>/tmp/mp3.log
 #		find $i -name "*.mp3"
		find $i -iname '*' -print | sed -n -E -e 's/.*mp3/&/p' -e 's/.*m4a/&/p' -e 's/.*mp4/&/p' -e 's/.*m4b/&/p' -e 's/.*MP3/&/p' |sed 's/^'$i'/\./g' > $sdir
#'s/.*wma/&/p'
cat $sdir | sed -e "s/^./\/mnt\/ftp\/Music\/$i/g" >> ./A1l_music.m3u
#ll=ll+1
if [ "$count" = "$1" ]; then
  exit
fi

#find $i -iname '*' -print | sed -n -E -e 's/.*mp3/&/p' -e 's/.*wav/&/p' -e 's/.*wma/&/p' | sed 's/^'$i'/\./g'
#	cat $sdir
#		cd ../
#cat Marche/Marche_playlist.m3u | sed 's/^/\.\//g'
#cat $sdir

done
#echo $count
#find . -name "*mp3" | while read FILENAME
#do
#locate
#done
#find ./ -name "*.m3u" > m3u.list
#fi
#echo $count

#/usr/local/etc/rc.d/mt-daapd restart 9 1>>/tmp/mp3.log
#tail -f /var/log/mt-daapd.log

#done
fi
#clear
#tail -f ./All_music.m3u
