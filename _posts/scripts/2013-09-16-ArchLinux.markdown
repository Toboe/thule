ahoog@wintermute:~$ sudo mount -t hfsplus -o ro,loop,offset=209735680 item001.dc3dd ~/mnt/hfs/
ahoog@wintermute:~$ sudo umount ~/mnt/hfs
sudo apt-get install hfsplus
Then, use the -o force option to force the drive to mount:
sudo mount -o force /dev/sdX /your/mount/point
sudo mount -o remount,force /mount/point
sudo mount -o remount,force /dev/sdx

curl -s horseebooksipsum.com/api/v1/ | say
gzip -d  /home/backup/usr.2009.05.06.img.gz  | ( cd /usr ; restore -rf - )

mkinitcpio -M will print out all autodetected modules
blacklist them in /etc/modprobe.d/modprobe.conf
Running mkinitcpio -v will list all modules pulled in by the various hooks (e.g. filesystem hook, SCSI hook, etc.).
mkinitcpio -M will print out all autodetected modules
oading the b43/b43legacy kernel module
Install the appropriate b43-firmware or b43-firmware-legacy package from the AUR.

pacman -S xf86-video-intel
xorg-server
xorg-apps
xorg-xinit
Xorg :0 -configure That should create an xorg.conf.new file in /root/ that you can copy over to /etc/X11/xorg.conf for more information see man xorg.conf

ifconfig wlan0 up
iwlist wlan0 scan
iwconfig wlan0 essid linksys
dhcpcd wlan0

You can install yaourt from AUR:
curl -O https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
tar zxvf package-query.tar.gz
cd package-query
makepkg -si
cd ..
curl -O https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
tar zxvf yaourt.tar.gz
cd yaourt
makepkg -si
cd ..

Sync database, upgrade packages, search aur and devel (all packages based on dev version) upgrades:
yaourt -Syu --devel --aur
Build package from source:
yaourt -Sb <package>
Check, edit, merge or remove *.pac* files:
yaourt -C
Get a PKGBUILD (support splitted package):
yaourt -G <package>
Build and export package, its sources to a directory:
yaourt -Sb --export <dir> <package>
Backup database:
yaourt -B
Query backup file:
yaourt -Q --backupfile <file>

status() {
echo -n "CPUTemp: $(( $(sensors | awk '/temp1/ {print $2}' | cut -c2-3) + 15 )) | "
echo -n "CPUMHz: $(awk '/MHz/ { printf "%.0f", $4}' /proc/cpuinfo) | "
echo -n "$(df -h | awk '/sda[15]/ {printf "%s: %s | ", $6, $3}')"
echo -n "RAM: $(free -m | awk '/\/cache/ {print $3}') MB | "
echo -n "$(uptime | sed 's/.*://; s/,//g') | "
echo -n "$(date +"%a %b %d %H:%M")"
}

# mplayer tv:// -tv driver=v4l2:width=320:height=240:device=/dev/video0 -fps 30
# mplayer tv:// -vf screenshot

lm_sensors package from the official repositories.
# sensors-detect
/etc/conf.d/lm_sensors
# modprobe it87
# modprobe coretemp
# rc.d start sensors



WMII
export WMII_FONT='xft:Sans-9'
into your wmiirc and it just works. xkblayout-state can be used to put layout indicator into the status line:
status() {
    echo -n label $(xkblayout-state print "%s") '|' $(date +"%a %b %d %H:%M")
}

If you would like to display the current directory in your terminal emulator's titlebar, add this to your .bashrc
WMII_IS_RUNNING=`ps a | grep wmii | awk '/[^"grep"] wmii$/'`
if [ -n "$WMII_IS_RUNNING" ]; then
  PROMPT_COMMAND='dirs | wmiir write /client/sel/label'
fi

LANG=ru_RU.UTF-8 ./wine winecfg


LOCALE="en_US.UTF-8"
HARDWARECLOCK="UTC"
TIMEZONE="Asia/Krasnoyarsk"
KEYMAP="ruwin_alt-UTF-8"
CONSOLEFONT="cyr-sun16"
CONSOLEMAP="cp866_to_uni"
USECOLOR="yes"

LOCALE="ru_RU.KOI8-R"
HARDWARECLOCK="localtime"
TIMEZONE=Europe/Moscow
KEYMAP="ru4"
CONSOLEFONT="Cyr_a8x16"
CONSOLEMAP="koi2alt"
USECOLOR="yes"




mail() {
        unread=`curl -n --silent "https://mail.google.com/mail/feed/atom" | tr -d '\n' | awk -F '<entry>' '{for (i=2; i<=NF; i++) {print $i}}' | sed -n "s/<title>\(.*\)<\/title.*name>\(.*\)<\/name>.*/\2 - \1/p" | wc -l`
 
        if [ $unread -eq 0 ]; then
                echo -n $normcolors mail $unread
        else
                echo -n $focuscolors mail $unread
        fi
 
}
 

cat /dev/ttyS2 | hexdump -C
shred -v filename
renice -20 -g 2874 (2784 found with ps -Aj)
 ps -e -m -o user,pid,args,%mem,rss | grep Chrome | perl -ne 'print n if / (\d+)$/' | ( x=0;while read line; do (( x +=  )); done; echo 0 ); 
say(){ mplayer -user-agent Mozilla "http://translate.google.com/translate_tts?tl=en&q=$(echo $* | sed s# #+#g)" > /dev/null 2>&1 ;  }; say "Zarathustra still lovest by the abbys" 
=======
$ ffmpeg -loop 1 -i image.png -i sound.mp3 -shortest video.mp4
$ curl -u user:pass -d status=?I am Tweeting from the shell? 
http://twitter.com/statuses/update.xml



Best way to go currently is to install (manually compile) the keyfuzz program and put

echo "786616 99" | keyfuzz -s -d /dev/input/by-id/usb-Apple_Inc._Apple_Internal_Keyboard___Trackpad-event-kbd

in your /etc/profile for instance. This maps Alt-Eject on a typical Apple Macbook Pro (mine is mid-2010, 6,2), to the Alt-SysRq combination.

Hardest was discovering 786616, which is 0xc00b8. For the "consumer" part of the USB HID codes one apparently does not add 0x70000 but 0xc0000. I found the code via the little program getscancodes (again, compile yourself).

For F12 it would have been 458821.

Goodluck!
Looks like no one has answered your question yet. If Arch is detecting a screen and displaying anything at all using your Mini Display Port I don't think it is an issue with the Adapter. If you have not tried to edit the Xorg configuration to manually set the display resolution. First take a backup of the config cp /etc/X11/xorg.conf /etc/X11/xorg.conf_backup now edit the config file vi /etc/X11/xorg.conf find the section screen and add the following under your monitor SubSection "Display" Depth 16 Modes "1024x768_75.00" EndSubSection That should set your screen resolution to 1024x768 with a 75Hz Refresh Rate and 16bit color
МинОбороны, есть аналогичный пункт - "В условиях эскалации конфликта в информационном пространстве и перехода его в кризисную фазу воспользоваться правом на индивидуальную или коллективную самооборону с применением любых избранных способов и средств, не противоречащих общепризнанным нормам и принципам международного права".
