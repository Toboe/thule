From physical disk /dev/sda, partition 1, to physical disk /dev/sdb, partition 1.
dd if=/dev/sda1 of=/dev/sdb1 bs=4096 conv=notrunc,noerror
From physical disk /dev/sda to physical disk /dev/sdb
dd if=/dev/sda of=/dev/sdb bs=4096 conv=notrunc,noerror

#Distributives
Samurai Web Testing Framework
DEFT Linux
Network Security Toolkit

#Just a wild guess, have you try installing pommed ?
http://www.erlang.org/
http://www.rust-lang.org/


Unix pv Command: Monitor Progress of Data Sent Via a Pipe
gxkb - X11 keyboard switcher
pacman
Siotop sysstat 
xcompmgr
#Xmessage:
hping
Irssi - IRC client
netcat (openbsd) - TCP/IP swiss army knife
http-//gotux.net/arch-linux/vnstat-network-monitor/

dstat - Versatile resource statistics tool
multitail - Tail command on steroids
ngrep - Network grep
iotop - I/O of processes
iftop
acpi -Battery status
dtrx - Archive simple Extract
galapix - ZUI zoomable user interface Image Viewer
siege - An HTTP/HTTPS stress load tester
lftp: A better command-line ftp/http/sftp client
tmux tmuxinator
loliclip
Vi move (vimv) 
undistract-me - long command notifications alarm (Dependences)
yaourt -Syua

gifsircle gifview -a
gerix tool for cracking WPA2 key
setxkbmap  -option grp:caps_toggle,grp_led:scroll "us,ru"

Scrivener for Mac
BitMessage 
janus-bootstrap

~/Public/m3u.html  | grep '/audios/' | sed -e s/\"/\ /g -e s/\,/\ /g | awk '{print $7}'
cat $1 | grep '</a> </span><span class="user" onclick="cur.cancelClick = true;"></span></div>' | sed -e s/\>/\ /g -e s/\</\ /g |awk '{print $16 $17 }'

#IRssi
- #securitytube on 
- #archlinux
- - #http://chat.freenode.net

/network add -autosendcmd "/^msg bot hi" freenode
/server add -network freenode irc.freenode.net
/connect freenode
/SET autocreate_windows ON
To connect to a server, type this for example:
/connect irc.freenode.net
/join #yourfavoritechannel
esc-cursor or alt-cursor => switch window
alt-q => window 11
alt-w => window 12
/window 30 => window 30
  /BIND meta-z change_window 16
  /BIND -delete meta-y

Add network and server:

/network add -nick mikap -realname "Michael Prokop" freenode
/server add -auto -network freenode chat.freenode.net
/network add freenode -autosendcmd /FNAUTH   => send self defined alias /FNAUTH
                                                by default to freenode
Join server:
/connect freenode

Close connection to server:
/disconnect freenode

Autojoin channel:
/channel add -auto #grml-workshop freenode

List channels:
/list

Display configuration of irssi:
/set
/set autocreate_own_query => display setting of variable autocreate_own_query

Kick user:
/kick username     => just kick
/kickban username  => kick and username can't join channel again
/ban username      => can't join channel again
/unban username    => unban again
/knockout <time> <nick> <reason> => kickban a user for specific time

Window actions:
/window move left  => move window to left
/window move 1     => move window to position 1
/layout save       => store/remember window settings

Diff stuff:
/who               => display users in channel in status window
/who mika          => display info about user mika
/wii mika          => display info about user mika including idle state (depends on network)
/names             => display users in channel in channel window
/set user_name fo  => set (ident) username to 'fo'
/away -all wenn mich jemand braucht, ich bin auf der toilette => set away-status on all networkﬂ
/me is away        => not welcome in many channels
/mode +q idiot     => don't allow messages from user idiot to channel (freenode special)
/quit              => leave all channels and quit irssi
/WC                => leave channel and close window
/part              => leave channel but don't close window
/mod +i            => only allow invited users (/invite user)
/stats p           => display stats members
/alias FNAUTH  set autocreate_own_query OFF;msg -freenode nickserv identify PASSWORD;wait -freenode 3000;msg -freenode
                   chanserv invite #channel;msg -freenode nickserv set unfiltered on;set autocreate_own_query ON;
                   /quote capab identify-msg
/reload            => reload configuration (~/.irssi/config)
/ /CALC 3 * 3      => write "/CALC 3 * 3" into the channel
/exec -o uptime    => display uptime

Direct Client Connect:
/dcc chat username     => direct chat with username
/msg =username message => send "message" to username without connection to server

NickServ (nick name handling):
/query NickServ         => create new window to talk to NickServ
help                    => get usage information
register <password>     => register your nick
info <user>             => request information about user
set password <newpass>  => set new passwort
set email foo@b.invalid => set mailaddress
set hide email          => don't display mailaddress in "info" information
link mikap_ <pass>      => link nickname mikap_ to mikap (mikap_ has to be registered as well of course)
set master mikap        => set master nickname to mikap

ChanServ (channel handling - depends from IRC net):
/query ChanServ
register #channel <password>    => register channel
set #grml-workshop mlock +ton-m =>
set secureops                   =>
level #channel list             => display level information
level #channel set user 50      => set user to level 50
level #channel set autoop 10    => "cmdop" -> be able to /op
access #channel add user        =>
invite #channel                 => all users in channel are allowed to send "/invite"s
recover username                +
release username                => kill username and release the nickname (also see the ghost command)

Logging:
/set autolog = "yes"
/set autolog_path = "~/Logs/irc/$tag_$0.%Y-%m-%d.log"
/set autolog_level = "MSGS ACTIONS KICKS PUBLIC"

Scripts:
% mkdir ~/.irssi/scripts ; cd ~/.irssi/scripts ; wget http://www.irssi.org/scripts/scripts/scriptassist.pl
/script load scriptassist.pl
/scriptassist install chanact
/script load chanact
[ /statusbar chanact add ]
[ /statusbar window remove chanact ]
/statusbar chanact add chanact -after act

/script unload script.pl

http://ben.reser.org/irssi/format_identify.pl
http://wouter.coekaerts.be/irssi/scripts/format_identify.pl
/script load format_identify
/quote capab identify-msg
=> not identified users are displayed as "user?"


/scriptassist install nicklist
/script load nicklist
/nicklist screen

Keybindings:
/bind meta-y /window last   => toggle between last used windows


#HEROKU

heroku keys:clear
heroku keys:add
So it looks to me like the git is using /Users/bishopz/.ssh keys rather than the keys I generated manually inside the repository folder.

In addition to the answers below, this article seems to be providing a lot of insight: Cannot push to Heroku because key fingerprint

I tried completely removing the .ssh directory. I ran

heroku keys:clear
ssh-add -D #to remove all ssh identities
ssh-keygen -t rsa -C "email@gmail.com" -f  ~/.ssh/id_rsa_heroku
ssh-add ~/.ssh/id_rsa_heroku
heroku keys:add ~/.ssh/id_rsa_heroku.pub
git push heroku master
and now get:

!  Your key with fingerprint 27:5f:64:4e:2e:62:a9:95:d2:02:df:27:85 is not authorized to access lit-tor-7969.
fatal: The remote end hung up unexpectedly
The response to

ssh -vvv git@heroku.com
#MONGO_DB
sudo rm /var/lib/mongodb/mongod.lock
sudo mongod --dbpath /var/lib/mongodb --repair
sudo chown mongodb /var/lib/mongodb/*
sudo service mongodb start


