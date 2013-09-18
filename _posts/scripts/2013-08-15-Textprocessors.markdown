#Serches
awk 'NR==2' buildinstructins
find . -iname '*' -print | sed -n -E -e 's/.*mp3/&/p' -e 's/.*wav/&/p' -e 's/.*wma/&/p' > appo.m3u
find . -iregex '.*\.\(mp3\|wav\|wma\)' -print > app.m3u

#VIM:
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

###########VIM############
:70t.
:tab(gt)
CNTR+P(W) :sp
e ++enc=cp1251
CNTR[BD]v
