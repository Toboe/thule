#!/bin/bash
count=0
media_l="/home/ronin47/.local/share/vlc/ml.xspf"
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > ${media_l}
echo "<playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\" xmlns:vlc=\"http://www.videolan.org/vlc/playlist/ns/0/\">" >> ${media_l}
echo "<title>Media Library</title>" >> ${media_l}
echo "<trackList>" >> ${media_l}

#find /mnt/ftp/Movies/Documentary 
find /mnt/ftp/Movies/ -iname '*' -print | sed -n -E -e 's/.*mp3/&/p' -e 's/.*wma/&/p' -e 's/.*m4a/&/p' -e 's/.*mp4/&/p' -e 's/.*m4b/&/p' -e 's/.*MP3/&/p' -e 's/.*avi/&/p' -e 's/.*vol/&/p' -e 's/.*VOL/&/p'| sed 's/^\./\/mnt\/ftp\/Movies\//g' |  sed '/\/._/d' > /tmp/allavi

#find /mnt/ftp/Movies/Ani -iname '*' -print | sed -n -E -e 's/.*mp3/&/p' -e 's/.*wma/&/p' -e 's/.*m4a/&/p' -e 's/.*mp4/&/p' -e 's/.*m4b/&/p' -e 's/.*MP3/&/p' -e 's/.*avi/&/p' -e 's/.*vol/&/p' -e 's/.*VOL/&/p'| sed 's/^\./\/mnt\/ftp\/Movies\//g' |  sed '/\/._/d' >> /tmp/allavi

#find /mnt/ftp/Movies/Documentary -iname '*' -print | sed -n -E -e 's/.*mp3/&/p' -e 's/.*wma/&/p' -e 's/.*m4a/&/p' -e 's/.*mp4/&/p' -e 's/.*m4b/&/p' -e 's/.*MP3/&/p' -e 's/.*avi/&/p'
#-e 's/.*vol/&/p' -e 's/.*VOL/&/p'| sed 's/^\./\/mnt\/ftp\/Movies\//g' |  sed '/\/._/d' > /tmp/allavi



while read line; do


#echo $line;
#sleep 1;
count=$(($count+1));

echo "<track>" >> ${media_l};
echo "<location>"$line"</location>" >> ${media_l};

#echo -e "$line" >> ${media_l};
#echo "</location>" >> ${media_l};

echo "<title></title>" >> ${media_l};
echo "<creator></creator>" >> ${media_l};
echo "<duration>0</duration>" >> ${media_l};
echo "<extension application=\"http://www.videolan.org/vlc/playlist/0\">" >> ${media_l};
echo "<vlc:id>"$count"</vlc:id>" >> ${media_l};

#echo $count >> ${media_l};
#echo "</vlc:id>" >> ${media_l};

echo "</extension>" >> ${media_l};
echo "</track>" >> ${media_l};
done < /tmp/allavi

echo "</trackList>" >> ${media_l}
echo "<extension application=\"http://www.videolan.org/vlc/playlist/0\">" >> ${media_l}
echo "</extension>" >> ${media_l}
echo "</playlist>" >> ${media_l}

echo $count 


