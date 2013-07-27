#!/bin/bash
touch /tmp/root
count=0
countdir=1
media_l="/home/ronin47/.local/share/vlc/ml.xspf"
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > ${media_l}
echo "<playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\" xmlns:vlc=\"http://www.videolan.org/vlc/playlist/ns/0/\">" >> ${media_l}
echo "<title>Media Library</title>" >> ${media_l}
echo "<trackList>" >> ${media_l}

#/mnt/ftp/Movies
for i in `find /mnt/ftp/Movies/. -type d -maxdepth 1 | sed 's/\.\///g' | sed 's/\/mnt\/ftp\/Movies\///g' `

        do
d=""
#echo $i
sleep 1

if [ "$i" = "." ]

then
d=" -maxdepth 1"
else
fi

#echo $d
find /mnt/ftp/Movies/$i $d -iname '*' -print | sed -n -E -e 's/.*mp3/&/p' -e 's/.*wma/&/p' -e 's/.*m4a/&/p' -e 's/.*mp4/&/p' -e 's/.*m4b/&/p' -e 's/.*wmv/&/p' -e 's/.*avi/&/p' -e 's/.*asf/&/p' > /tmp/allavi
#-e 's/.*mov/&/p' -e 's/.*wmv/&/p' > /tmp/allavi


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

if [ "$i" = "." ]
then

#echo $i >> /tmp/root
touch /tmp/root
echo $count >> /tmp/root
else
touch /tmp/$i
#echo $i > /tmp/$i
echo $count >> /tmp/$i

fi
	done < /tmp/allavi

done


echo "</trackList>" >> ${media_l}
echo "<extension application=\"http://www.videolan.org/vlc/playlist/0\">" >> ${media_l}


for i in `find . -type d -maxdepth 1 | sed 's/\.\///g' | sed 's/\./root/g' `
        do
echo "<vlc:node title=\""$i"\">"  >> ${media_l}
while read line; do
echo "<vlc:item tid=\""$line"\" />"  >> ${media_l}
done < /tmp/$i
echo "</vlc:node>"  >> ${media_l}
rm /tmp/$i
		done

echo "</extension>" >> ${media_l}
echo "</playlist>" >> ${media_l}

echo $count 
#rm /tmp/root

