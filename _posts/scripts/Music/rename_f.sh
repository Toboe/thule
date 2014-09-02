find . -type d -d 1 -name "* *"| grep -v "^./Podcasts*" | nl -ba | sort -nr | cut -f2 > /tmp/fldr.txt
while read  iline
do
#echo $iline
#if ["$iline" = "Podcasts"]; then 
#echo "!!!!!!!!!!!!!!!"
#fi
predicate=`echo $iline| awk -F "/" '{  print $NF }' | tr " " "_"`
#echo $predicate
sleep 3
echo \"$iline\" \"`dirname "$iline"`/$predicate\"
#/bin/mv  \"$iline\" \"`dirname "$iline"`/$predicate\"
done < /tmp/fldr.txt

