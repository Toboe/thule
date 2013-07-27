DT=$(date | sed 's/:/\ /g'| awk '{print $1 $2 $3 $4 $5}')
PPT () {
date +%s%N
}
#PT=$(date +%s%N | cut -b1-13)
echo $DT
#find $1 -name '*.[pgj][pni][egf]*' | grep -v .Apple | grep -v tumblr | while read FN; do
find $1 | while read FN; do
 BFN=$(basename "$FN")
 SUF=$(echo $FN | tail -c5 | sed -e 's/.//g')
 NFN=$DT${BFN}
 PT=$(date +%s%N)
 
 FFN=$(date +%s%N).$SUF
#FF=$1/$(date +%s%N).$SUF
#echo $PT
NSUF=$(file -ib "$1/$BFN" | awk '"^image/" {print $1}' | sed -e 's/;//g' | sed -e 's/image\///g')
#| sed -e 's/.//g')
#echo "$1/$BFN"  "$1/$PT.$SUF"

#file -ib $1/$BFN | awk '"^image/" {print $1}' | sed -e 's/;//g' | sed -e 's/image\///g' 

#echo "$1/$BFN - $1/$NFN"
#mv "$1/$BFN" "$1/$NFN"
#mv "$1/$BFN"  "$1/$PT.$SUF"



#echo " $PT"
#echo " $NSUF"

case "$2" in

   "-h" )
     echo 1111111111111111111 
       ;;

        "-d" )
          echo -e "\033[32m $1/\033[1;35m$BFN \033[1;33m |-->  \033[1;34m$PT.\033[1;31m$NSUF"
            ;;
        "-m" )
          echo -e "\033[32m $1/\033[1;35m$BFN \033[1;33m |-->  \033[1;34m$PT.\033[1;31m$NSUF"
          mv "$1/$BFN"  "$1/$PT.$NSUF"
            ;;
        esac
#mv "$1/$BFN" "$1/$NFN"
#mv "$1/$BFN"  "$1/$FFN"
#echo $(gifinfo $1/$BFN 2>/dev/null | grep Comment)
# if [ "$(gifinfo $1/$(date +%s%N).$SUF 2>/dev/null | grep Comment)" ]; then
#  echo "GIF- $SUF"
#else 
#  echo "PIC - $1/$BFN"
#  #echo "GIF"
#fi
#feh "$1/$BFN"
done

case "$2" in 
  "-M")
    mkdir /mnt/ftp/Pictures/DateSave/$DT/
    echo -e "move .../$1 ----> .../$DT/"
    mv $1/* /mnt/ftp/Pictures/DateSave/$DT/
    echo "Was moved $(wc -l /mnt/ftp/Pictures/DateSave/$DT/) "
  ;;
  esac
