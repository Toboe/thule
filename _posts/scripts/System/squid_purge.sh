squid purge

Сквид стоит, настроен, кеш набит
а вот как бы нам от туда вытащить чего?
ведь я уже посмотрел (читать "скачал") прикольный ролик/файл/картинку..
вот для этого (и не только этого) есть замечательная программа purge..
где качать - спросить у The Google, как собирать в инструкции =)
меня больше интересует автоматизация процесса разграбления )
сам скрипт:

#!/bin/bash
PURGE="/root/purge/purge/purge"
SQUIDCF="/etc/squid/squid.conf"
PPARAM="-n -a -s -c"
SIZE="+50k"
TMPDIR="/var/www/localhost/htdocs/purge/"
REZDIR="/var/www/localhost/htdocs/rez/"
FILEEXT="jpeg jpg mp3 exe png rar zip wav flv mp4 swf"

#FILEEXT=`cat /var/log/squid/access.log|awk '{print $7}'|grep -o "\.[a-z]\{1,5\}$"|sort|uniq`

for i in $FILEEXT;
do EXT="-e \.$i$"
$PURGE $PPARAM $SQUIDCF -C $TMPDIR $EXT
done

for i in $FILEEXT;
do EXT="*.$i"
DSTDIR=$REZDIR$i/
if [ ! -e "$DSTDIR" ]; then mkdir $DSTDIR; fi;
find $TMPDIR -iname $EXT -size $SIZE -exec mv {} $DSTDIR \;
done;
exit

перед exit можно (или даже нужно) поставить что нибудь типа rm -rf TMPDIR/* - для очистки совести кеша.
теперь по порядку
в начале (первую строчку по известным причинам я пропущу) идет куча переменных
ибо только они позволяют быстро подстраивать скрипт и при адекватном обзывании делают его более легко читаемым.
PURGE - путь к самой программе (мне было лень делать make install или копировать куда положено, зачем мне сторонний пакет в системе?).
SQUIDCF - дорожка к (и с) конфигу сквида.
PPARAM - параметры пурги для вытаскивания файла из скидовского кеша в человечном виде.
SIZE - размер того, что будем сохранять. служит фильтром, чтоб не тягать сотни тысяч мелких картинок и т.д.
TMPDIR - временная директория, куда Пурга будет складывать свое хозяйство в том виде, в котором ее приучили.
REZDIR - а это директория, куда попадут отсортированые файлы в том виде, который задумал я.
FILEEXT - расширения, которые мы хотим получить. можно писать свое через пробе - скрипт универсален (не зря я мучился).
#FILEEXT=`cat... - страшная строчка, раскоментировать только в случае садомазохизма... (и нелюбви к серверу, оставлено мной как стратегическое оружие)

и вот он, первый цикл обработки..
именно он выгребает все заказанное по расширениям с выгребную яму временную директорию.

а вот и второй цикл, который проверяет наличие директории одноименной с желаемым разширением файла, и в случае отсутствия создает такую (я же говорил про универсальность). затем выгребная яма временная директория сканируется на предмет наличия файлов (небольшое отступленице: коллеги используют вместо -iname связку -name -type f, считаю разумным) с заданным расширением и размером большим (если быть точней >=) указанному и скирдует их в вышеуказанную одноименную расширению директорию.

примечания в тексте, каменты ниже.

собственно на сегодня все.






немного доработал скрипт =)

#!/bin/bash
# made by Cpander 
# ver. 1.3
PURGE="/root/purge/purge/purge"
SQUIDCF="/usr/local/etc/squid/squid.conf "
PPARAM="-n -a -s -c"
SIZE="+50k"
TMPDIR="/var/www/localhost/htdocs/purge/"
REZDIR="/var/www/localhost/htdocs/rez/"
NEWDIR=$REZDIR"new/"
FILEEXT="jpeg jpg mp3 exe png rar zip wav flv mp4 swf"

#FILEEXT=`cat /var/log/squid/access.log|awk '{print $7}'|grep -o "\.[a-z]\{1,5\}$"|sort|uniq`

if [ ! -e $NEWDIR ]; then mkdir $NEWDIR; fi;

for i in $FILEEXT;
do OLDDIR=$REZDIR;
if [ ! -e "$OLDDIR" ]; then mkdir $OLDDIR; fi;
mv $NEWDIR$i/* $OLDDIR$i/
EXP="-e \.$i$"
$PURGE $PPARAM $SQUIDCF -C $TMPDIR $EXP
EXT="*.$i"
DSTDIR=$NEWDIR$i/
if [ ! -e "$DSTDIR" ]; then mkdir $DSTDIR; fi;
find $TMPDIR -iname $EXT -size $SIZE -exec mv {} $DSTDIR \;
done;

rm -rf $TMPDIR/*

exit
