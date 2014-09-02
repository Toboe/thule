#for i in `find . -type d -maxdepth 1 | grep ^\./ | sed 's/\.\///g' | grep -v '^\.' | grep ' '`
find . -type d -maxdepth 1 | grep ^\./ | sed 's/\.\///g' | grep -v '^\.' | grep ' ' | while read LINE
do
#echo echo "$LINE"| awk '{ gsub(" ","\\ "); print }'
#echo "$LINE" | sed 's/\ /\\ /g' 
#echo "$LINE" | sed 's/\ /\\ /g'
#old= `echo "$LINE" | sed 's/\ /\\ /g'`
#new=`echo "$i" | sed 's/|/_/g'`

#echo `echo "./$LINE/"| awk '{ gsub(" ","\\\ "); print }'`" "`echo "./$LINE/"|sed 's/\\ /_/g'` 
#echo ./$LINE" "`echo "$LINE"|sed 's/\\ /_/g'`
#mv -f "$old" "$new"
#mv -f  `echo "./$LINE/"| awk '{ gsub(" ","\\\ "); print }'`" "`echo "./$LINE/"|sed 's/\\ /_/g'`
echo $LINE
#echo $www
#ls "echo "$LINE" | sed 's/\ /\\ /g'"
#echo $old
#ls -l $old
sleep 2
done
