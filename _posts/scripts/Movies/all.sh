#!/bin/bash
count=0
media_l="/home/ronin47/.local/share/vlc/ml.xspf"
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > ${media_l}
echo "<playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\" xmlns:vlc=\"http://www.videolan.org/vlc/playlist/ns/0/\">" >> ${media_l}
echo "<title>Media Library</title>" >> ${media_l}
echo "<trackList>" >> ${media_l}

find /mnt/ftp/Movies/ -iname '*' -print | sed -n -E -e 's/.*mp3/&/p' -e 's/.*wma/&/p' -e 's/.*m4a/&/p' -e 's/.*mp4/&/p' -e 's/.*m4b/&/p' -e 's/.*MP3/&/p' -e 's/.*avi/&/p' -e 's/.*vol/&/p' -e 's/.*VOL/&/p'| sed 's/^\./\/mnt\/ftp\/Movies\//g' |  sed '/\/._/d' > /tmp/allavi

while read line; do
count=$(($count+1));

echo "<track>" >> ${media_l};
echo "<location>"$line"</location>" >> ${media_l};

#echo -e "$line" >> ${media_l};
#echo "</location>" >> ${media_l};

echo "<title></title>" >> ${media_l};
echo "<creator></creator>" >> ${media_l};
echo "<duration>0</duration>" >> ${media_l};
echo "<extension application="http://www.videolan.org/vlc/playlist/0">" >> ${media_l};
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


#for i in `find /mnt/ftp/Movies/ -iname '*' -print | sed -n -E -e #'s/.*avi/&/p' | sed 's/^\./\/mnt\/ftp\/Movies\//g' |  sed '/\/._/d' #'
#do 
#count=$(($count+1))
#fi
#echo $count


2x2	http://83.142.8.2:8002
	



		
		
		find ./ -iname '*' -print | sed -n -E -e 's/.*mp3/&/p' -e 's/.*wma/&/p' -e 's/.*m4a/&/p' -e 's/.*mp4/&/p' -e 's/.*m4b/&/p' -e 's/.*MP3/&/p' |sed 's/^\./\/mnt\/ftp\/Movies\//g' |  sed '/\/._/d'  
		
find ./ -iname '*' -print | sed -n -E -e 's/^._*.mp4/&/p'	



find ./ -iname '*' -print | sed -n -E -e 's/.*avi/&/p' | sed -n -E -e 's/Documentary/&/p'| sed 's/^\./\/mnt\/ftp\/Movies\//g' |  sed '/\/._/d' 
	
		
		
		 sed '/\/._/d'  
		
		
		<track>
			<location>file:///Volumes/Video/Eraserhead%20%5B1977%5D.m4v</location>
			<title></title>
			<creator></creator>
			<duration>0</duration>
			<extension application="http://www.videolan.org/vlc/playlist/0">
				<vlc:id>0</vlc:id>
			</extension>
		</track>
		<track>
			<location>file:///Volumes/Video/Heavy%20Metal.m4v</location>
			<extension application="http://www.videolan.org/vlc/playlist/0">
				<vlc:id>1</vlc:id>
			</extension>
		</track>
		<track>
			<location>udp://@192.168.1.29</location>
			<extension application="http://www.videolan.org/vlc/playlist/0">
				<vlc:id>2</vlc:id>
			</extension>
		</track>
	</trackList><extension application="http://www.videolan.org/vlc/playlist/0">
		<vlc:node title="Empty Folder">
			<vlc:item tid="0" />
		</vlc:node>
			<vlc:item tid="1" />
			<vlc:item tid="2" />
	
	
	
	
	
	</extension>
</playlist>
