
VIM:
visual + ip
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

nd 	effect
{Visual}"+y 	copy the selected text into the system clipboard
"+y{motion} 	copy the text specified by {motion} into the system clipboard
:[range]yank + 	copy the text specified by [range] into the system clipboard
"+p 	Normal mode put command pastes system clipboard after cursor
:put + 	Ex command puts contents of system clipboard on a new line
<C-r>+ 	From insert mode (or commandline mode)
:set clipboard=unnamed
                        

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



 each time you hit Ctrl-W, you delete the word to the left of the cursor
hit Ctrl-U.  Everything to the left of the cursor will be deleted, leaving you with:

 "kyy
Or you can append to a register by using a capital letter

    "Kyy

You can then move through the document and paste it elsewhere using

    "kp

To access all currently defined registers type

    :reg





                                                                             grep 'pattern1\|pattern2' filename
Title: [vim] Clear trailing whitespace in file                               grep -E 'pattern1|pattern2' filename
$ :%s/\s\+$//                                                                grep -e pattern1 -e pattern2 filename
% acts on every line in the file.
\s matches spaces.                                                           grep -E 'pattern1.*pattern2' filename
\+ matches one or more occurrences of what's right behind it.                grep -E 'pattern1.*pattern2|pattern2.*pattern1' filename
                                                                             grep -E 'Manager.*Sales|Sales.*Manager' empl*


#AWK
awk ' /'pattern'/ {print $2} ' Печатает только элементы второго столбца, соответствующие шаблону
awk -f script.awk inputfile
awk ' program ' inputfile Исполняет program, используя данные из inputfile
awk "BEGIN { print \"Hello, world!!\" }"
awk '{ print }' Печатает все, что вводится из командной строки, пока не встретится EOF
awk -F "" 'program' files Определяет разделитель полей как null, в отличие от пробела по умолчанию
awk -F "regex" 'program' files Разделитель полей также может быть регулярным выражением
awk '{ if (length($0) > max) max = \
length($0) }
END { print max }' inputfile
Печатает длину самой длинной строки
awk 'length($0) > 80' inputfile
Печатает все строки длиннее 80 символов
awk 'NF > 0' data
Печатает каждую строку, содержащую хотя бы одно поле (NF означает Number
of Fields)
awk 'BEGIN { for (i = 1; i <= 7; i++) print int(101 * rand()) }'
Печатает семь случайных чисел в диапазоне от 0 до 100
ls -l . | awk '{ x += $5 } ; END { print "total bytes: " x }'
total bytes: 7449362
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




Title: Prepend a text to a file.
$ sed -i 's/^/ls -l /' output_files.txt







'{if(min==""){min=max=$6}; if($6>max) {max=$6}; if($6< min) {min=$6}; total+=$6; count+=1} END {print 100-total/count, 100-min}'
df -F ufs -o i | sed '1d' | awk '{print $5,(($3-$2)*100)/$3}'

df -F ufs -o i |
        sed '1d' | \
        awk 'BEGIN {ORS=" "}{printf("\"%s\" - %0.1f%%, ",$5,(($3-$2)*100)/$3);}END{print "\n"}' | \
        sed 's/, $//' >> info_$HOST_NAME.txt

$[100-($(cat vmstat.txt | grep -v disk | grep -v swap | awk '{ total += $5; count++ } END { printf "%0.f", total/count/1024 }')/0.1*)]


echo "iostat.txt parse:"

cat iostat.txt | grep -v extended | grep -v device | grep sd | awk '{b[$1]++;a[$1]=a[$1] + $10 ; if(max[$1]==""){max[$1]=$10}; if($10>max[$1]) {max[$1]=$10} } END { for(i in a) print i, a[i]/b[i], max[i] }'

echo "vmstat.txt parse:"

echo $[100-($(cat vmstat.txt | grep -v disk | grep -v swap | awk '{ total += $5; count++ } END { printf "%0.f", total/count/1024 }')*100/$(prtconf 2>/dev/null  | grep Memory | awk '{ print $3 }'))]

