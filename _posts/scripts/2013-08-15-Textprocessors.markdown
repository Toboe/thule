#Serches
find /samba/share -mtime +10 | awk '{print "mv -f "$1" /backup"$1""; print "ln -s /backup"$1" "$1""}' | sh
awk 'NR==2' buildinstructins
find . -iname '*' -print | sed -n -E -e 's/.*mp3/&/p' -e 's/.*wav/&/p' -e 's/.*wma/&/p' > appo.m3u
find . -iregex '.*\.\(mp3\|wav\|wma\)' -print > app.m3u
find -size +100M

## Delete all the crap files on desktop before syncing
find /home/username/Music/ -regextype posix-awk -regex "(.*.jpg|.*.ini|.*.rtf|.*.url|.*.txt|.*.log|.*.sfv|.*.nfo|
.*.md5|.*.m3u)" -exec rm -v {} \;

##Print line with DD & next
awk '/^DD/{f=1;print;next}f{print;exit}' myfile.txt
$ awk '
/^DD/{
print
getline
print
}' myfile.txt
$ sed -n '/^DD/{p;n;p;}' myfile.txt
$ grep -A1 "^DD" myfile.txt
##Line newx to Pattern
$ awk '/^DD/{f=1;next}f{print;exit}' myfile.txt
$ awk '
/^DD/{
getline
print
}' myfile.txt
$ sed -n '/^DD/{n;p;}' myfile.txt

##Line previous to Pattern

#wk '/^DD/{print x;print};{x=$0}' myfile.txt
$ grep -B1 "^DD" myfile.txt
###without patter
$ awk '/^DD/{print x};{x=$0}' myfile.txt
$ sed -n '/^DD/{g;1!p;};h' myfile.txt
##Previous and newx of PAttern
$ grep -A1 -B1 "^DD" myfile.txt
$ grep -A1 -B2 "^DD" myfile.txt
awk -v lines=7 '/blah/ {for(i=lines;i;--i)getline; print $0 }' logfile

VIM:
:s/foo/bar/g
 	Change each 'foo' to 'bar' in the current line.
:%s/foo/bar/g 	Change each 'foo' to 'bar' in all lines.
:5,12s/foo/bar/g 	Change each 'foo' to 'bar' for all lines from line 5 to line 12 inclusive.
:'a,'bs/foo/bar/g 	Change each 'foo' to 'bar' for all lines from mark a to mark b inclusive (see Note below).
:'<,'>s/foo/bar/g 	When compiled with +visual, change each 'foo' to 'bar' for all lines within a visual selection. Vim automatically appends the visual selection range ('<,'>) for any ex command when you select an area and enter :. Also, see Note below.
:.,$s/foo/bar/g 
	Change each 'foo' to 'bar' for all lines from the current line (.) to the last line ($) inclusive.
:.,+2s/foo/bar/g 
	Change each 'foo' to 'bar' for the current line (.) and the two next lines (+2).
:g/^baz/s/foo/bar/g 
	Change each 'foo' to 'bar' in each line starting with 'baz'.
                        

When searching:

    ., *, \, [, ], ^, and $ are metacharacters. 
    +, ?, |, {, }, (, and ) must be escaped to use their special function. 
    \/ is / (use backslash + forward slash to search for forward slash) 
    \t is tab, \s is whitespace 
    \n is newline, \r is CR (carriage return = Ctrl-M = ^M) 
    \{#\} is used for repetition. /foo.\{2\} will match foo and the two following characters. The \ is not required on the closing } so /foo.\{2} will do the same thing. 
    \(foo\) makes a backreference to foo. Parenthesis without escapes are literally matched. Here the \ is required for the closing \). 

When replacing:

    \r is newline, \n is a null byte (0x00). 
    \& is ampersand (& is the text that matches the search pattern). 
    \1 inserts the text of the first backreference. \2 inserts the second backreference, and so on. 

Insert newline without entering insert mode
nmap <S-Enter> O<Esc>  
shift
nmap <CR> o<Esc>


 each time you hit Ctrl-W, you delete the word to the left of the cursor
hit Ctrl-U.  Everything to the left of the cursor will be deleted, leaving you with:

I find this useful for just quickly seeing which files contain a search time. I would normally limit the files searched with a command such as :
find . -iname '*php' | xargs grep 'string' -sl

Another common search for me, is to just look at the recently updated files:
find . -iname '*php' -mtime -1 | xargs grep 'string' -sl

would find only files edited today, whilst the following finds the files older than today:
find . -iname '*php' -mtime +1 | xargs grep 'string' -sl

##*#########VIM############
:70t.
:tab(gt)
CNTR+P(W) :sp
e ++enc=cp1251
CNTR[BD]v
dt[symbol] or d/[pattern]
deleted using d/D/x/X/c/C/s/S commands.



    "kyy

Or you can append to a register by using a capital letter

    "Kyy

You can then move through the document and paste it elsewhere using

    "kp

To access all currently defined registers type

    :reg


$ :set ci

After the option is set, you can use / to search strings(case insensitive)


Title: Include a remote file (in vim)
$ :r scp://yourhost//your/file
Like vim scp://yourhost//your/file but in vim cmds.


Title: [vim] Clear a file in three characters (plus enter)
$ :%d
% selects every line in the file. 'd' deletes what's selected. It's a pretty 
simple combination.                                                          #GREP
                                                                             grep 'pattern1\|pattern2' filename
Title: [vim] Clear trailing whitespace in file                               grep -E 'pattern1|pattern2' filename
$ :%s/\s\+$//                                                                grep -e pattern1 -e pattern2 filename
% acts on every line in the file.
\s matches spaces.                                                           grep -E 'pattern1.*pattern2' filename
\+ matches one or more occurrences of what's right behind it.                grep -E 'pattern1.*pattern2|pattern2.*pattern1' filename
                                                                             grep -E 'Manager.*Sales|Sales.*Manager' empl*
Character '$' matches end-of-line.
Title: vi show line numbers                                                  grep -v 'pattern1' filename
$ :set number
Prints line numbers making it easier to see long lines that wrap in your 
terminal and extra line breaks at the end of a file.
works too.


#########A

Title: apache statistics

$ grep "10/Sep/2013" access.log| cut -d[ -f2 | cut -d] -f1 | awk -F: '{print 
$2":"$3}' | sort -nk1 -nk2 | uniq -c | awk '{ if ($1 > 10) print $0}'
=======

#AWK
awk ' {print $1,$3} '
Печатает только первый и третий столбцы, используя stdin
awk ' {print $0} '
Печатает все столбцы, используя stdin
awk ' /'pattern'/ {print $2} '
Печатает только элементы второго столбца, соответствующие шаблону
"pattern", используя stdin
awk -f script.awk inputfile
Как и sed, awk использует ключ -f для получения инструкций из файла, что
полезно, когда их большое количество и вводить их вручную в терминале
непрактично.
awk ' program ' inputfile
Исполняет program, используя данные из inputfile
awk "BEGIN { print \"Hello, world!!\" }"
Классическое "Hello, world" на awk
awk '{ print }'
Печатает все, что вводится из командной строки, пока не встретится EOF
! /bin/awk -f
BEGIN { print "Hello, world!" }
Скрипт awk для классического "Hello, world!" (сделайте его исполняемым с
помощью chmod и запустите)
 This is a program that prints \
"Hello, world!"
 and exits
Комментарии в скриптах awk
awk -F "" 'program' files
Определяет разделитель полей как null, в отличие от пробела по умолчанию
awk -F "regex" 'program' files
Разделитель полей также может быть регулярным выражением
awk '{ if (length($0) > max) max = \
length($0) }
END { print max }' inputfile
Печатает длину самой длинной строки
awk 'length($0) > 80' inputfile
Печатает все строки длиннее 80 символов
awk 'NF > 0' data
Печатает каждую строку, содержащую хотя бы одно поле (NF означает Number
of Fields)
awk 'BEGIN { for (i = 1; i <= 7; i++)
print int(101 * rand()) }'
Печатает семь случайных чисел в диапазоне от 0 до 100
ls -l . | awk '{ x += $5 } ; END \
{ print "total bytes: " x }'
total bytes: 7449362
Печатает общее количество байтов, используемое файлами в текущей
директории
ls -l . | awk '{ x += $5 } ; END \
{ print "total kilobytes: " (x + \
1023)/1024 }'
total kilobytes: 7275.85
Печатает общее количество килобайтов, используемое файлами в текущей
директории
awk -F: '{ print $1 }' /etc/passwd | sort
Печатает отсортированный список имен пользователей
awk 'END { print NR }' inputfile
Печатает количество строк в файле, NR означает Number of Rows
awk 'NR % 2 == 0' data
Печатает четные строки файла.
ls -l | awk '$6 == "Nov" { sum += $5 }
END { print sum }'
Печатает общее количество байтов файла, который последний раз
редактировался в ноябре.
awk '$1 ~/J/' inputfile
Регулярное выражение для всех записей в первом поле, которые начинаются
с большой буквы j.
awk '$1 ~!/J/' inputfile
Регулярное выражение для всех записей в первом поле, которые не
начинаются с большой буквы j.
awk 'BEGIN { print "He said \"hi!\" \to her." }'
Экранирование двойных кавычек в awk.
echo aaaabcd | awk '{ sub(/a+/, \ ""); print }'
Печатает "bcd"
awk '{ $2 = $2 - 10; print $0 }' inventory
Модифицирует inventory и печатает его с той разницей, что значение
второго поля будет уменьшено на 10.
awk '{ $6 = ($5 + $4 + $3 + $2); print \ $6' inventory
Даже если поле шесть не существует в inventory, вы можете создать его и
присвоить значение, затем вывести его.
echo a b c d | awk '{ OFS = ":"; $2 = ""
> print $0; print NF }'
OFS - это Output Field Separator (разделитель выходных полей) и команда
выведет "a::c:d" и "4", так как хотя второе поле аннулировано, оно все
еще существует, поэтому может быть подсчитано.
echo a b c d | awk '{ OFS = ":"; \
$2 = ""; $6 = "new"
> print $0; print NF }'
Еще один пример создания поля; как вы можете видеть, поле между $4
(существующее) и $6 (создаваемое) также будет создано (как пустое $5),
поэтому вывод будет выглядеть как "a::c:d::new" "6".
echo a b c d e f | awk '\
{ print "NF =", NF;
> NF = 3; print $0 }'
Отбрасывание трех полей (последних) путем изменения количества полей.
FS=[ ]
Это регулярное выражения для установки пробела в качестве разделителя
полей.
echo ' a b c d ' |  awk 'BEGIN { FS = \
"[ \t\n]+" }
> { print $2 }'
Печатает только "a".
awk -n '/RE/{p;q;}' file.txt
Печатает только первое совпадение с регулярным выражением.
awk -F\\\\ '...' inputfiles ...
Устанавливает в качестве разделителя полей \\
BEGIN { RS = "" ; FS = "\n" }
{
print "Name is:", $1
print "Address is:", $2
print "City and State are:", $3
print ""
}
Если у нас есть запись вида
"John Doe
1234 Unknown Ave.
Doeville, MA",
этот скрипт устанавливает в качестве разделителя полей новую строку, так
что он легко может работать со строками.
awk 'BEGIN { OFS = ";"; ORS = "\n\n" }
> { print $1, $2 }' inputfile
Если файл содержит два поля, записи будут напечатаны в виде:

"field1:field2 
field3;field4

...;..."
так как разделитель выходных полей - две новые строки, а разделитель
полей - ";".
awk 'BEGIN {
> OFMT = "%.0f" # print numbers as \
integers (rounds)
> print 17.23, 17.54 }'
Будет напечатано 17 и 18 , так как в качестве выходного формата (Output
ForMaT) указано округление чисел с плавающей точкой до ближайших целых
значений.
awk 'BEGIN {
> msg = "Dont Panic!"
> printf "%s\n", msg
>} '
Вы можете использовать printf практически так же, как и в C.
awk '{ printf "%-10s %s\n", $1, \
$2 }' inputfile
Печатает первое поле в виде строки длиной 10 символов, выровненной по
левому краю, а затем второе поле в обычном виде.
awk '{ print $2 > "phone-list" }' \inputfile
Простой пример извлечения данных, где второе поле записывается под
именем "phone-list".
awk '{ print $1 > "names.unsorted"
       command = "sort -r > names.sorted"
       print $1 | command }' inputfile
Записывает имена, содержащиеся в $1, в файл, затем сортируем и выводим
результат в другой файл.
awk 'BEGIN { printf "%d, %d, %d\n", 011, 11, \
0x11 }'
Will print 9, 11, 17
if (/foo/ || /bar/)
   print "Found!"
Простой поиск для foo или bar.
awk '{ sum = $2 + $3 + $4 ; avg = sum / 3
> print $1, avg }' grades
Простые арифметические операции (в большинстве похожи на C)
awk '{ print "The square root of", \
$1, "is", sqrt($1) }'
2
The square root of 2 is 1.41421
7
The square root of 7 is 2.64575
Простой расширяемый калькулятор
awk '$1 == "start", $1 == "stop"' inputfile
Печатает каждую запись между start и stop.
awk '
> BEGIN { print "Analysis of \"foo\"" }
> /foo/ { ++n }
> END { print "\"foo\" appears", n,\
 "times." }' inputfile
Правила BEGIN и END исполняются только один раз, до и после каждой
обработки записи.
echo -n "Enter search pattern: "
read pattern
awk "/$pattern/ "'{ nmatches++ }
END { print nmatches, "found" }' inputfile
Search using shell
if (x % 2 == 0)
print "x is even"
else
print "x is odd"
Простое условие. awk, как и C, также поддерживает операторы ?:.
awk '{ i = 1
  while (i <= 3) {
    print $i
    i++
  }
}' inputfile
Печатает первые три поля каждой записи, по одной в строке.
awk '{ for (i = 1; i <= 3; i++)
  print $i
}'
Печатает первые три поля каждой записи, по одной в строке.
BEGIN {
if (("date" | getline date_now) <= 0) {
  print "Can't get system date" > \
"/dev/stderr"
  exit 1
}
print "current date is", date_now
close("date")
}
Выход с кодом ошибки, отличным от 0, означает, что что-то идет не так.
Пример:
awk 'BEGIN {
> for (i = 0; i < ARGC; i++)
> print ARGV[i]
> }' file1 file2
Печатает awk file1 file2
for (i in frequencies)
delete frequencies[i]
Удаляет элементы в массиве
foo[4] = ""
if (4 in foo)
print "This is printed, even though foo[4] \
is empty"
Проверяют элементы массива
function ctime(ts, format)
{
  format = "%a %b %d %H:%M:%S %Z %Y"
  if (ts == 0)
  ts = systime()
  # use current time as default
  return strftime(format, ts)
}
awk-вариант функции ctime() в C. Так вы можете определять свои
собственные функции в awk.
BEGIN { _cliff_seed = 0.1 }
function cliff_rand()
{
  _cliff_seed = (100 * log(_cliff_seed)) % 1
  if (_cliff_seed < 0)
    _cliff_seed = - _cliff_seed
  return _cliff_seed
}
Генератор случайных чисел Cliff.
cat apache-anon-noadmin.log | \
awk 'function ri(n) \
{  return int(n*rand()); }  \
BEGIN { srand(); }  { if (! \
($1 in randip)) {  \
randip[$1] = sprintf("%d.%d.%d.%d", \
ri(255), ri(255)\
, ri(255), ri(255)); } \
$1 = randip[$1]; print $0  }'
Анонимный лог Apache (IP случайные)
