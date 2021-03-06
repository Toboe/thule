#!/bin/sh

# Name of this version of winetricks (YYYYMMDD)
WINETRICKS_VERSION=20111115

# This is a utf-8 file
# You should see an o with two dots over it here [ö]
# You should see a micro (u with a tail) here [µ]
# You should see a trademark symbol here [™]

#--------------------------------------------------------------------
#
# Winetricks is a package manager for win32 dlls and applications on posix.
# Features:
# - Consists of a single shell script - no installation required
# - Downloads packages automatically from original trusted sources
# - Points out and works around known wine bugs automatically
# - Both commandline and GUI operation
# - Can install many packages in silent (unattended) mode
# - Multiplatform; written for Linux, but supports MacOSX and Cygwin, too
#
# Uses the following non-Posix system tools:
# - wine is used to execute win32 apps except on cygwin.
# - cabextract, unzip, and 7z are needed by some verbs.
# - wget or curl is needed for downloading.
# - sha1sum or openssl is needed for verifying downloads.
# - zenity is needed by the GUI, though it can limp along somewhat with kdialog.
# - xdg-open (if present) is used to open download pages for the
#   user when downloads cannot be fully automated.
# - sudo is used to mount .iso images if the user cached them with -k option.
# - perl is used to munge steam config files
# On ubuntu, the following lines can be used to install all the prereqs:
#    sudo add-apt-repository ppa:ubuntu-wine/ppa
#    sudo apt-get update
#    sudo apt-get install wine1.3 cabextract unzip p7zip wget zenity
#
# See http://winetricks.org for documentation and tutorials, including
# how to contribute changes to winetricks.
#
#--------------------------------------------------------------------
#
# Copyright
#   Copyright (C) 2007-2011 Dan Kegel <dank!kegel.com>
#   Copyright (C) 2008-2011 Austin English <austinenglish!gmail.com>
#   Copyright (C) 2010-2011 Phil Blankenship <phillip.e.blankenship!gmail.com>
#   Copyright (C) 2010-2011 Shannon VanWagner <shannon.vanwagner!gmail.com>
#   Copyright (C) 2010 Belhorma Bendebiche <amro256!gmail.com>
#   Copyright (C) 2010 Eleazar Galano <eg.galano!gmail.com>
#   Copyright (C) 2010 Travis Athougies <iammisc!gmail.com>
#   Copyright (C) 2010 Andrew Nguyen
#   Copyright (C) 2010 Detlef Riekenberg
#   Copyright (C) 2010 Maarten Lankhorst
#   Copyright (C) 2010 Rico Schüller
#   Copyright (C) 2011 Scott Jackson <sjackson2!gmx.com>
#   Copyright (C) 2011 Trevor Johnson
#   Copyright (C) 2011 Franco Junio
#   Copyright (C) 2011 Craig Sanders
#   Copyright (C) 2011 Matthew Bauer <mjbauer95>
#   Copyright (C) 2011 Giuseppe Dia
#   Copyright (C) 2011 Łukasz Wojniłowicz
#   Copyright (C) 2011 Matthew Bozarth
#
# License
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Lesser General Public
#   License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later
#   version.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Lesser General Public License for more details.
#   You should have received a copy of the GNU Lesser General Public
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#--------------------------------------------------------------------
# Coding standards:
#
# Portability:
# - Portability matters, as this script is run on many operating systems
# - No bash, zsh, or csh extensions; only use features from
#   the Posix standard shell and utilities; see
#   http://pubs.opengroup.org/onlinepubs/009695399/utilities/xcu_chap02.html
# - 'checkbashisms -p -x winetricks' should show no warnings (per Debian policy)
# - Prefer classic sh idioms as described in e.g.
#   "Portable Shell Programming" by Bruce Blinn, ISBN: 0-13-451494-7
# - If there is no universally available program for a needed function,
#   support the two most frequently available programs.
#   e.g. fall back to wget if curl is not available; likewise, support
#   both sha1sum and openssl.
# - When using unix commands like cp, put options before filenames so it will
#   work on systems like MacOSX.  e.g. "rm -f foo.dat", not "rm foo.dat -f"
#
# Formatting:
# - Your terminal and editor must be configured for utf-8
#   If you do not see an o with two dots over it here [ö], stop!
# - Do not use tabs in this file or any verbs.
# - Indent 4 spaces.
# - Try to keep line length below 80 (makes printing easier)
# - Open curly braces ('{') and 'then' at beginning of line,
#   close curlies ('}') and 'fi' should line up with the matching { or if,
#   cases aligned with 'case' and 'esac'.  For instance,
#
#      if test "$FOO" = "bar"
#      then
#         echo "FOO is bar"
#      fi
#      case "$FOO" of
#      bar) echo "FOO is still bar" ;;
#      esac
#
# Commenting:
# - Comments should explain intent in English
# - Keep functions short and well named to reduce need for comments
#
# Naming:
# Public things defined by this script, for use by verbs:
# - Variables have uppercase names starting with W_
# - Functions have lowercase names starting with w_
#
# Private things internal to this script, not for use by verbs:
# - Local variables have lowercase names starting with uppercase _W_
# - Global variables have uppercase names starting with WINETRICKS_
# - Functions have lowercase names starting with winetricks_
# FIXME: A few verbs still use winetricks-private functions or variables.
#
# Internationalization / localization:
# - Important or frequently used message should be internationalized
#   so translations can be easily added.  For example:
#     case $LANG in
#     de*) echo "Das ist die deutsche Meldung" ;;
#     *)   echo "This is the English message" ;;
#     esac
#
#--------------------------------------------------------------------

# FIXME: maybe obey XDG_DATA_HOME
W_PREFIXES_ROOT="${WINE_PREFIXES:-$HOME/.local/share/wineprefixes}"

#---- Public Functions ----

# Ask permission to continue
w_askpermission()
{
    echo "------------------------------------------------------"
    echo "$@"
    echo "------------------------------------------------------"

    if test $W_OPT_UNATTENDED
    then
        _W_timeout="--timeout 5"
    fi

    case $WINETRICKS_GUI in
    zenity) $WINETRICKS_GUI $_W_timeout --question --title=winetricks --text="`echo $@ | sed 's,\\\\,\\\\\\\\,g'`" --no-wrap;;
    kdialog) $WINETRICKS_GUI --title winetricks --warningcontinuecancel "$@" ;;
    none) printf %s "Press Y or N, then Enter: " ; read response ; test "$response" = Y || test "$response" = y;;
    esac

    if test $? -ne 0
    then
        w_die "Operation cancelled, quitting."
        exec false
    fi

    unset _W_timeout
}

# Display info message.  Time out quickly if user doesn't click.
w_info()
{
    echo "------------------------------------------------------"
    echo "$@"
    echo "------------------------------------------------------"

    _W_timeout="--timeout 3"

    case $WINETRICKS_GUI in
    zenity) $WINETRICKS_GUI $_W_timeout --info --title=winetricks --text="`echo $@ | sed 's,\\\\,\\\\\\\\,g'`" --no-wrap;;
    kdialog) $WINETRICKS_GUI --title winetricks --msgbox "$@" ;;
    none) ;;
    esac

    unset _W_timeout
}

# Display warning message to stderr (since it is called inside redirected code)
w_warn()
{
    echo "------------------------------------------------------" >&2
    echo "$@" >&2
    echo "------------------------------------------------------" >&2

    if test $W_OPT_UNATTENDED
    then
        _W_timeout="--timeout 5"
    fi

    case $WINETRICKS_GUI in
    zenity) $WINETRICKS_GUI $_W_timeout --error --title=winetricks --text="`echo $@ | sed 's,\\\\,\\\\\\\\,g'`";;
    kdialog) $WINETRICKS_GUI --title winetricks --error "$@" ;;
    none) ;;
    esac

    unset _W_timeout
}

# Display warning message to stderr (since it is called inside redirected code)
# And give gui user option to cancel (for when used in a loop)
# If user cancels, exit status is 1
w_warn_cancel()
{
    echo "------------------------------------------------------" >&2
    echo "$@" >&2
    echo "------------------------------------------------------" >&2

    if test $W_OPT_UNATTENDED
    then
        _W_timeout="--timeout 5"
    fi

    # Zenity has no cancel button, but will set status to 1 if you click the go-away X
    case $WINETRICKS_GUI in
    zenity) $WINETRICKS_GUI $_W_timeout --error --title=winetricks --text="`echo $@ | sed 's,\\\\,\\\\\\\\,g'`";;
    kdialog) $WINETRICKS_GUI --title winetricks --warningcontinuecancel "$@" ;;
    none) ;;
    esac

    # can't unset, it clears status
}

# Display fatal error message and terminate script
w_die()
{
    w_warn "$@"

    exit 1
}

# Execute with error checking
# Put this in front of any command that might fail
w_try()
{
    # "VAR=foo w_try cmd" fails to put VAR in the environment
    # with some versions of bash if w_try is a shell function?!
    # This is a problem when trying to pass environment variables to e.g. wine.
    # Adding an explicit export here works around it, so add any we use.
    export WINEDLLOVERRIDES
    printf '%s\n' "Executing $*"

    # On Vista, we need to jump through a few hoops to run commands in cygwin.
    # First, .exe's need to have the executable bit set.
    # Second, only cmd can run setup programs (presumably for security).
    # If $1 ends in .exe, we know we're running on real windows, otherwise
    # $1 would be 'wine'.
    case "$1" in
    *.exe)
        chmod +x "$1" || true # don't care if it fails
        cmd /c "$@"
        ;;
    *)
        "$@"
        ;;
    esac
    status=$?
    if test $status -ne 0
    then
        w_die "Note: command '$@' returned status $status.  Aborting."
    fi
}

w_try_regedit()
{
    # on windows, doesn't work without cmd /c
    case "$OS" in
    "Windows_NT") cmdc="cmd /c";;
    *) unset cmdc ;;
    esac

    w_try winetricks_early_wine $cmdc regedit $W_UNATTENDED_SLASH_S "$@"
}

w_try_regsvr()
{
    w_try $WINE regsvr32 $W_UNATTENDED_SLASH_S $@
}

w_try_cabextract()
{
    # Not always installed, but shouldn't be fatal unless it's being used
    if test ! -x "`which cabextract 2>/dev/null`"
    then
        w_die "Cannot find cabextract.  Please install it (e.g. 'sudo apt-get install cabextract' or 'sudo yum install cabextract')."
    fi

    w_try cabextract -q "$@"
}

w_try_unzip()
{
    # Not always installed, but shouldn't be fatal unless it's being used
    if test ! -x "`which unzip 2>/dev/null`"
    then
        w_die "Cannot find unzip.  Please install it (e.g. 'sudo apt-get install unzip' or 'sudo yum install unzip')."
    fi

    w_try unzip -o -q "$@"
}

w_read_key()
{
    if test ! "$W_OPT_UNATTENDED"
    then
        W_KEY=dummy_to_make_autohotkey_happy
        return 0
    fi

    mkdir -p "$W_CACHE/$W_PACKAGE"

    # backwards compatibile location
    # Auth doesn't belong in cache, since restoring it requires user input
    _W_keyfile="$W_CACHE/$W_PACKAGE/key.txt"
    if ! test -f "$_W_keyfile" 
    then
        _W_keyfile="$WINETRICKS_AUTH/$W_PACKAGE/key.txt"
    fi
    if ! test -f "$_W_keyfile"
    then
        # read key from user
        case $LANG in
        da*) _W_keymsg="Angiv venligst registrerings-nøglen for pakken '$_PACKAGE'"
            _W_nokeymsg="Ingen nøgle angivet"
            ;;
        de*) _W_keymsg="Bitte einen Key für Pakete '$W_PACKAGE' eingeben"
            _W_nokeymsg="Keinen Key eingegeben?"
            ;;
        pl*) _W_keymsg="Proszę podać klucz dla programu '$W_PACKAGE'"
            _W_nokeymsg="Nie podano klucza"
            ;;
        *)  _W_keymsg="Please enter the key for app '$W_PACKAGE'"
            _W_nokeymsg="No key given"
            ;;
        esac
        case $WINETRICKS_GUI in
        *zenity) W_KEY=`zenity --entry --text "$_W_keymsg"` ;;
        *kdialog) W_KEY=`kdialog --inputbox "$_W_keymsg"` ;;
        *xmessage) w_die "sorry, can't read key from gui with xmessage" ;;
        none) printf %s "$_W_keymsg": ; read W_KEY ;;
        esac
        if test "$W_KEY" = ""
        then
            w_die "$_W_nokeymsg"
        fi
        echo "$W_KEY" > "$_W_keyfile"
    fi
    W_RAW_KEY=`cat "$_W_keyfile"`
    W_KEY=`echo $W_RAW_KEY | tr -d '[:blank:][=-=]'`
    unset _W_keyfile _W_keymsg _W_nokeymsg
}

# Convert a Windows path to a Unix path quickly.
# $1 is an absolute Windows path starting with c:\ or C:/
# with no funny business, so we can use the simplest possible
# algorithm.
winetricks_wintounix()
{
    _W_winp_="$1"
    # Remove drive letter and colon
    _W_winp="${_W_winp_#??}"
    # Prepend the location of drive c
    printf %s "$WINEPREFIX"/dosdevices/c:
    # Change backslashes to slashes
    echo $_W_winp | sed 's,\\,/,g' 
}

# Convert between Unix path and Windows path
# Usage is lowest common denominator of cygpath/winepath
# so -u to convert to unix, and -w to convert to windows
w_pathconv()
{
    case "$OS" in
     "Windows_NT")
        # for some reason, cygpath turns some spaces into newlines?!
        cygpath "$@" | tr '\012' '\040' | sed 's/ $//'
        ;;
     *)
        case "$@" in
        -u?c:\\*|-u?C:\\*|-u?c:/*|-u?C:/*) winetricks_wintounix "$2" ;;
        *) winetricks_early_wine winepath "$@" ;;
        esac
        ;;
    esac
}

# Expand an environment variable and print it to stdout
w_expand_env()
{
    winetricks_early_wine cmd.exe /c echo "%$1%"
}

# verify an sha1sum
w_verify_sha1sum()
{
    _W_vs_wantsum=$1
    _W_vs_file=$2

    _W_vs_gotsum=`$WINETRICKS_SHA1SUM < $_W_vs_file | sed 's/ .*//'`
    if [ "$_W_vs_gotsum"x != "$_W_vs_wantsum"x ]
    then
        w_die "sha1sum mismatch!  Rename $_W_vs_file and try again."
    fi
    unset _W_vs_wantsum _W_vs_file _W_vs_gotsum
}

# wget outputs progress messages that look like this:
#      0K .......... .......... .......... .......... ..........  0%  823K 40s
# This function replaces each such line with the pair of lines
# 0%
# # Downloading... 823K (40s)
# It uses minimal buffering, so each line is output immediately
# and the user can watch progress as it happens.

winetricks_parse_wget_progress()
{
    # Parse a percentage, a size, and a time into $1, $2 and $3
    # then use them to create the output line.
    perl -p -e \
       '$| = 1; s/^.* +([0-9]+%) +([0-9,.]+[GMKB]) +([0-9hms,.]+).*$/\1\n# Downloading... \2 (\3)/' 
}

# Execute wget, and if in gui mode, also show a graphical progress bar
winetricks_wget_progress()
{
    case $WINETRICKS_GUI in
    zenity) 
        # Usa a subshell so if the user clicks 'Cancel',
        # the --auto-kill kills the subshell, not the current shell
        (
            wget "$@" 2>&1 |
            winetricks_parse_wget_progress | \
            $WINETRICKS_GUI --progress --width 400 --title="$_W_file" --auto-kill --auto-close
        )
        err=$?
        if test $err -gt 128 
        then
            # 129 is 'killed by SIGHUP'
            # Sadly, --auto-kill only applies to parent process,
            # which was the subshell, not all the elements of the pipeline...
            # have to go find and kill the wget.
            # If we ran wget in the background, we could kill it more directly, perhaps...
            if pid=`ps augxw | grep ."$_W_file" | grep -v grep | awk '{print $2}'`
            then
                echo User aborted download, killing wget
                kill $pid
            fi
        fi
        return $err
        ;;
    *) wget "$@" ;;
    esac
}

# Download a file
# Usage: w_download_to packagename url [sha1sum [filename [cookie jar]]]
# Caches downloads in winetrickscache/$packagename
w_download_to()
{
    _W_packagename="$1"
    _W_url="$2"
    _W_sum="$3"
    _W_file="$4"
    _W_cookiejar="$5"

    case $_W_packagename in
    .) w_die "bug: please do not download packages to top of cache" ;;
    esac

    if [ "$_W_file"x = ""x ]
    then
        _W_file=`basename "$_W_url"`
    fi
    _W_cache="$W_CACHE/$_W_packagename"
    w_try mkdir -p "$_W_cache"

    # Try download twice
    checksum_ok=""
    tries=0
    while test $tries -lt 2
    do
        tries=`expr $tries + 1`

        if test -s "$_W_cache/$_W_file" 
        then
            if test "$3"
            then
                if test $tries = 1
                then
                    # The cache was full.  If the file is larger than 500MB,
                    # don't checksum it, that just annoys the user.
                    if test `du -k "$_W_cache/$_W_file" | cut -f1` -gt 500000
                    then
                        checksum_ok=1
                        break
                    fi
                fi
                # If checksum matches, declare success and exit loop
                gotsum=`$WINETRICKS_SHA1SUM < "$_W_cache/$_W_file" | sed 's/(stdin)= //;s/ .*//'`
                if [ "$gotsum"x = "$3"x ]
                then
                    checksum_ok=1
                    break
                fi
                if test ! "$WINETRICKS_CONTINUE_DOWNLOAD"
                then
                    w_warn "Checksum for $_W_cache/$_W_file did not match, retrying download"
                    mv -f "$_W_cache/$_W_file" "$_W_cache/$_W_file".bak
                fi
            else
                # file exists, no checksum known, declare success and exit loop
                break
            fi
        elif test -f "$_W_cache/$_W_file"
        then
            # zero length file, just delete before retrying
            rm "$_W_cache/$_W_file"
        fi

        _W_dl_olddir=`pwd`
        cd "$_W_cache"
        # Mac folks tend to have curl rather than wget
        # On Mac, 'which' doesn't return good exit status
        # Need to jam in --header "Accept-Encoding: gzip,deflate" else
        # redhat.com decompresses liberation-fonts.tar.gz!
        # Note: this causes other sites to compress downloads, hence
        # the kludge further down.  See http://code.google.com/p/winezeug/issues/detail?id=77
        echo Downloading $_W_url to $_W_cache

        # For sites that prefer mozilla in the useragent, set W_BROWSERAGENT=1
        case "$W_BROWSERAGENT" in
        1) _W_agent="Mozilla/5.0 (compatible; Konqueror/2.1.1; X11)" ;;
        *) _W_agent= ;;
        esac

        if [ -x "`which wget 2>/dev/null`" ]
        then
           # Use -nd to insulate ourselves from people who set -x in WGETRC
           # [*] --retry-connrefused works around the broken sf.net mirroring
           # system when downloading corefonts
           # [*] --read-timeout is useful on the adobe server that doesn't
           # close the connection unless you tell it to (control-C or closing
           # the socket)
           winetricks_wget_progress \
               -O "$_W_file" -nd \
               -c --read-timeout=300 --retry-connrefused \
               --header "Accept-Encoding: gzip,deflate" \
               ${_W_cookiejar:+--load-cookies "$_W_cookiejar"} \
               ${_W_agent:+--user-agent="$_W_agent"} \
               "$_W_url"
        elif [ -x "`which curl 2>/dev/null`" ]
        then
           # curl doesn't get filename from the location given by the server!
           # fortunately, we know it
           curl -L -o "$_W_file" -C - \
               --header "Accept-Encoding: gzip,deflate" \
               ${_W_cookiejar:+--cookie "$_W_cookiejar"} \
               ${_W_agent:+--user-agent "$_W_agent"} \
               "$_W_url"
        else
            w_die "Please install wget (or, if that's not available, curl)"
        fi
        if test $? != 0
        then
            test -f "$_W_file" && rm "$_W_file"
            w_die "Downloading $_W_url failed"
        fi
        # Need to decompress .exe's that are compressed, else cygwin fails
        # Also affects ttf files on github
	_W_filetype=`which file 2>/dev/null`
        case $_W_filetype-$_W_file in
        /*-*.exe|/*-*.ttf)
            case `file "$_W_file"` in
            *gzip*) mv "$_W_file" "$_W_file.gz"; gunzip < "$_W_file.gz" > "$_W_file";;
            esac
        esac

        # On cygwin, .exe's must be marked +x
        case "$_W_file" in
        *.exe) chmod +x "$_W_file" ;;
        esac

        cd "$_W_dl_olddir"
        unset _W_dl_olddir
    done

    if test "$3" && test ! "$checksum_ok"
    then 
        w_verify_sha1sum $3  "$_W_cache/$_W_file"
    fi
}

# Open a web browser for the user to the give page
# Usage: w_open_webpage url
w_open_webpage()
{
    # See http://www.dwheeler.com/essays/open-files-urls.html
    for _W_cmd in xdg-open sdtwebclient cygstart open firefox true
    do
        _W_cmdpath=`which $_W_cmd`
        if test -n "$_W_cmdpath"
        then
            break
        fi
    done
    $_W_cmd "$1" &
    unset _W_cmd _W_cmdpath
}

# Download a file
# Usage: w_download url [sha1sum [filename [cookie jar]]]
# Caches downloads in winetrickscache/$W_PACKAGE
w_download()
{
    w_download_to $W_PACKAGE "$@"
}

# Download one or more files via bittorrent
# Usage: w_download_torrent [foo.torrent]
# Caches downloads in $W_CACHE/$W_PACKAGE, torrent files are assumed to be there
# If no foo.torrent is given, will add ALL .torrent files in $W_CACHE/$W_PACKAGE
w_download_torrent()
{
    # FIXME: figure out how to extract the filename from the .torrent file
    # so callers don't need to check if the files are already downloaded.

    w_call utorrent

    UT_WINPATH="$W_CACHE_WIN\\$W_PACKAGE"
    cd "$W_CACHE/$W_PACKAGE"

    if [ "$2"x != ""x ] # foo.torrent parameter supplied
    then
        w_try $WINE utorrent "/DIRECTORY" "$UT_WINPATH" "$UT_WINPATH\\$2" &
    else # grab all torrents
        for torrent in `ls *.torrent`
        do
            w_try $WINE utorrent "/DIRECTORY" "$UT_WINPATH" "$UT_WINPATH\\$torrent" &
        done
    fi

    # Start uTorrent, have it wait until all downloads are finished
    w_ahk_do "
        SetTitleMatchMode, 2
        winwait, Torrent
        Loop
        {
            sleep 6000
            ifwinexist, Torrent, default
            {
                ;should uTorrent be the default torrent app?
                controlclick, Button1, Torrent, default  ; yes
                continue
            }
            ifwinexist, Torrent, already
            {
                ;torrent already registered, fine
                controlclick, Button1, Torrent, default  ; yes
                continue
            }
            ifwinexist, Torrent, Bandwidth
            {
                ;Cancels bandwidth test on first run of uTorrent
                controlclick, Button5, Torrent, Bandwidth
                continue
            }
            ifwinexist, Torrent, version
            {
                ;Decline upgrade to newer version
                controlclick, Button3, Torrent, version
                controlclick, Button2, Torrent, version
                continue
            }
            break
        }
        ;Sets parameter to close uTorrent once all downloads are complete
        winactivate, Torrent 2.0
        send !o
        send a{Down}{Enter}
        winwaitclose, Torrent 2.0
    "
}

w_download_manual_to()
{
    _W_packagename="$1"
    _W_url="$2"
    _W_file="$3"
    _W_sha1sum="$4"

    case "$media" in
    "download")
        w_info "FAIL: bug: media type is download, but w_download_manual was called.  Programmer, please change verb's media type to manual_download."
        ;;
    esac

    case $LANG in
    da*) _W_dlmsg="Hent venligst filen $_W_file fra $_W_url og placér den i $W_CACHE/$_W_packagename, kør derefter dette skript.";;
    de*) _W_dlmsg="Bitte laden Sie $_W_file von $_W_url runter, stellen Sie's in $W_CACHE/$_W_packagename, dann wiederholen Sie diesen Kommando.";;
    pl*) _W_dlmsg="Proszę pobrać plik $_W_file z $_W_url, następnie umieścić go w $W_CACHE/$_W_packagename, a na końcu uruchomić ponownie ten skrytp.";;
    *) _W_dlmsg="Please download $_W_file from $_W_url, place it in $W_CACHE/$_W_packagename, then re-run this script.";;
    esac

    if ! test -f "$W_CACHE/$_W_packagename/$_W_file"
    then
        mkdir -p "$W_CACHE/$_W_packagename"
        case "$OS" in
        "Windows_NT")
            cygstart "$W_CACHE/$_W_packagename" ;;
        *)
            xdg-open "$W_CACHE/$_W_packagename" ;;
        esac
        w_open_webpage "$_W_url"
        sleep 3   # give some time for browser to open
        w_die "$_W_dlmsg"
        # FIXME: wait in loop until file is finished?
    fi
    # FIXME: verify $sha1sum of $file
    unset _W_url _W_file _W_sha1sum _W_dlmsg
}

w_download_manual()
{
    w_download_manual_to $W_PACKAGE "$@"
}

# Turn off news, overlays, and friend interaction in steam
# Run from inside c:\Program Files\Steam
w_steam_safemode()
{
    cat > "$W_TMP/steamconfig.pl" <<"_EOF_"
#!/usr/bin/perl
# Parse steam's localconfig.vcf, add settings to it, and write it out again
# The file is a recursive dictionary
#
# FILE :== CONTAINER
#
# VALUE :== "name" "value" NEWLINE
#
# CONTAINER :== "name" NEWLINE "{" NEWLINE ( VALUE | CONTAINER ) * "}" NEWLINE
#
# We load it into a recursive hash.

use strict;
use warnings;

sub read_into_container{
    my( $pcontainer ) = @_;

    $_ = <FILE> || die "Can't read first line of container";
    /{/ || die "First line of container was not {";
    while (<FILE>) {
       chomp;
       if (/"([^"]*)"\s*"([^"]*)"$/) {
           ${$pcontainer}{$1} = $2;
       } elsif (/"([^"]*)"$/) {
           my( %newcon, $name );
           $name = $1;
           read_into_container(\%newcon);
           ${$pcontainer}{$name} = \%newcon;
        } elsif (/}/) {
           return;
        } else {
           die "huh?";
        }
    }
}

sub dump_container{
    my( $pcontainer, $indent ) = @_;
    foreach (sort(keys(%{$pcontainer}))) {
        my( $val ) = ${$pcontainer}{$_};
        if (ref $val eq 'HASH') {
            print "${indent}\"$_\"\n";
            print "${indent}{\n";
            dump_container($val, "$indent\t");
            print "${indent}}\n";
        } else {
            print "${indent}\"${_}\"\t\t\"$val\"\n";
        }
    }
}

# Disable anything unsafe or annoying
sub disable_notifications{
    my( $pcontainer ) = @_;
    ${$pcontainer}{"friends"}{"PersonaStateDesired"} = "1";
    ${$pcontainer}{"friends"}{"Notifications_ShowIngame"} = "0";
    ${$pcontainer}{"friends"}{"Sounds_PlayIngame"} = "0";
    ${$pcontainer}{"friends"}{"Notifications_ShowOnline"} = "0";
    ${$pcontainer}{"friends"}{"Sounds_PlayOnline"} = "0";
    ${$pcontainer}{"friends"}{"Notifications_ShowMessage"} = "0";
    ${$pcontainer}{"friends"}{"Sounds_PlayMessage"} = "0";
    ${$pcontainer}{"friends"}{"AutoSignIntoFriends"} = "0";
    ${$pcontainer}{"News"}{"NotifyAvailableGames"} = "0";
    ${$pcontainer}{"system"}{"EnableGameOverlay"} = "0";
}

# Read the file
my(%top);
open FILE, $ARGV[0] || die "can't open ".$ARGV[0];
my($line);
$line = <FILE> || die "Could not read first line from ".$ARGV[0];
$line =~ /"UserLocalConfigStore"/ || die "this is not a localconfig.vdf file";
read_into_container(\%top);

# Modify it
disable_notifications(\%top);

# Write modified file
print "\"UserLocalConfigStore\"\n";
print "{\n";
dump_container(\%top, "\t");
print "}\n";
_EOF_

for file in userdata/*/config/localconfig.vdf
do
    cp "$file" "$file.old"
    perl "$W_TMP"/steamconfig.pl "$file.old" > "$file"
done
}

w_question()
{
    case $WINETRICKS_GUI in
    *zenity) $WINETRICKS_GUI --entry --text "$1" ;;
    *kdialog) $WINETRICKS_GUI --inputbox "$1" ;;
    *xmessage) w_die "sorry, can't ask question with xmessage" ;;
    none) echo -n "$1" >&2 ; read W_ANSWER ; echo $W_ANSWER; unset W_ANSWER;;
    esac
}

# Reads steam username and password from environment, cache, or user
# If had to ask user, cache answer.
w_steam_getid()
{
    #TODO: Translate
    _W_steamidmsg="Please enter your Steam login ID (not email)"
    _W_steampasswordmsg="Please enter your Steam password"

    if test ! "$W_STEAM_ID"
    then
        if test -f "$W_CACHE"/steam_userid.txt
        then
            W_STEAM_ID=`cat "$W_CACHE"/steam_userid.txt`
        else
            W_STEAM_ID=`w_question "$_W_steamidmsg"`
            echo "$W_STEAM_ID" > "$W_CACHE"/steam_userid.txt
            chmod 600 "$W_CACHE"/steam_userid.txt
        fi
    fi
    if test ! "$W_STEAM_PASSWORD"
    then
        if test -f "$W_CACHE"/steam_password.txt
        then
            W_STEAM_PASSWORD=`cat "$W_CACHE"/steam_password.txt`
        else
            W_STEAM_PASSWORD=`w_question "$_W_steampasswordmsg"`
            echo "$W_STEAM_PASSWORD" > "$W_CACHE"/steam_password.txt
            chmod 600 "$W_CACHE"/steam_password.txt
        fi
    fi
}

# Usage:
# w_steam_install_game steamidnum windowtitle
w_steam_install_game()
{
    _W_steamid=$1
    _W_steamtitle="$2"

    w_steam_getid

    # Install the steam runtime
    WINETRICKS_OPT_SHAREDPREFIX=1 w_call steam

    # Steam puts up a bunch of windows.  Here's the sequence:
    # "Steam - Updating" - wait for it to close.  May appear twice in a row.
    # "Steam - Login" - wait for it to close (credentials already given on cmdline)
    # "Steam" (small window) - connecting, wait for it to close
    # "Steam" (large window) - the main window
    # "Steam - Updates News" - close it forcefully
    # "Install - $title" - send enter, click a couple checkboxes, send enter again
    # "Updating $title" - small download progress dialog
    # "Steam - Ready" game install done.  (Only comes up if main window not up.)

    cd "$W_PROGRAMS_X86_UNIX/Steam"
    w_ahk_do "
        SetTitleMatchMode 2 
        SetWinDelay 500
        ; Run steam once until it finishes its initial update.  
        ; For me, this exits at 26%.
        run steam.exe -applaunch $_W_steamid -login $W_STEAM_ID $W_STEAM_PASSWORD 
        Loop
        {
            ifWinExist, Steam - Updating
            {
                winwaitclose, Steam
                process close, Steam.exe
                sleep 1000
                ; Run a second time; let it finish updating, then kill it.
                run steam.exe
                winwait Steam - Updating
                winwaitclose
                process close, Steam.exe
                ; Run a third time, have it log in, wait until it has finished connecting
                run steam.exe -applaunch $_W_steamid -login $W_STEAM_ID $W_STEAM_PASSWORD 
            }
            ifWinExist, Steam Login
            {
                break
            }
            sleep 500
        }
        ; wait for login window to close
        winwaitclose

        winwait Steam  ; wait for small <<connecting>> window
        winwaitclose
    "

if [ "$STEAM_DVD" = "TRUE" ]
then
    w_ahk_do "
        ; Run a fourth time, have it install the app.
        run steam.exe -install ${W_ISO_MOUNT_LETTER}:\\
    "
else
    w_ahk_do "
        ; Run a fourth time, have it install the app.
        run steam.exe -applaunch $_W_steamid
    "
fi

    w_ahk_do "
        winwait Install - $_W_steamtitle
        if ( w_opt_unattended > 0 ) {
            send {enter}          ; next (for 1st of 3 pages of install dialog)
            sleep 1000
            click 32, 91          ; uncheck create menu item?
            click 32, 119         ; check create desktop icon?
            send {enter}          ; next (for 2nd of 3 pages of install dialog)
            ; dismiss any news dialogs, and click 'next' on third page of install dialog
            loop
            {
                sleep 1000
                ifwinexist Steam - Updates News
                {
                    winclose
                    continue
                }
                ifwinexist Install - $_W_steamtitle
                {
                    winactivate
                    send {enter}      ; next (for 3rd of 3 pages of install dialog)
                }
                ifwinnotexist Install - $_W_steamtitle
                {
                    sleep 1000
                    ifwinnotexist Install - $_W_steamtitle
                        break
                }
            }
        }
    "

if [ "$STEAM_DVD" = "TRUE" ]
then
    # Wait for install to finish
    while true
    do
        grep "SetHasAllLocalContent(true) called for $_W_steamid" "$W_PROGRAMS_X86_UNIX/Steam/logs/download_log.txt" && break
        sleep 5
    done
fi

    w_ahk_do "
        ; For DVD's: theoretically, it should be installed now, but most games want to download updates. Do that now.
        ; For regular downloads: relaunch to coax steam into showing its nice small download progress dialog
        process close, Steam.exe
        run steam.exe -login $W_STEAM_ID $W_STEAM_PASSWORD -applaunch $_W_steamid
        winwait Ready -
        process close, Steam.exe
    "

    # Not all users need this disabled, but let's play it safe for now
    if w_workaround_wine_bug 22053 "Disabling ingame notifications to prevent game crashes on some machines."
    then
        w_steam_safemode
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Steam" "steam.exe -login $W_STEAM_ID $W_STEAM_PASSWORD -applaunch $_W_steamid"

    myexec="Exec=env WINEPREFIX=\"$HOME/.local/share/wineprefixes/$W_PACKAGE\" wine cmd /c 'C:\\\\\\Run-$W_PACKAGE.bat'"
    mymenu="$HOME/.local/share/applications/wine/Programs/Steam/$_W_steamtitle.desktop"
    if test -f "$mymenu" && w_workaround_wine_bug 26487 "Fixing system menu"
    then
        sed -i "s,Exec=.*,$myexec," "$mymenu"
    else
        w_warn "bug: could not find system menu entry $_W_steamtitle"
    fi

    unset _W_steamid _W_steamtitle
}

#----------------------------------------------------------------

# Generic GOG.com installer
# Usage: game_id game_title [other_files,size [reader_control [run_command [download_id [install_dir [installer_size_and_sha1]]]]]]
# game_id
#     Used for main installer name and download url.
# game_title
#     Used for AutoHotKey and installation path in bat script.
# other_files
#     Extra installer files, in one string, space-separated.
# reader_control
#     If set, the control id of the configuration pannel checkbox controling
#     Adobe Reader installation.
#     Some games don't have it, some games do with different ids.
# run_command
#     Used for bat script, relative to installation path.
# download_id
#     For games which download url doesn't match their game_id
# install_dir
#     If different from game_title
# installer_size_and_sha1
#     exe file SHA1.
winetricks_load_gog()
{
    game_id="$1"
    game_title="$2"
    other_files="$3"
    reader_control="$4"
    run_command="$5"
    download_id="$6"
    install_dir="$7"
    installer_size_and_sha1="$8"

    if [ "$download_id"x = ""x ]
    then
        download_id="$game_id"
    fi
    if [ "$install_dir"x = ""x ]
    then
        install_dir="$game_title"
    fi

    installer_path="$W_CACHE/$W_PACKAGE"
    mkdir -p "$installer_path"
    installer="setup_$game_id.exe"

    if test "$installer_size_and_sha1"x = ""x
    then
        files="$installer $other_files"
    else
        files="$installer,$installer_size_and_sha1 $other_files"
    fi

    file_id=0
    for file_and_size_and_sha1 in $files
    do
        case "$file_and_size_and_sha1" in
        *,*,*)
            sha1sum=`echo $file_and_size_and_sha1 | sed "s/.*,//"`
            minsize=`echo $file_and_size_and_sha1 | sed 's/[^,]*,\([^,]*\),.*/\1/'`
            file=`echo $file_and_size_and_sha1 | sed 's/,.*//'`
            ;;
        *,*) 
            sha1sum=""
            minsize=`echo $file_and_size_and_sha1 | sed 's/.*,//'`
            file=`echo $file_and_size_and_sha1 | sed 's/,.*//'`
            ;;
        *)
            sha1sum=""
            minsize=1
            file=$file_and_size_and_sha1
            ;;
        esac
        file_path="$installer_path/$file"
        if ! test -s "$file_path" || test `stat -Lc%s "$file_path"` -lt $minsize
        then
            # FIXME: bring back automated download
            w_info "You have to be logged in to gog, and you have to own the game, for the following URL to work.  Otherwise it gets a 404."
            w_download_manual "https://www.gog.com/en/download/game/$download_id/$file_id" "$file"
            check_sha1=1
            filesize=`stat -Lc%s "$file_path"`
            if test $minsize -gt 1 && test $filesize -ne $minsize
            then
                check_sha1=""
                w_warn "Expected file size $minsize, please report new size $filesize."
            fi
            if test "$check_sha1" != "" && test "$sha1sum"x != ""x
            then
                w_verify_sha1sum "$sha1sum" "$file_path"
            fi
        fi
        file_id=`expr $file_id + 1`
    done

    cd "$installer_path"
    w_ahk_do "
        run $installer
        WinWait, Setup - $game_title, Start installation
        ControlGet, checkbox_state, Checked,, TCheckBox1 ; EULA
        if (checkbox_state != 1) {
            ControlClick, TCheckBox1
        }
        if (\"$reader_control\") {
            ControlClick, TMCoPShadowButton1 ; Options
            Loop, 10
            {
                ControlGet, visible, Visible,, $reader_control
                if (visible)
                {
                    break
                }
                Sleep, 1000
            }
            ControlGet, checkbox_state, Checked,, $reader_control ; Unckeck Adobe/Foxit Reader
            if (checkbox_state != 0) {
                ControlClick, $reader_control
            }
        }
        ControlClick, TMCoPShadowButton2 ; Start Installation
        WinWait, Setup - $game_title, Exit Installer
        ControlClick, TMCoPShadowButton1 ; Exit Installer
        "

    if test "$run_command"x != ""x
    then
        w_declare_exe "$W_PROGRAMS_X86_WIN\\GOG.com\\$install_dir" "$run_command"
    fi
}

#----------------------------------------------------------------


# Usage: w_mount "volume name" [filename-to-check [discnum]]
# Some games have two volumes with identical volume names.
# For these, please specify discnum 1 for first disc, discnum 2 for 2nd, etc.,
# else caching can't work.
# FIXME: should take mount option 'unhide' for poorly mastered discs
w_mount()
{
    if test "$3"
    then
        WINETRICKS_IMG="$W_CACHE/$W_PACKAGE/$1-$3.iso"
    else
        WINETRICKS_IMG="$W_CACHE/$W_PACKAGE/$1.iso"
    fi
    mkdir -p "$W_CACHE/$W_PACKAGE"

    if test -f "$WINETRICKS_IMG"
    then
        winetricks_mount_cached_iso
    else
        if test "$WINETRICKS_OPT_KEEPISOS" = 0 || test "$2"
        then
            while true
            do
                winetricks_mount_real_volume "$1"
                if test "$2" = "" || test -f "$W_ISO_MOUNT_ROOT/$2"
                then
                    break
                else
                    w_warn "Wrong disc inserted, $2 not found"
                fi
            done
        fi

        case "$WINETRICKS_OPT_KEEPISOS" in
        1)
            winetricks_cache_iso "$1"
            winetricks_mount_cached_iso
            ;;
        esac
    fi
}

w_umount()
{
    if test "$WINE" = ""
    then
        # Windows
        winetricks_load_vcdmount
        cd "$VCD_DIR"
        w_try vcdmount.exe /u
    else
        echo "Running $WINETRICKS_SUDO umount $W_ISO_MOUNT_ROOT"
        case "$WINETRICKS_SUDO" in
        gksudo)
          # -l lazy unmount in case executable still running
          $WINETRICKS_SUDO "umount -l $W_ISO_MOUNT_ROOT"
          w_try $WINETRICKS_SUDO "rm -rf $W_ISO_MOUNT_ROOT"
          ;;
        *)
          $WINETRICKS_SUDO umount -l $W_ISO_MOUNT_ROOT
          w_try $WINETRICKS_SUDO rm -rf $W_ISO_MOUNT_ROOT
          ;;
        esac
        $WINE eject ${W_ISO_MOUNT_LETTER}:
        rm -f "$WINEPREFIX"/dosdevices/${W_ISO_MOUNT_LETTER}:
        rm -f "$WINEPREFIX"/dosdevices/${W_ISO_MOUNT_LETTER}::
    fi
}

w_ahk_do()
{
    if ! test -f "$W_CACHE/ahk/AutoHotkey.exe"
    then
        W_BROWSERAGENT=1 \
        w_download_to ahk http://www.autohotkey.com/download/AutoHotkey104805.zip b3981b13fbc45823131f69d125992d6330212f27 
        w_try_unzip -d "$W_CACHE/ahk"  "$W_CACHE/ahk/AutoHotkey104805.zip" AutoHotkey.exe AU3_Spy.exe
        chmod +x "$W_CACHE/ahk/AutoHotkey.exe"
    fi

    _W_CR=`printf \\\\r`
    cat <<_EOF_ | sed "s/\$/$CR/" > "$W_TMP"/tmp.ahk
w_opt_unattended = ${W_OPT_UNATTENDED:-0}
$@
_EOF_
    w_try $WINE "$W_CACHE_WIN\\ahk\\AutoHotkey.exe" "$W_TMP_WIN"\\tmp.ahk
    unset _W_CR
}

# Function to protect wine-specific sections of code.
# Outputs a message to console explaining what's being skipped.
# Usage:
#   if w_skip_windows name-of-operation
#   then
#      return
#   fi
#   ... do something that doesn't make sense on windows ...

w_skip_windows()
{
    case "$OS" in
    "Windows_NT")
        echo "Skipping operation '$1' on Windows"
        return 0
        ;;
    esac
    return 1
}

w_override_dlls()
{
    w_skip_windows w_override_dlls && return

    _W_mode=$1
    case $_W_mode in
    *=*)
        w_die "w_override_dlls: unknown mode $_W_mode.
Usage: 'w_override_dlls mode[,mode] dll ...'." ;;
    disabled)
        _W_mode="" ;;
    esac
    shift
    echo Using $_W_mode override for following DLLs: $@
    cat > "$W_TMP"/override-dll.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
_EOF_
    while test "$1" != ""
    do
        case "$1" in
        comctl32)
           rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.windows.common-controls_6595b64144ccf1df_6.0.2600.2982_none_deadbeef.manifest
           ;;
        esac

        # Note: if you want to override even DLLs loaded with an absolute path,
        # you need to add an asterisk:
        echo "\"*$1\"=\"$_W_mode\"" >> "$W_TMP"/override-dll.reg
        #echo "\"$1\"=\"$_W_mode\"" >> "$W_TMP"/override-dll.reg

        shift
    done

    w_try_regedit "$W_TMP_WIN"\\override-dll.reg

    unset _W_mode
}

w_override_no_dlls()
{
    w_skip_windows override && return

    $WINE regedit /d 'HKEY_CURRENT_USER\Software\Wine\DllOverrides'
}

w_override_all_dlls()
{
    # Disable all known native Microsoft DLLs in favor of Wine's builtin ones
    w_override_dlls builtin \
        acledit aclui activeds actxprxy advapi32 advpack amstream atl authz avicap32 \
        avifil32 avifilebavrt bcrypt browseui cabinet capi2032 cards cfgmgr32 clusapi \
        comcat comctl32 comdlg32 commdlg compobj compstui credui crtdll crypt32 cryptdlg \
        cryptdll cryptnet cryptui ctapi32 ctl3d ctl3d32 ctl3dv2 \
        d3d10 d3d10core d3d8 d3d9 \
        d3dcompiler_33 d3dcompiler_34 d3dcompiler_35 d3dcompiler_36 \
        d3dcompiler_37 d3dcompiler_38 d3dcompiler_39 d3dcompiler_40 \
        d3dcompiler_41 d3dcompiler_42 d3dcompiler_43 \
        d3dim d3drm \
        d3dx10_33 d3dx10_34 d3dx10_35 d3dx10_36 d3dx10_37 d3dx10_38 \
        d3dx10_39 d3dx10_40 d3dx10_41 d3dx10_42 d3dx10_43 \
        d3dx9_24 d3dx9_25 d3dx9_26 d3dx9_27 d3dx9_28 d3dx9_29 \
        d3dx9_30 d3dx9_31 d3dx9_32 d3dx9_33 d3dx9_34 d3dx9_35 \
        d3dx9_36 d3dx9_37 d3dx9_38 d3dx9_39 d3dx9_40 d3dx9_41 \
        d3dx9_42 d3dx9_43 \
        d3dxof \
        dbghelp dciman32 ddeml ddraw ddrawex \
        devenum dinput dinput8 dispdib dispex dmband dmcompos dmime dmloader dmscript \
        dmstyle dmsynth dmusic dmusic32 dnsapi dplay dplayx dpnaddr dpnet dpnhpast \
        dpnlobby dpwsockx drmclien dsound dssenh dswave dwmapi dxdiagn dxgi faultrep \
        fltlib fusion fwpuclnt gdi32 gdiplus glu32 gpkcsp hal hid hlink \
        hnetcfg httpapi iccvid icmp imagehlp imm imm32 inetcomm inetmib1 infosoft \
        initpki inkobj inseng iphlpapi itircl itss jscript kernel32 loadperf localspl \
        localui lz32 lzexpand mapi32 mapistub mciavi32 mcicda mciqtz32 mciseq mciwave \
        midimap mlang mmdevapi mmsystem mpr mprapi msacm msacm32 mscat32 mscms \
        mscoree msctf msdaps msdmo msftedit mshtml msi msimg32 msimtf msisip \
        msnet32 msrle32 mssign32 mssip32 mstask msvcirt \
        msvcr70 msvcr71 msvcr80 msvcr90 msvcr100 \
        msvcp70 msvcp71 msvcp80 msvcp90 msvcp100 \
        msvcrt msvcrt20 msvcrt40 msvcrtd \
        msvfw32 msvidc32 msvideo mswsock msxml3 \
        msxml4 nddeapi netapi32 newdev ntdll ntdsapi ntprint objsel odbc32 odbccp32 \
        ole2 ole2conv ole2disp ole2nls ole2prox ole2thk ole32 oleacc oleaut32 olecli \
        olecli32 oledb32 oledlg olepro32 olesvr olesvr32 olethk32 openal32 opengl32 pdh \
        pidgen powrprof printui propsys psapi pstorec qcap qedit qmgr qmgrprxy \
        quartz query rasapi16 rasapi32 rasdlg resutils riched20 riched32 rpcrt4 rsabase \
        rsaenh rtutils sccbase schannel secur32 security sensapi serialui setupapi setupx \
        sfc sfc_os shdoclc shdocvw shell shell32 shfolder shlwapi slbcsp slc \
        snmpapi softpub spoolss sti storage stress svrapi sxs t2embed tapi32 \
        toolhelp traffic twain twain_32 typelib unicows updspapi url urlmon user32 \
        userenv usp10 uxtheme vdmdbg ver version w32skrnl w32sys wbemprox wiaservc \
        win32s16 win87em winaspi windebug windowscodecs wined3d winedos winemapi wing wing32 \
        winhttp wininet winmm winnls winnls32 winscard winsock wintab wintab32 wintrust \
        wldap32 wmi wmiutils wnaspi32 wow32 ws2_32 wsock32 wtsapi32 wuapi wuaueng \
        xinput1_1 xinput1_2 xinput1_3 xinput9_1_0 xmllite
}

w_override_app_dlls()
{
    w_skip_windows w_override_app_dlls && return

    _W_app=$1
    shift
    _W_mode=$1
    shift

    # Fixme: handle comma-separated list of modes
    case $_W_mode in
    b*) _W_mode=builtin ;;
    n*) _W_mode=native ;;
    d*)
        _W_mode="" ;;
    *)
        w_die "w_override_app_dlls: unknown mode $_W_mode.  (want native, builtin, or disabled)
Usage: 'w_override_app_dlls app mode dll ...'." ;;
    esac

    echo Using $_W_mode override for following DLLs when running $_W_app: $@
    (
    echo REGEDIT4
    echo ""
    echo "[HKEY_CURRENT_USER\\Software\\Wine\\AppDefaults\\$_W_app\\DllOverrides]"
    ) > "$W_TMP"/override-dll.reg

    while test "$1" != ""
    do
        case "$1" in
        comctl32)
           rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.windows.common-controls_6595b64144ccf1df_6.0.2600.2982_none_deadbeef.manifest
           ;;
        esac
        echo "\"$1\"=\"$_W_mode\"" >> "$W_TMP"/override-dll.reg
        shift
    done

    w_try_regedit "$W_TMP_WIN"\\override-dll.reg
    rm "$W_TMP"/override-dll.reg
    unset _W_app _W_mode
}

# Has to be set in a few places...
w_set_winver()
{
    w_skip_windows w_set_winver && return
    # FIXME: This should really be done with winecfg, but it has no CLI options.

    # First, delete any lingering version info, otherwise it may conflict:
    (
    $WINE reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion" /v SubVersionNumber /f || true
    $WINE reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion" /v VersionNumber /f || true
    $WINE reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion" /v CSDVersion /f || true
    $WINE reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber /f || true
    $WINE reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion" /v CurrentVersion /f || true
    $WINE reg delete "HKLM\System\CurrentControlSet\Control\ProductOptions" /v ProductType /f || true
    $WINE reg delete "HKLM\System\CurrentControlSet\Control\ServiceCurrent" /v OS /f || true
    $WINE reg delete "HKLM\System\CurrentControlSet\Control\Windows" /v CSDVersion /f || true
    $WINE reg delete "HKCU\Software\Wine" /v Version /f || true
    $WINE reg delete "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /f || true
    ) > /dev/null 2>&1

    case $1 in
    win31)
        echo "Setting Windows version to $1"
        cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_USERS\S-1-5-4\Software\Wine]
"Version"="win31"

_EOF_

        w_try_regedit "$W_TMP_WIN"\\set-winver.reg
        return
        ;;
    win95)
        # This key is only used for win 95/98:

        echo "Setting Windows version to $1"
        cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion]
"ProductName"="Microsoft Windows 95"
"SubVersionNumber"=""
"VersionNumber"="4.0.950"

_EOF_
        w_try_regedit "$W_TMP_WIN"\\set-winver.reg
        return
        ;;
    win98)
        # This key is only used for win 95/98:

        echo "Setting Windows version to $1"
        cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion]
"ProductName"="Microsoft Windows 98"
"SubVersionNumber"=" A "
"VersionNumber"="4.10.2222"

_EOF_
        w_try_regedit "$W_TMP_WIN"\\set-winver.reg
        return
        ;;
    nt40)
        # Similar to modern version, but sets two extra keys:

        echo "Setting Windows version to $1"
        cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion]
"CSDVersion"="Service Pack 6a"
"CurrentBuildNumber"="1381"
"CurrentVersion"="4.0"

[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\ProductOptions]
"ProductType"="WinNT"

[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\ServiceCurrent]
"OS"="Windows_NT"

[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Windows]
"CSDVersion"=dword:00000600

_EOF_
        w_try_regedit "$W_TMP_WIN"\\set-winver.reg
        return
        ;;
    win2k)
        csdversion="Service Pack 4"
        currentbuildnumber="2195"
        currentversion="5.0"
        csdversion_hex=dword:00000400
        ;;
    winxp)
        csdversion="Service Pack 3"
        currentbuildnumber="2600"
        currentversion="5.1"
        csdversion_hex=dword:00000300
        ;;
    vista)
        csdversion="Service Pack 2"
        currentbuildnumber="6002"
        currentversion="6.0"
        csdversion_hex=dword:00000200
        ;;
    win7)
        csdversion="Service Pack 1"
        currentbuildnumber="7601"
        currentversion="6.1"
        csdversion_hex=dword:00000100
        $WINE reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f
        ;;
    *)
        die "Invalid Windows version given."
        ;;
    esac

    echo "Setting Windows version to $1"
    cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion]
"CSDVersion"="$csdversion"
"CurrentBuildNumber"="$currentbuildnumber"
"CurrentVersion"="$currentversion"

[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Windows]
"CSDVersion"=$csdversion_hex

_EOF_
    w_try_regedit "$W_TMP_WIN"\\set-winver.reg
}

w_unset_winver()
{
    w_set_winver winxp
}

# Present app $1 with the Windows personality $2
w_set_app_winver()
{
    w_skip_windows w_set_app_winver && return

    _W_app="$1"
    _W_version="$2"
    echo "Setting $_W_app to $_W_version mode"
    (
    echo REGEDIT4
    echo ""
    echo "[HKEY_CURRENT_USER\\Software\\Wine\\AppDefaults\\$_W_app]"
    echo "\"Version\"=\"$_W_version\""
    ) > "$W_TMP"/set-winver.reg

    w_try_regedit "$W_TMP_WIN"\\set-winver.reg
    rm "$W_TMP"/set-winver.reg
    unset _W_app
}

# Usage: w_wine_version OP VALUE
# All the integer comparison operators of 'test' are supported, since 'test' does the work.
# Example:
#  if w_wine_version -gt 1.3.2
#  then
#      ...
#  fi
w_wine_version()
{
    # Parse major/minor/micro/nano fields of VALUE.  Ignore nano.  Abort if major is not 1.
    case $2 in
    0*|1.0|1.0.*) w_die "bug: $2 is before 1.1, we don't bother with bugs fixed that long ago" ;;
    1.1.*) _W_minor=1; _W_micro=`echo $2 | sed 's/.*\.//'`;;
    1.2) _W_minor=2; _W_micro=0;;
    1.2.*) _W_minor=2; _W_micro=`echo $2 | sed 's/.*\.//'`;;
    1.3.*) _W_minor=3; _W_micro=`echo $2 | sed 's/.*\.//'`;;
    *) w_die "bug: unrecognized version $2";;
    esac

    # Comparing current wine version 1.$WINETRICKS_WINE_MINOR.$WINETRICKS_WINE_MICRO against 1.$_W_minor.$_W_micro 
    if test $WINETRICKS_WINE_MINOR = $_W_minor
    then
        test $WINETRICKS_WINE_MICRO $1 $_W_micro || return 1
    else
        test $WINETRICKS_WINE_MINOR $1 $_W_minor || return 1
    fi
}

# Built-in self test for w_wine_version
#echo Verify that version 1.3.4 is equal to itself
#WINETRICKS_WINE_MINOR=3 WINETRICKS_WINE_MICRO=4 w_wine_version -eq 1.3.4 || w_die "fail test case wine-1.3.4 = 1.3.4"
#echo Verify that version 1.3.4 is greater than 1.2
#WINETRICKS_WINE_MINOR=3 WINETRICKS_WINE_MICRO=4 w_wine_version -gt 1.2 || w_die "fail test case wine-1.3.4 > wine-1.2"

# Usage: w_wine_version_in range ...
# True if wine version in any of the given ranges
# 'range' can be
#    val1,   (for >= val1)
#    ,val2   (for <= val2)
#    val1,val2 (for >= val1 && <= val2)
w_wine_version_in()
{
   for _W_range
   do
     _W_val1=`echo $_W_range | sed 's/,.*//'`
     _W_val2=`echo $_W_range | sed 's/.*,//'`

     # If in this range, return true
     case $_W_range in
     ,*)                                  w_wine_version   -le "$_W_val2" && unset _W_range _W_val1 _W_val2 && return 0;;
     *,) w_wine_version -ge "$_W_val1"                                    && unset _W_range _W_val1 _W_val2 && return 0;;
     *)  w_wine_version -ge "$_W_val1" && w_wine_version   -le "$_W_val2" && unset _W_range _W_val1 _W_val2 && return 0;;
     esac
   done
   unset _W_range _W_val1 _W_val2
   return 1
}

# Built-in self teest for w_wine_version_in
#w_wine_version_in_test()
#{
#    WINETRICKS_WINE_MINOR=$1 WINETRICKS_WINE_MICRO=$2 w_wine_version_in $3 $4 $5 $6 || w_die "fail test case wine-1.$1.$2 in $3 $4 $5 $6"
#}
#w_wine_version_not_in_test()
#{
#    WINETRICKS_WINE_MINOR=$1 WINETRICKS_WINE_MICRO=$2 w_wine_version_in $3 $4 $5 $6 && w_die "fail test case wine-1.$1.$2 in $3 $4 $5 $6"
#}
#echo Verify that version 1.2.0 is in the range 1.2,
#w_wine_version_in_test 2 0  1.2,
#echo Verify that version 1.3.4 is in the range 1.2,
#w_wine_version_in_test 3 4  1.2,
#echo Verify that version 1.3 is not in the range ,1.2
#w_wine_version_not_in_test 3 0  ,1.2
#echo test passed

# Usage: workaround_wine_bug bugnumber [message] [good-wine-version-range ...]
# Returns true and outputs given msg if the workaround needs to be applied.
# For debugging: if you want to skip a bug's workaround, put the bug number in 
# the environment variable WINETRICKS_BLACKLIST to disable it.
w_workaround_wine_bug()
{
    if test "$WINE" = ""
    then
        echo No need to work around wine bug $1 on windows
        return 1
    fi
    case "$2" in
    [0-9]*) w_die "bug: want message in w_workaround_wine_bug arg 2, got $2" ;;
    "") _W_msg="";;
    *)  _W_msg="-- $2";;
    esac

    if test "$3" && w_wine_version_in $3 $4 $5 $6
    then
        echo Current wine does not have wine bug $1, so not applying workaround
        return 1
    fi

    case $1 in
    "$WINETRICKS_BLACKLIST")
        echo wine bug $1 workaround blacklisted, skipping
        return 1
        ;;
    esac
    case $LANG in
    da*) w_warn "Arbejder uden om wine-fejl ${1} $_W_msg" ;;
    de*) w_warn "Wine-Fehler ${1} wird umgegangen $_W_msg" ;;
    pl*) w_warn "Obchodzenie błędu w wine ${1} $_W_msg" ;;
    *)   w_warn "Working around wine bug ${1} $_W_msg" ;;
    esac
    winetricks_stats_log_command w_workaround_wine_bug-$1
    return 0
}

# Function for verbs to register themselves so they show up in the menu.
# Example:
# w_metadata wog games \
#   title="World of Goo Demo" \
#   pub="2D Boy" \
#   year="2008" \
#   media="download" \
#   file1="WorldOfGooDemo.1.0.exe"

w_metadata()
{
    if test "$installed_exe1" || test "$installed_file1" || test "$publisher" || test "$year"
    then
        w_die "bug: stray metadata tags set: somebody forgot a backslash in a w_metadata somewhere.  Run with sh -x to see where."
    fi
    if winetricks_metadata_exists $1
    then
        w_die "bug: a verb named $1 already exists."
    fi

    _W_md_cmd="$1"
    _W_category=$2
    file="$WINETRICKS_METADATA/$_W_category/$1.vars"
    shift
    shift
    # Echo arguments to file, with double quotes around the values.
    # Used to use perl here, but that was too slow on cygwin.
    for arg
    do
        case "$arg" in
        installed_exe1=/*)
            w_die "bug: w_metadata $_W_md_cmd has a unix path for installed_exe1, should be a windows path";;
        installed_file1=/*)
            w_die "bug: w_metadata $_W_md_cmd has a unix path for installed_file1, should be a windows path";;
        media=download_manual)
            w_die "bug: verb $_W_md_cmd has media=download_manual, should be manual_download" ;;
        esac
        # Use longest match when stripping value,
        # and shortest match when stripping name,
        # so descriptions can have embedded equals signs
        # FIXME: backslashes get interpreted here.  This screws up
        # installed_file1 fairly often.  Fortunately, we can use forward
        # slashes in that variable instead of backslashes.
        echo ${arg%%=*}=\"${arg#*=}\"
    done > "$file"
    echo category='"'$_W_category'"' >> "$file"
    # If the problem described above happens, you'd see errors like this:
    # /tmp/w.dank.4650/metadata/dlls/comctl32.vars: 6: Syntax error: Unterminated quoted string
    # so check for lines that aren't properly quoted.

    # Do sanity check unless running on cygwin, where it's way too slow.
    case "$OS" in
    "Windows_NT")
        ;;
    *)
        if grep '[^"]$' "$file"
        then
            w_die "bug: w_metadata $_W_md_cmd corrupt, might need forward slashes?"
        fi
        ;;
    esac
    unset _W_md_cmd
}

# Function for verbs to register their main executable [or, if name is given,
# other executables]
# Example:
#   w_declare_exe "$W_PROGRAMS_X86_WIN\\WorldOfGooDemo" WorldOfGoo.exe [name]
w_declare_exe()
{
    _W_dir="$1"
    _W_exe="$2"
    if test "$3"
    then
        _W_name="$3"
    else
        _W_name="$W_PACKAGE"
    fi
    cat > "$W_DRIVE_C/run-$_W_name.bat" <<__EOF__
${W_PROGRAMS_DRIVE}:
cd "$_W_dir"
$_W_exe %*
__EOF__
    unset _W_dir _W_exe _W_name
}

# Call a verb, don't let it affect environment
# Hope that subshell passes through exit status
# Usage: w_do_call foo [bar]       (calls load_foo bar)
# Or: w_do_call foo=bar            (also calls load_foo bar)
# Or: w_do_call foo                (calls load_foo)
w_do_call()
{
    (
        case $1 in
        *=*) arg=`echo $1 | sed 's/.*=//'`; cmd=`echo $1 | sed 's/=.*//'`;;
        *) cmd=$1; arg=$2 ;;
        esac

        # Kludge: use Temp instead of temp to avoid \t expansion in w_try
        # but use temp in unix path because that's what wine creates, and having both temp and Temp
        # causes confusion (e.g. makes vc2005trial fail)
        # FIXME: W_TMP is also set in winetricks_set_wineprefix, can we avoid the duplication?
        W_TMP="$W_DRIVE_C/windows/temp/_$1"
        W_TMP_WIN="C:\\windows\\Temp\\_$1"
        test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
        mkdir -p "$W_TMP"

        # Unset all known used metadata values, in case this is a nested call
        unset installed_file1 installed_exe1

        if winetricks_metadata_exists $1
        then
            . "$WINETRICKS_METADATA"/*/$1.vars
        elif winetricks_metadata_exists $cmd
        then
            . "$WINETRICKS_METADATA"/*/$cmd.vars
        elif test $cmd = native || test $cmd = disabled || test $cmd = builtin
        then
            # ugly special case - can't have metadata for these verbs until we allow arbitrary parameters
            w_override_dlls $cmd $arg
            _W_status=$?
            test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
            return $_W_status
        else
            w_die "No such verb $1"
        fi

        # If needed, set the app's wineprefix
        case "$OS" in
        Windows_NT)
            ;;
        *)
            case "$category"-"$WINETRICKS_OPT_SHAREDPREFIX" in
            apps-0|benchmarks-0|games-0)
                winetricks_set_wineprefix "$cmd"
                # If it's a new wineprefix, give it metadata
                if test ! -f "$WINEPREFIX"/wrapper.cfg
                then
                    echo ww_name=\"$title\" > "$WINEPREFIX"/wrapper.cfg
                fi
                ;;
            esac
            ;;
        esac

        test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
        mkdir -p "$W_TMP"

        # Don't install if already installed
        if test "$WINETRICKS_FORCE" != 1 && winetricks_is_installed $1
        then
            echo "$1 already installed, skipping"
            return 0
        fi

        # We'd like to get rid of W_PACKAGE, but for now, just set it as late as possible.
        W_PACKAGE=$1
        winetricks_stats_log_command $*
        w_try load_$cmd $arg

        # User-specific postinstall hook.
        # Source it so the script can call w_download() if needed.
        postfile="$WINETRICKS_POST/$1/$1-postinstall.sh"
        if test -f "$postfile"
        then
            chmod +x "$postfile"
            . "$postfile"
        fi

        # Clean up after this verb
        test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"

        # Verify install
        if test "$installed_exe1" || test "$installed_file1"
        then
            if ! winetricks_is_installed $1
            then
                w_die "$1 install completed, but installed file $_W_file_unix not found"
            fi
        fi
        # Calling subshell must explicitly propagate error code with exit $?
    ) || exit $?
}

# If you want to check exit status yourself, use w_do_call
w_call()
{
    w_try w_do_call $@
}

w_register_font()
{
    file=$1
    shift
    font=$1

    case "$file" in
    *.TTF|*.ttf) font="$font (TrueType)";;
    esac

    # Kludge: use _r to avoid \r expansion in w_try
    cat > "$W_TMP"/_register-font.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts]
"$font"="$file"
_EOF_
    # too verbose
    w_try_regedit "$W_TMP_WIN"\\_register-font.reg
    cp "$W_TMP"/*.reg /tmp/_reg$$.reg

    # Wine also updates the win9x fonts key, so let's do that, too
    cat > "$W_TMP"/_register-font.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Fonts]
"$font"="$file"
_EOF_
    w_try_regedit "$W_TMP_WIN"\\_register-font.reg
    cp "$W_TMP"/*.reg /tmp/_reg$$-2.reg
}

w_register_font_substitution()
{
    _W_alias=$1
    shift
    _W_font=$1
    # Kludge: use _r to avoid \r expansion in w_try
    cat > "$W_TMP"/_register-font-sub.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes]
"$_W_alias"="$_W_font"
_EOF_
    w_try_regedit "$W_TMP_WIN"\\_register-font-sub.reg
    unset _W_alias _W_font
}

w_append_path()
{
    # Prepend $1 to the windows path in the registry.
    # Use printf %s to avoid interpreting backslashes.
    _W_NEW_PATH="`printf %s $1| sed 's,\\\\,\\\\\\\\,g'`"
    _W_WIN_PATH="`w_expand_env PATH | sed 's,\\\\,\\\\\\\\,g'`"

    sed 's/$/\r/' > "$W_TMP"/path.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment]
"PATH"="$_W_NEW_PATH;$_W_WIN_PATH"
_EOF_

    w_try_regedit "$W_TMP_WIN"\\path.reg
    rm -f "$W_TMP"/path.reg
    unset _W_NEW_PATH _W_WIN_PATH
}
 
#---- Private Functions ----

winetricks_print_version() {
    echo "$WINETRICKS_VERSION"
}

# Run a small wine command for internal use
# Handy place to put small workarounds
winetricks_early_wine()
{
    # The sed works around http://bugs.winehq.org/show_bug.cgi?id=25838
    # which unfortunately got released in wine-1.3.12
    # We would like to use DISPLAY= to prevent virtual desktops from
    # popping up, but that causes autohotkey's tray icon to not show up.
    # We used to use WINEDLLOVERRIDES=mshtml= here to suppress the gecko
    # autoinstall, but that yielded wineprefixes that *never* autoinstalled
    # gecko (winezeug bug 223).
    # The tr removes carriage returns so expanded variables don't have crud on the end
    # The grep works around using new wineprefixes with old wine
    WINEDEBUG=-all $WINE "$@" 2>/dev/null | ( sed 's/.*1h.=//' | tr -d '\r' | grep -v "Module not found" || true)
}

winetricks_detect_gui()
{
    if test -x "`which zenity 2>/dev/null`"
    then
        WINETRICKS_GUI=zenity

        WINETRICKS_MENU_HEIGHT=500
        WINETRICKS_MENU_WIDTH=1010
    elif test -x "`which kdialog 2>/dev/null`"
    then
        echo "Zenity not found!  Using kdialog as poor substitute."
        WINETRICKS_GUI=kdialog
    else
        echo "Please install zenity if you want a graphical interface."
        exit 1
    fi
}

# Detect which sudo to use
winetricks_detect_sudo()
{
    WINETRICKS_SUDO=sudo
    if test "$WINETRICKS_GUI" = "none"
    then
        return
    fi
    if test x"$DISPLAY" != x""
    then
        if test -x "`which gksudo 2>/dev/null`"
        then
            WINETRICKS_SUDO=gksudo
        elif test -x "`which kdesudo 2>/dev/null`"
        then
            WINETRICKS_SUDO=kdesudo
        fi
    fi
}

winetricks_get_prefix_var()
{
    (
        . "$W_PREFIXES_ROOT/$p/wrapper.cfg"
        # The cryptic sed is there to turn ' into '\''
        eval echo \$ww_$1 | sed "s/'/'\\\''/"
    )
}

# Display prefix menu, get which wineprefix the user wants to work with
winetricks_prefixmenu()
{
    case $LANG in
    *)   _W_msg_title="Winetricks - choose a wineprefix"
         _W_msg_body='What do you want to do?'
         _W_msg_apps='Install an app'
         _W_msg_games='Install a game'
         _W_msg_benchmarks='Install a benchmark'
         _W_msg_default="Select the default wineprefix"
         _W_msg_unattended0="Disable silent install"
         _W_msg_unattended1="Enable silent install"
         _W_msg_showbroken0="Hide broken apps (e.g. those with DRM problems)"
         _W_msg_showbroken1="Show broken apps (e.g. those with DRM problems)"
         _W_msg_help="View help"
         ;;
    esac
    case "$W_OPT_UNATTENDED" in
    1) _W_cmd_unattended=attended; _W_msg_unattended="$_W_msg_unattended0" ;;
    *) _W_cmd_unattended=unattended; _W_msg_unattended="$_W_msg_unattended1" ;;
    esac
    case "$W_OPT_SHOWBROKEN" in
    1) _W_cmd_showbroken=hidebroken; _W_msg_showbroken="$_W_msg_showbroken0" ;;
    *) _W_cmd_showbroken=showbroken; _W_msg_showbroken="$_W_msg_showbroken1" ;;
    esac

    case $WINETRICKS_GUI in
    zenity)
        printf %s "zenity \
            --title '$_W_msg_title' \
            --text '$_W_msg_body' \
            --list \
            --radiolist \
            --column '' \
            --column '' \
            --column '' \
            --height $WINETRICKS_MENU_HEIGHT \
            --width $WINETRICKS_MENU_WIDTH \
            --hide-column 2 \
            FALSE help       '$_W_msg_help' \
            FALSE apps       '$_W_msg_apps' \
            FALSE benchmarks '$_W_msg_benchmarks' \
            FALSE games      '$_W_msg_games' \
            TRUE  main       '$_W_msg_default' \
            " \
            > "$WINETRICKS_WORKDIR"/zenity.sh

        if ls -d $W_PREFIXES_ROOT/*/dosdevices > /dev/null 2>&1
        then
            for prefix in "$W_PREFIXES_ROOT"/*/dosdevices
            do
                q="${prefix%%/dosdevices}"
                p="${q##*/}"
                if test -f "$W_PREFIXES_ROOT/$p/wrapper.cfg"
                then
                    _W_msg_name="$p (`winetricks_get_prefix_var name`)"
                else
                    _W_msg_name="$p"
                fi
                printf %s " FALSE prefix='$p' 'Select $_W_msg_name' "
            done >> $WINETRICKS_WORKDIR/zenity.sh
        fi
        printf %s " FALSE $_W_cmd_unattended '$_W_msg_unattended'" >> $WINETRICKS_WORKDIR/zenity.sh
        printf %s " FALSE $_W_cmd_showbroken '$_W_msg_showbroken'" >> $WINETRICKS_WORKDIR/zenity.sh

        sh "$WINETRICKS_WORKDIR"/zenity.sh | tr '|' ' '
        ;;

    kdialog)
        (
        printf %s "kdialog \
            --geometry 600x400+100+100 \
            --title '$_W_msg_title' \
            --separate-output \
            --radiolist '$_W_msg_body' \
            help       '$_W_msg_help'       off \
            games      '$_W_msg_games'      off \
            benchmarks '$_W_msg_benchmarks' off \
            apps       '$_W_msg_apps'       off \
            main       '$_W_msg_default'    on "
        if ls -d "$W_PREFIXES_ROOT"/*/dosdevices > /dev/null 2>&1
        then
            for prefix in "$W_PREFIXES_ROOT"/*/dosdevices
            do
                q="${prefix%%/dosdevices}"
                p="${q##*/}"
                if test -f "$W_PREFIXES_ROOT/$p/wrapper.cfg"
                then
                    _W_msg_name="$p (`winetricks_get_prefix_var name`)"
                else
                    _W_msg_name="$p"
                fi
                printf %s "prefix='$p' 'Select $_W_msg_name' off "
            done
        fi
        ) > "$WINETRICKS_WORKDIR"/kdialog.sh
        sh "$WINETRICKS_WORKDIR"/kdialog.sh
        ;;
    esac
    unset _W_msg_help _W_msg_body _W_msg_title _W_msg_new _W_msg_default _W_msg_name
}

# Display main menu, get which submenu the user wants
winetricks_mainmenu()
{
    case $LANG in
    da*) _W_msg_title='Vælg en pakke-kategori'
         _W_msg_body='Hvad ønsker du at gøre?'
         _W_msg_dlls="Install a Windows DLL"
         _W_msg_fonts='Install a font'
         _W_msg_settings='Change Wine settings'
         _W_msg_winecfg='Run winecfg'
         _W_msg_regedit='Run regedit'
         _W_msg_taskmgr='Run taskmgr'
         _W_msg_shell='Run a commandline shell (for debugging)'
         _W_msg_folder='Browse files'
         _W_msg_annihilate="Delete ALL DATA AND APPLICATIONS INSIDE THIS WINEPREFIX" 
         ;;
    de*) _W_msg_title='Pakettyp auswählen'
         _W_msg_body='Was möchten Sie tun?'
         _W_msg_dlls="Windows-DLL installieren"
         _W_msg_fonts='Schriftart installieren'
         _W_msg_settings='Change Wine settings'
         _W_msg_winecfg='Run winecfg'
         _W_msg_regedit='Run regedit'
         _W_msg_taskmgr='Run taskmgr'
         _W_msg_shell='Run a commandline shell (for debugging)'
         _W_msg_folder='Browse files'
         _W_msg_annihilate="Delete ALL DATA AND APPLICATIONS INSIDE THIS WINEPREFIX" 
         ;;
    pl*) _W_msg_title="Winetricks - obecny prefiks to \"$WINEPREFIX\""
         _W_msg_body='What would you like to do to this wineprefix?'
         _W_msg_dlls="Zainstaluj Windowsową bibliotekę DLL lub komponent"
         _W_msg_fonts='Zainstaluj czcionkę'
         _W_msg_settings='Zmień ustawienia'
         _W_msg_winecfg='Uruchom winecfg'
         _W_msg_regedit='Uruchom regedit'
         _W_msg_taskmgr='Uruchom taskmgr'
         _W_msg_shell='Uruchom powłokę wiersza poleceń (dla debugowania)'
         _W_msg_folder='Przeglądaj pliki'
         _W_msg_annihilate="Usuń WSZYSTKIE DANE I APLIKACJE WEWNĄTRZ TEGO WINEPREFIXA" 
         ;;
    *)   _W_msg_title="Winetricks - current prefix is \"$WINEPREFIX\""
         _W_msg_body='What would you like to do to this wineprefix?'
         _W_msg_dlls="Install a Windows DLL or component"
         _W_msg_fonts='Install a font'
         _W_msg_settings='Change settings'
         _W_msg_winecfg='Run winecfg'
         _W_msg_regedit='Run regedit'
         _W_msg_taskmgr='Run taskmgr'
         _W_msg_shell='Run a commandline shell (for debugging)'
         _W_msg_folder='Browse files'
         _W_msg_annihilate="Delete ALL DATA AND APPLICATIONS INSIDE THIS WINEPREFIX" 
         ;;
    esac

    case $WINETRICKS_GUI in
    zenity)
        (
          printf %s "zenity \
            --title '$_W_msg_title' \
            --text '$_W_msg_body' \
            --list \
            --radiolist \
            --column '' \
            --column '' \
            --column '' \
            --height $WINETRICKS_MENU_HEIGHT \
            --width $WINETRICKS_MENU_WIDTH \
            --hide-column 2 \
            FALSE dlls       '$_W_msg_dlls' \
            FALSE fonts      '$_W_msg_fonts' \
            FALSE settings   '$_W_msg_settings' \
            FALSE winecfg    '$_W_msg_winecfg' \
            FALSE regedit    '$_W_msg_regedit' \
            FALSE taskmgr    '$_W_msg_taskmgr' \
            FALSE shell      '$_W_msg_shell' \
            FALSE folder     '$_W_msg_folder' \
            FALSE annihilate '$_W_msg_annihilate' \
         "
         ) > "$WINETRICKS_WORKDIR"/zenity.sh
        sh "$WINETRICKS_WORKDIR"/zenity.sh | tr '|' ' '
        ;;

    kdialog)
        $WINETRICKS_GUI --geometry 600x400+100+100 \
                --title "$_W_msg_title" \
                --separate-output \
                --radiolist \
                "$_W_msg_body"\
                dlls       "$_W_msg_dlls" off \
                fonts      "$_W_msg_fonts" off \
                settings   "$_W_msg_settings" off \
                winecfg    "$_W_msg_winecfg" off \
                regedit    "$_W_msg_regedit" off \
                taskmgr    "$_W_msg_taskmgr" off \
                shell      "$_W_msg_shell" off \
                folder     "$_W_msg_folder" off \
                annihilate "$_W_msg_annihilate" off \
                $_W_cmd_unattended "$_W_msg_unattended" off \

        ;;
    esac
    unset _W_msg_body _W_msg_title _W_msg_apps _W_msg_benchmarks _W_msg_dlls _W_msg_games _W_msg_settings
}

winetricks_settings_menu()
{
    case $LANG in
    *)   _W_msg_title="Winetricks - current prefix is \"$WINEPREFIX\""
         _W_msg_body='Which setting(s) would you like to change?'
         ;;
    esac

    case $WINETRICKS_GUI in
    zenity)
        case $LANG in
        da*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Pakke \
                --column Navn \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        de*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Paket \
                --column Name \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        pl*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Ustawienie \
                --column Nazwa \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        *) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Setting \
                --column Title \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        esac > "$WINETRICKS_WORKDIR"/zenity.sh

        for metadatafile in "$WINETRICKS_METADATA"/$WINETRICKS_CURMENU/*.vars
        do
            code=`winetricks_metadata_basename $metadatafile`
            (
            title='?'
            author='?'
            . $metadatafile
            printf "%s %s %s %s" " " FALSE \
                    $code \
                    "\"$title\""
            )
        done >> $WINETRICKS_WORKDIR/zenity.sh

        sh "$WINETRICKS_WORKDIR"/zenity.sh | tr '|' ' '
        ;;

    kdialog)
        (
        printf %s "kdialog --geometry 600x400+100+100 --title '$_W_msg_title' --separate-output --checklist '$_W_msg_body' "
        winetricks_list_all | sed 's/\([^ ]*\)  *\(.*\)/\1 "\1 - \2" off /' | tr '\012' ' '
        ) > "$WINETRICKS_WORKDIR"/kdialog.sh
        sh "$WINETRICKS_WORKDIR"/kdialog.sh
        ;;
    esac

    unset _W_msg_body _W_msg_title
}

# Display the current menu, output list of verbs to execute to stdout
winetricks_showmenu()
{
    case $LANG in
    da*) _W_msg_title='Vælg en pakke'
         _W_msg_body='Vilken pakke vil du installere?'
         _W_cached="cached"   
         ;;
    de*) _W_msg_title='Pakete auswählen'
         _W_msg_body='Welche Pakete möchten Sie installieren?'
         _W_cached="gecached" 
         ;;
    pl*) _W_msg_title="Winetricks - obecny prefiks to \"$WINEPREFIX\""
         _W_msg_body='Które paczki chesz zainstalować?'
         _W_cached="zarchiwizowane"   
         ;;
    *)   _W_msg_title="Winetricks - current prefix is \"$WINEPREFIX\""
         _W_msg_body='Which package(s) would you like to install?'
         _W_cached="cached"   
         ;;
    esac


    case $WINETRICKS_GUI in
    zenity)
        case $LANG in
        da*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Pakke \
                --column Navn \
                --column Udgiver \
                --column År \
                --column Medie \
                --column Status \
                --column 'Size (MB)' \
                --column 'Time (sec)' \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        de*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Paket \
                --column Name \
                --column Herausgeber \
                --column Jahr \
                --column Media \
                --column Status \
                --column 'Größe (MB)' \
                --column 'Zeit (sec)' \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
             ;;
        pl*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Paczka \
                --column Nazwa \
                --column Wydawca \
                --column Rok \
                --column Media \
                --column Status \
                --column 'Rozmiar (MB)' \
                --column 'Czas (sek)' \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
             ;;
        *) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Package \
                --column Title \
                --column Publisher \
                --column Year \
                --column Media \
                --column Status \
                --column 'Size (MB)' \
                --column 'Time (sec)' \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
             ;;
        esac > "$WINETRICKS_WORKDIR"/zenity.sh

        > $WINETRICKS_WORKDIR/installed.txt
        for metadatafile in "$WINETRICKS_METADATA"/$WINETRICKS_CURMENU/*.vars
        do
            code=`winetricks_metadata_basename $metadatafile`
            (
            title='?'
            author='?'
            . $metadatafile
            if test "$W_OPT_SHOWBROKEN" = 1 || test "$wine_showstoppers" = ""
            then
                # Compute cached and downloadable flags
                flags=""
                winetricks_is_cached $code && flags="$_W_cached"
                installed=FALSE
                if winetricks_is_installed $code
                then
                    installed=TRUE
                    echo $code >> $WINETRICKS_WORKDIR/installed.txt
                fi
                printf %s " $installed \
                    $code \
                    \"$title\" \
                    \"$publisher\" \
                    \"$year\" \
                    \"$media\" \
                    \"$flags\" \
                    \"$size_MB\" \
                    \"$time_sec\" \
                " 
            fi
            )
        done >> $WINETRICKS_WORKDIR/zenity.sh

        # Filter out any verb that's already installed
        sh "$WINETRICKS_WORKDIR"/zenity.sh |
            tr '|' '\012' |
            fgrep -v -x -f "$WINETRICKS_WORKDIR"/installed.txt |
            tr '\012' ' '
        ;;

    kdialog)
        (
        printf %s "kdialog --geometry 600x400+100+100 --title '$_W_msg_title' --separate-output --checklist '$_W_msg_body' "
        winetricks_list_all | sed 's/\([^ ]*\)  *\(.*\)/\1 "\1 - \2" off /' | tr '\012' ' '
        ) > "$WINETRICKS_WORKDIR"/kdialog.sh
        sh "$WINETRICKS_WORKDIR"/kdialog.sh
        ;;
    esac

    unset _W_msg_body _W_msg_title
}

# Converts a metadata abolute path to its app code
winetricks_metadata_basename()
{
    # Classic, but too slow on cygwin
    #basename $1 .vars

    # first, remove suffix .vars
    _W_mb_tmp=${1%.vars}
    # second, remove any directory prefix
    echo ${_W_mb_tmp##*/}
    unset _W_mb_tmp
}

# Returns true if given verb has been registered
winetricks_metadata_exists()
{
    test -f "$WINETRICKS_METADATA"/*/$1.vars
}

# Returns true if given verb has been cached
# You must have already loaded its metadata before calling
winetricks_is_cached()
{
    # FIXME: also check file2... if given
    _W_path="$W_CACHE/$1/$file1"
    case "$_W_path" in
    *..*)
        # Remove /foo/.. so verbs that don't have their own cache directories
        # can refer to siblings
        _W_path="`echo $_W_path | sed 's,/[^/]*/\.\.,,'`"
        ;;
    esac
    if test -f "$_W_path"
    then
        unset _W_path
        return 0
    fi
    unset _W_path
    return 1
}

# Returns true if given verb has been installed
# You must have already loaded its metadata before calling
winetricks_is_installed()
{
    unset _W_file _W_file_unix
    if test "$installed_exe1"
    then
        _W_file="$installed_exe1"
    elif test "$installed_file1"
    then
        _W_file="$installed_file1"
    else
        return 1  # not installed
    fi

    case "$OS" in
    Windows_NT)
        # On Windows, there's no wineprefix, just check if file's there
        _W_file_unix="`w_pathconv -u "$_W_file"`"
        if test -f "$_W_file_unix"
        then
            unset _W_file _W_file_unix _W_prefix
            return 0  # installed
        fi
        ;;
    *)
        # Compute wineprefix for this app
        case "$category"-"$WINETRICKS_OPT_SHAREDPREFIX" in
        apps-0|benchmarks-0|games-0)
            _W_prefix="$W_PREFIXES_ROOT/$1"
            ;;
        *)
            _W_prefix="$WINEPREFIX"
            ;;
        esac
        if test -d "$_W_prefix/dosdevices"
        then
            _W_file_unix="`WINEPREFIX="$_W_prefix" w_pathconv -u "$_W_file"`"
            if test -f "$_W_file_unix" && ! grep -q "Wine placeholder DLL" "$_W_file_unix"
            then
                unset _W_file _W_file_unix _W_prefix
                return 0  # installed
            fi
        fi
        ;;
    esac
    unset _W_file _W_prefix  # leak _W_file_unix for caller.  Is this wise?
    return 1  # not installed
}

# List verbs which are already fully cached locally
winetricks_list_cached()
{
    for _W_metadatafile in "$WINETRICKS_METADATA"/*/*.vars
    do
        # Use a subshell to avoid putting metadata in global space
        # If this is too slow, we can unset known metadata by hand
        (
        code=`winetricks_metadata_basename $_W_metadatafile`
        . $_W_metadatafile
        if winetricks_is_cached $code
        then
            echo $code
        fi
        )
    done | sort
    unset _W_metadatafile
}

# List verbs which are automatically downloadable, regardless of whether they're cached yet
winetricks_list_download()
{
    cd "$WINETRICKS_METADATA"
    grep -l 'media=.download' */*.vars | sed 's,.*/,,;s/\.vars//' | sort -u
}

# List verbs which are downloadable with user intervention, regardless of whether they're cached yet
winetricks_list_manual_download()
{
    cd "$WINETRICKS_METADATA"
    grep -l 'media=.manual_download' */*.vars | sed 's,.*/,,;s/\.vars//' | sort -u
}

winetricks_list_installed()
{
    (
    # Jump through a couple hoops to evaluate the verbs in alphabetical order
    # Assume that no filename contains '|'
    cd "$WINETRICKS_METADATA"
    for _W_metadatafile in `ls */*.vars | sed 's,^\(.*\)/,\1|,' | sort -t\| -k +2 | tr '|' /`
    do
        # Use a subshell to avoid putting metadata in global space
        # If this is too slow, we can unset known metadata by hand
        (
        code=`winetricks_metadata_basename $_W_metadatafile`
        . $_W_metadatafile
        if winetricks_is_installed $code
        then
            echo $code
        fi
        )
    done
    )
    unset _W_metadatafile
}

# Helper for adding a string to a list of flags
winetricks_append_to_flags()
{
    if test "$flags"
    then
        flags="$flags,"
    fi
    flags="${flags}$1"
}

# List all verbs in category WINETRICKS_CURMENU verbosely
# Format is "verb  title  (publisher, year) [flags]"
winetricks_list_all()
{
    # Note: doh123 relies on 'winetricks list' to list main menu categories
    case $WINETRICKS_CURMENU in
    prefix|main) echo "$WINETRICKS_CATEGORIES" | tr ' ' '\012' ; return;;
    esac

    case $LANG in
    da*) _W_cached="cached"   ; _W_download="kan hentes"    ;;
    de*) _W_cached="gecached" ; _W_download="herunterladbar";;
    pl*) _W_cached="zarchiwizowane"   ; _W_download="do pobrania"  ;;
    *)   _W_cached="cached"   ; _W_download="downloadable"  ;;
    esac

    for _W_metadatafile in "$WINETRICKS_METADATA"/$WINETRICKS_CURMENU/*.vars
    do
        # Use a subshell to avoid putting metadata in global space
        # If this is too slow, we can unset known metadata by hand
        (
        code=`winetricks_metadata_basename $_W_metadatafile`
        . $_W_metadatafile

        # Compute cached and downloadable flags
        flags=""
        test "$media" = "download" && winetricks_append_to_flags "$_W_download"
        winetricks_is_cached $code   && winetricks_append_to_flags "$_W_cached"
        test "$flags" && flags="[$flags]"

        if ! test "$year" && ! test "$publisher"
        then
            printf "%-24s %s %s\n" $code "$title" "$flags"
        else
            printf "%-24s %s (%s, %s) %s\n" $code "$title" "$publisher" "$year" "$flags"
        fi
        )
    done
    unset _W_cached _W_metadatafile
}

# Abort if user doesn't own the given directory (or its parent, if it doesn't exist yet)
winetricks_die_if_user_not_dirowner()
{
    if test -d "$1"
    then
        _W_checkdir="$1"
    else
        # fixme: quoting problem?
        _W_checkdir=`dirname "$1"`
    fi
    _W_nuser=`id -u`
    _W_nowner=`ls -l -n -d -L "$_W_checkdir" | awk '{print $3}'`
    if test x$_W_nuser != x$_W_nowner
    then
        w_die "You (`id -un`) don't own $_W_checkdir.  Don't run this tool as another user!"
    fi
}

# See
# http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-119.pdf (iso9660)
# http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
# http://www.osta.org/specs/pdf/udf102.pdf
# http://www.ecma-international.org/publications/techreports/E-TR-071.htm

# Usage: read_bytes offset count device
winetricks_read_bytes()
{
    dd status=noxfer if=$3 bs=1 skip=$1 count=$2 2>/dev/null
}

# Usage: read_hex offset count device
winetricks_read_hex()
{
    od -j $1 -N $2 -t x1 $3          | # offset $1, count $2, single byte hex format, file $3
        sed 's/^[^ ]* //'             | # remove address
        sed '$d'                        # remove final line which is just final offset
}

# Usage: read_decimal offset device
# Reads single four byte word, outputs in decimal.
# Uses default endianness.
# udf uses little endian words, so this only works on little endian machines.
winetricks_read_decimal()
{
    od -j $1 -N 4  -t u4 $2          | # offset $1, byte count 4, four byte decimal format, file $2
        sed 's/^[^ ]* //'             | # remove address
        sed '$d'                        # remove final line which is just final offset
}

winetricks_read_udf_volume_name()
{
    # "Anchor volume descriptor pointer" starts at sector 256

    # AVDP Layout (ECMA-167 3/10.2):
    # size   offset   contents
    # 16     0        descriptor tag (id = 2)
    # 16     8        main (primary?) volume descriptor sequence extent
    # ...

    # descriptor tag layout (ECMA-167 3/7.2):
    # size   offset   contents
    # 2      0        TagIdentifier
    # ...

    # extent layout (ECMA-167 3/7.1):
    # size   offset   contents
    # 4      0        length (in bytes)
    # 8      4        location (in 2k sectors)

    # primary volume descriptor layout (ECMA-167 3/10.1):
    # size   offset   contents
    # 16     0        descriptor tag (id = 1)
    # ...
    # 32     24       volume identifier (dstring)

    # 1. check the 16 bit TagIdentifier of the descriptor tag, make sure it's 2
    tagid=`winetricks_read_hex 524288 2 $1`
    : echo tagid is $tagid
    case "$tagid" in
    "02 00") : echo Found AVDP ;;
    *) echo "Did not find AVDP (tagid was $tagid)"; exit 1;;
    esac

    # 2. read the location of the main volume descriptor:
    offset=`winetricks_read_decimal 524308 $1`
    : echo MVD is at sector $offset
    offset=`expr $offset \* 2048`
    : echo MVD is at byte $offset

    # 3. check the TagIdentifier of the MVD's descriptor tag, make sure it's 1
    tagid=`winetricks_read_hex $offset 2 $1`
    : echo tagid is $tagid
    case "$tagid" in
    "01 00") : echo Found MVD ;;
    *) echo Did not find MVD; exit 1;;
    esac

    # 4. Read whether the name is in 8 or 16 bit chars
    offset=`expr $offset + 24`
    width=`winetricks_read_hex $offset 1 $1`

    offset=`expr $offset + 1`

    # 5. Profit!
    case $width in
    08)   winetricks_read_bytes $offset 30 $1 | sed 's/  *$//' ;;
    10)  winetricks_read_bytes $offset 30 $1 | tr -d '\000' | sed 's/  *$//' ;;
    *) echo "Unhandled dvd volname character width '$width'"; exit 1;;
    esac

    echo ""
}

winetricks_read_iso9660_volume_name()
{
    winetricks_read_bytes 32808 30 $1 | sed 's/  *$//'
}

winetricks_read_volume_name()
{
    # ECMA-119 says that CD-ROMs have sector size 2k, and at sector 16 have:
    # size  offset contents
    #  1    0      Volume descriptor type (1 for primary volume descriptor)
    #  5    1      Standard identifier ("CD001" for iso9660)
    # ECMA-167, section 9.1.2, has a table of standard identifiers:
    # "BEA01": ecma-167 9.2, Beginning Extended Area Descriptor
    # "CD001": ecma-119
    # "CDW02": ecma-168

    std_id=`winetricks_read_bytes 32769 5 $1`
    : echo std_id is $std_id

    case $std_id in
    CD001) winetricks_read_iso9660_volume_name $1 ;;
    BEA01) winetricks_read_udf_volume_name $1; ;;
    *) echo "Unrecognized disk type $std_id"; exit 1 ;;
    esac
}

winetricks_volname()
{
    x=`volname $1 2> /dev/null| sed 's/  *$//'`
    if test "x$x" = "x"
    then
        # UDF?  See https://bugs.launchpad.net/bugs/678419
        x=`winetricks_read_volume_name $1`
    fi
    echo $x
}

# Really, should take a volume name as argument, and use 'mount' to get
# mount point if system automounted it.
winetricks_detect_optical_drive()
{
    case "$WINETRICKS_DEV" in
    "") ;;
    *) return ;;
    esac

    for WINETRICKS_DEV in /dev/cdrom /dev/dvd /dev/sr0
    do
        test -b $WINETRICKS_DEV && break
    done

    case "$WINETRICKS_DEV" in
    "x") w_die "can't find cd/dvd drive" ;;
    esac
}

winetricks_cache_iso()
{
    # WINETRICKS_IMG has already been set by w_mount
    _W_expected_volname="$1"

    winetricks_die_if_user_not_dirowner "$W_CACHE"
    winetricks_detect_optical_drive

    # Horrible hack for Gentoo - make sure we can read from the drive
    if ! test -r $WINETRICKS_DEV
    then
        case "$WINETRICKS_SUDO" in
        gksudo) $WINETRICKS_SUDO "chmod 666 $WINETRICKS_DEV" ;;
        *) $WINETRICKS_SUDO chmod 666 $WINETRICKS_DEV ;;
        esac
    fi

    while true
    do
        # Wait for user to insert disc.
        # Sleep long to make it less likely to close the drive during insertion.
        while ! dd if=$WINETRICKS_DEV of=/dev/null count=1
        do
            sleep 5
        done

        # Some distros automount discs in /media, take advantage of that
        if test -d "/media/_W_expected_volname"
        then
            break
        fi
        # Otherwise try and read it straight from unmounted volume
        _W_volname=`winetricks_volname $WINETRICKS_DEV`
        if test "$_W_expected_volname" != "$_W_volname"
        then
            case $LANG in
            da*)  w_warn "Forkert disk [$_W_volname] indsat. Indsæt venligst disken [$_W_expected_volname]" ;;
            de*)  w_warn "Falsche Disk [$_W_volname] eingelegt.  Bitte legen Sie Disk [$_W_expected_volname] ein!" ;;
        pl*)  w_warn "Włożono zły dysk [$_W_volname].  Proszę włożyć dysk [$_W_expected_volname]" ;;
            *)    w_warn "Wrong disc [$_W_volname] inserted.  Please insert disc [$_W_expected_volname]" ;;
            esac

            sleep 10
        else
            break
        fi
    done

    # Copy disc to .iso file, display progress every 5 seconds
    # Use conv=noerror,sync to replace unreadable blocks with zeroes
    case $WINETRICKS_OPT_DD in
    dd)
      dd if=$WINETRICKS_DEV of="$W_CACHE"/temp.iso bs=2048 conv=noerror,sync &
      WINETRICKS_DD_PID=$!
      ;;
    ddrescue)
      if test "`which ddrescue`" = ""
      then
          w_die "Please install ddrescue first."
      fi
      ddrescue -v -b 2048 $WINETRICKS_DEV "$W_CACHE"/temp.iso &
      WINETRICKS_DD_PID=$!
      ;;
    esac
    echo $WINETRICKS_DD_PID > $WINETRICKS_WORKDIR/dd-pid

    # Note: if user presses ^C, winetricks_cleanup will call winetricks_iso_cleanup
    # FIXME: add progress bar for kde, too
    case $WINETRICKS_GUI in
    none|kdialog)
        while ps -p $WINETRICKS_DD_PID > /dev/null 2>&1
        do
          sleep 5
          ls -l "$W_CACHE"/temp.iso
        done
        ;;
    zenity)
        while ps -p $WINETRICKS_DD_PID > /dev/null 2>&1
        do
          echo 1
          sleep 2
        done | $WINETRICKS_GUI --title "Copying to $_W_expected_volname.iso" --progress --pulsate --auto-kill
        ;;
    esac
    rm $WINETRICKS_WORKDIR/dd-pid

    mv "$W_CACHE"/temp.iso "$WINETRICKS_IMG"

    eject $WINETRICKS_DEV || true    # punt if eject not found (as on cygwin)
}

winetricks_load_vcdmount()
{
    if test "$WINE" != ""
    then
        return
    fi

    # Call only on real Windows.
    # Sets VCD_DIR and W_ISO_MOUNT_ROOT

    # The only free mount tool I know for Windows Vista is Virtual CloneDrive,
    # which can be downloaded at
    # http://www.slysoft.com/en/virtual-clonedrive.html
    # FIXME: actually install it here

    # Locate vcdmount.exe.
    VCD_DIR="Elaborate Bytes/VirtualCloneDrive"
    if test ! -x "$W_PROGRAMS_UNIX/$VCD_DIR/vcdmount.exe" && test ! -x "$W_PROGRAMS_X86_UNIX/$VCD_DIR/vcdmount.exe"
    then
        w_warn "Installing Virtual CloneDrive"
        w_download_to vcd http://static.slysoft.com/SetupVirtualCloneDrive.exe
        # have to use cmd else vista won't let cygwin run .exe's?
        chmod +x "$W_CACHE"/vcd/SetupVirtualCloneDrive.exe
        cd "$W_CACHE/vcd"
        cmd /c SetupVirtualCloneDrive.exe
    fi
    if test -x "$W_PROGRAMS_UNIX/$VCD_DIR/vcdmount.exe"
    then
        VCD_DIR="$W_PROGRAMS_UNIX/$VCD_DIR"
    elif test -x "$W_PROGRAMS_X86_UNIX/$VCD_DIR/vcdmount.exe"
    then
        VCD_DIR="$W_PROGRAMS_X86_UNIX/$VCD_DIR"
    else
        w_die "can't find Virtual CloneDrive?"
    fi
    # FIXME: Use WMI to locate the drive named
    # "ELBY CLONEDRIVE..." using WMI as described in
    # http://delphihaven.wordpress.com/2009/07/05/using-wmi-to-get-a-drive-friendly-name/
}

winetricks_mount_cached_iso()
{
    # On entry, WINETRICKS_IMG is already set
    w_umount

    if test "$WINE" = ""
    then
        winetricks_load_vcdmount
        my_img_win="`w_pathconv -w $WINETRICKS_IMG | tr '\012' ' ' | sed 's/ $//'`"
        cd "$VCD_DIR"
        w_try vcdmount.exe /l=$letter "$my_img_win"

        tries=0
        while test $tries -lt 20
        do
            for W_ISO_MOUNT_LETTER in e f g h i j k
            do
                # let user blacklist drive letters
                echo "$WINETRICKS_MOUNT_LETTER_IGNORE" | grep -q "$W_ISO_MOUNT_LETTER" && continue
                W_ISO_MOUNT_ROOT=/cygdrive/$W_ISO_MOUNT_LETTER
                if find $W_ISO_MOUNT_ROOT -iname 'setup*' -o -iname '*.exe' -o -iname '*.msi'
                then
                    break 2
                fi
            done
            tries=`expr $tries + 1`
            echo "Waiting for mount to finish mounting"
            sleep 1
        done
    else
        # Linux
        # FIXME: find a way to mount or copy from image without sudo
        _W_USERID=`id -u`
        case "$WINETRICKS_SUDO" in
        gksudo)
          w_try $WINETRICKS_SUDO "mkdir -p $W_ISO_MOUNT_ROOT"
          w_try $WINETRICKS_SUDO "mount -o ro,loop,uid=$_W_USERID,unhide $WINETRICKS_IMG $W_ISO_MOUNT_ROOT"
          ;;
        *)
          w_try $WINETRICKS_SUDO mkdir -p $W_ISO_MOUNT_ROOT
          w_try $WINETRICKS_SUDO mount -o ro,loop,uid=$_W_USERID,unhide "$WINETRICKS_IMG" $W_ISO_MOUNT_ROOT
          ;;
        esac

        echo "Mounting as drive ${W_ISO_MOUNT_LETTER}:"
        # Gotta provide a symlink to the raw disc, else installers that check volume names will fail
        rm -f "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}:"*
        ln -sf "$WINETRICKS_IMG" "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}::"
        ln -sf "$W_ISO_MOUNT_ROOT" "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}:"
        unset _W_USERID
    fi
}

# List the currently mounted udf or iso9660 filesystems that match the given pattern
# Output format:
#   dev mountpoint
#   dev mountpoint
#   ...
# Mountpoints may contain spaces.

winetricks_list_mounts()
{
    mount | egrep 'udf|iso9660' | sed 's,^\([^ ]*\) on \(.*\) type .*,\1 \2,'| grep "$1\$"
}

# Return success and set _W_dev _W_mountpoint if volume $1 is mounted
# Note: setting variables as a way of returning results from a
# shell function exposed several bugs in most shells (except ksh!)
# related to implicit subshells.  It would be better to output
# one string to stdout instead.
winetricks_is_mounted()
{
    # First, check for matching mountpoint
    _W_tmp="`winetricks_list_mounts "$1"`"
    if test "$_W_tmp"
    then
        _W_dev=`echo $_W_tmp | sed 's/ .*//'`
        _W_mountpoint="`echo $_W_tmp | sed 's/^[^ ]* //'`"
        # Volume found!
        return 0
    fi

    # If that fails, read volume name the hard way for each volume
    # Have to use file to return results from implicit subshell
    rm -f /tmp/_W_tmp.$LOGNAME
    winetricks_list_mounts . | while true
    do
        IFS= read _W_tmp

        _W_dev=`echo $_W_tmp | sed 's/ .*//'`
        test "$_W_dev" || break
        _W_mountpoint="`echo $_W_tmp | sed 's/^[^ ]* //'`"
        _W_volname=`winetricks_volname $_W_dev`
        if test "$1" = "$_W_volname"
        then
            # Volume found!  Want to return from function here, but can't
            echo "$_W_tmp" > /tmp/_W_tmp.$LOGNAME
            break
        fi
    done

    if test -f /tmp/_W_tmp.$LOGNAME
    then
        # Volume found!  Return from function.
        _W_dev=`cat /tmp/_W_tmp.$LOGNAME | sed 's/ .*//'`
        _W_mountpoint="`cat /tmp/_W_tmp.$LOGNAME | sed 's/^[^ ]* //'`"
        rm -f /tmp/_W_tmp.$LOGNAME
        return 0
    fi

    # Volume not found
    unset _W_dev _W_mountpoint _W_volname
    return 1
}

winetricks_mount_real_volume()
{
    _W_expected_volname="$1"

    # Wait for user to insert disc.

    case $LANG in
    da*)_W_mountmsg="Indsæt venligst disken '$_W_expected_volname' (krævet af pakken '$_PACKAGE')" ;;
    de*)_W_mountmsg="Disc '$_W_expected_volname' bitte einlegen (für Pakete '$W_PACKAGE')" ;;
    pl*)  _W_mountmsg="Proszę włożyć dysk '$_W_expected_volname' (potrzebny paczce '$W_PACKAGE')" ;;
    *)  _W_mountmsg="Please insert volume '$_W_expected_volname' (needed for package '$W_PACKAGE')" ;;
    esac

    if test "$WINE" = ""
    then
        # Assume already mounted, just get drive letter
        W_ISO_MOUNT_LETTER=`awk '/iso/ {print $1}' < /proc/mounts | tr -d :`
        W_ISO_MOUNT_ROOT=`awk '/iso/ {print $2}' < /proc/mounts`
    else
        while ! winetricks_is_mounted "$_W_expected_volname"
        do
            w_try w_warn_cancel "$_W_mountmsg"
            # In non-gui case, give user two seconds to futz with disc drive before spamming him again
            sleep 2
        done
        WINETRICKS_DEV=$_W_dev
        W_ISO_MOUNT_ROOT="$_W_mountpoint"

        # Gotta provide a symlink to the raw disc, else installers that check volume names will fail
        rm -f "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}:"*
        ln -sf "$WINETRICKS_DEV" "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}::"
        ln -sf "$W_ISO_MOUNT_ROOT" "$WINEPREFIX/dosdevices/${W_ISO_MOUNT_LETTER}:"
    fi

    # FIXME: need to remount some discs with unhide option,
    # add that as option to w_mount

    unset _W_mountmsg
}

winetricks_cleanup()
{
    test "$WINETRICKS_CACHE_SYMLINK" && rm -f "$WINETRICKS_CACHE_SYMLINK"
    test "$W_OPT_NOCLEAN" = 1 || rm -rf "$WINETRICKS_WORKDIR"
}

winetricks_kill_handler()
{
    #echo "Caught signal, cleaning up."
    if test -f "$WINETRICKS_WORKDIR/dd-pid"
    then
        kill `cat "$WINETRICKS_WORKDIR/dd-pid"`
    fi
    winetricks_cleanup
    #echo "Done cleanup, quitting."
    exit
}

winetricks_set_unattended()
{
    # We shouldn't use all these extra variables.  Instead, we should
    # use ${foo:+bar} to jam in commandline options for silent install 
    # only if W_OPT_UNATTENDED is nonempty.  See
    # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02
    # So in attended mode, W_OPT_UNATTENDED should be empty.

    case $1 in
    1)
        W_OPT_UNATTENDED=1
        # Might want to trim our stable of variables here a bit...
        W_UNATTENDED_DASH_Q="-q"
        W_UNATTENDED_SLASH_Q="/q"
        W_UNATTENDED_SLASH_S="/S"
        W_UNATTENDED_DASH_SILENT="-silent"
        W_UNATTENDED_SLASH_SILENT="/silent"
        ;;
    *)
        W_OPT_UNATTENDED=""
        W_UNATTENDED_DASH_Q=""
        W_UNATTENDED_SLASH_Q=""
        W_UNATTENDED_SLASH_S=""
        W_UNATTENDED_DASH_SILENT=""
        W_UNATTENDED_SLASH_SILENT=""
        ;;
    esac
}

# Usage: winetricks_set_wineprefix [bottlename]
# Bottlename must not contain spaces, slashes, or other special charaters
# If bottlename is omitted, the default bottle (~/.wine) is used.
winetricks_set_wineprefix()
{
    if ! test "$1"
    then
        WINEPREFIX="$WINETRICKS_ORIGINAL_WINEPREFIX"
    else
        WINEPREFIX="$W_PREFIXES_ROOT/$1"
    fi
    export WINEPREFIX
    #echo "WINEPREFIX is now $WINEPREFIX" >&2
    mkdir -p "`dirname "$WINEPREFIX"`"

    # Run wine here to force creation of the wineprefix so it's there when we want to make the cache symlink a bit later.
    # The folder-name is localized!
    W_PROGRAMS_WIN="`w_expand_env ProgramFiles`"
    case "$W_PROGRAMS_WIN" in
    "") w_die "$WINE cmd.exe /c echo '%ProgramFiles%' returned empty string" ;;
    %*) w_die "$WINE cmd.exe /c echo '%ProgramFiles%' returned unexpanded string '$W_PROGRAMS_WIN' ... can be caused a corrupt wineprefix, an old wine, or by not owning $WINEPREFIX" ;;
    *unknown*) w_die "$WINE cmd.exe /c echo '%ProgramFiles%' returned a string containing the word 'unknown', as if a voice had cried out in terror, and was suddenly silenced." ;;
    esac

    case "$OS" in
    "Windows_NT")
        W_DRIVE_C="/cygdrive/c" ;;
    *)
        W_DRIVE_C="$WINEPREFIX/dosdevices/c:" ;;
    esac

    # Kludge: use Temp instead of temp to avoid \t expansion in w_try
    # but use temp in unix path because that's what wine creates, and having both temp and Temp
    # causes confusion (e.g. makes vc2005trial fail)
    if ! test "$1"
    then
        W_TMP="$W_DRIVE_C/windows/temp"
        W_TMP_WIN="C:\\windows\\Temp"
    else
        # Verbs can rely on W_TMP being empty at entry, deleted after return, and a subdir of C:
        W_TMP="$W_DRIVE_C/windows/temp/_$1"
        W_TMP_WIN="C:\\windows\\Temp\\_$1"
    fi

    case "$OS" in
     "Windows_NT")
        W_CACHE_WIN="`w_pathconv -w $W_CACHE`"
        ;;
     *)
        # For case where z: doesn't exist or / is writable (!),
        # make a drive letter for W_CACHE.  Clean it up on exit.
        test "$WINETRICKS_CACHE_SYMLINK" && rm -f "$WINETRICKS_CACHE_SYMLINK"
        for letter in y x w v u t s r q p o n m
        do
            if ! test -d "$WINEPREFIX"/dosdevices/${letter}:
            then
                mkdir -p "$WINEPREFIX"/dosdevices
                WINETRICKS_CACHE_SYMLINK="$WINEPREFIX"/dosdevices/${letter}:
                ln -sf "$W_CACHE" "$WINETRICKS_CACHE_SYMLINK"
                break
            fi
        done
        W_CACHE_WIN="${letter}:"
        ;;
    esac

    # FIXME wrong on 64 bit windows for now
    W_COMMONFILES_X86_WIN="`w_expand_env CommonProgramFiles`"

    W_WINDIR_UNIX="$W_DRIVE_C/windows"

    # FIXME: move that tr into w_pathconv, if it's still needed?
    W_PROGRAMS_UNIX="`w_pathconv -u "$W_PROGRAMS_WIN"`"

    # 64 bit windows has a second directory for program files
    W_PROGRAMS_X86_WIN="${W_PROGRAMS_WIN} (x86)"
    W_PROGRAMS_X86_UNIX="${W_PROGRAMS_UNIX} (x86)"
    if ! test -d "$W_PROGRAMS_X86_UNIX"
    then
        W_PROGRAMS_X86_WIN="${W_PROGRAMS_WIN}"
        W_PROGRAMS_X86_UNIX="${W_PROGRAMS_UNIX}"
    fi

    W_APPDATA_WIN="`w_expand_env AppData`"
    W_APPDATA_UNIX="`w_pathconv -u "$W_APPDATA_WIN"`"

    # FIXME: get fonts path from SHGetFolderPath
    # See also http://blogs.msdn.com/oldnewthing/archive/2003/11/03/55532.aspx
    W_FONTSDIR_WIN="c:\\windows\\Fonts"

    # FIXME: just convert path from windows to unix?
    # Did the user rename Fonts to fonts?
    if test ! -d "$W_WINDIR_UNIX"/Fonts && test -d "$W_WINDIR_UNIX"/fonts
    then
        W_FONTSDIR_UNIX="$W_WINDIR_UNIX"/fonts
    else
        W_FONTSDIR_UNIX="$W_WINDIR_UNIX"/Fonts
    fi
    mkdir -p "${W_FONTSDIR_UNIX}"

    # Win(e) 32/64?
    # Using the variable W_SYSTEM32_DLLS instead of SYSTEM32 because some stuff does go under system32 for both arch's
    # e.g., spool/drivers/color
    if test -d "$W_DRIVE_C/windows/syswow64"
    then
        W_ARCH=win64
        W_SYSTEM32_DLLS="$W_WINDIR_UNIX/syswow64"
        W_SYSTEM32_DLLS_WIN="C:\\windows\\syswow64"
        W_SYSTEM64_DLLS="$W_WINDIR_UNIX/system32"
    else
        W_ARCH=win32
        W_SYSTEM32_DLLS="$W_WINDIR_UNIX/system32"
        W_SYSTEM32_DLLS_WIN="C:\\windows\\system32"
    fi
}

winetricks_annihilate_wineprefix()
{
    w_skip_windows "No wineprefix to delete on windows" && return

    w_askpermission "Delete $WINEPREFIX, its apps, icons, and menu items?"
    rm -rf "$WINEPREFIX"/*
    rm -rf "$WINEPREFIX"

    # Also remove menu items.
    find ~/.local/share/applications/wine -type f -name '*.desktop' -exec grep -q -l "$WINEPREFIX" '{}' ';' -exec rm '{}' ';'

    # Also remove desktop items.
    # Desktop might be synonym for home directory, so only go one level
    # deep to avoid extreme slowdown if user has lots of files
    (
    if ! test "$XDG_DESKTOP_DIR" && test -f ~/.config/user-dirs.dirs
    then
        . ~/.config/user-dirs.dirs
    fi
    find "$XDG_DESKTOP_DIR" -maxdepth 1 -type f -name '*.desktop' -exec grep -q -l "$WINEPREFIX" '{}' ';' -exec rm '{}' ';'
    )

    # FIXME: recover more nicely.  At moment, have to restart to avoid trouble.
    exit 0
}

winetricks_init()
{
    #---- Private Variables ----

    # Ephemeral files for this run
    WINETRICKS_WORKDIR=/tmp/w.$LOGNAME.$$
    test "$W_OPT_NOCLEAN" = 1 || rm -rf "$WINETRICKS_WORKDIR"

    # Registering a verb creates a file in WINETRICKS_METADATA
    WINETRICKS_METADATA="$WINETRICKS_WORKDIR/metadata"

    # The list of categories is also hardcoded in winetricks_mainmenu() :-(
    WINETRICKS_CATEGORIES="apps benchmarks dlls fonts games settings"
    for _W_cat in $WINETRICKS_CATEGORIES
    do
        mkdir -p "$WINETRICKS_METADATA"/$_W_cat
    done

    # Which subdirectory of WINETRICKS_METADATA is currently active (or main, if none)
    WINETRICKS_CURMENU=prefix

    # Delete work directory after each run, on exit either graceful or abrupt
    trap winetricks_kill_handler EXIT HUP INT QUIT ABRT

    # Whether to always cache cached iso's (1) or only use cache if present (0)
    # Can be inherited from environment or set via -k, defaults to off
    WINETRICKS_OPT_KEEPISOS=${WINETRICKS_OPT_KEEPISOS:-0}

    # what program to use to make disc image (dd or ddrescue)
    WINETRICKS_OPT_DD=${WINETRICKS_OPT_DD:-dd}

    # whether to use shared wineprefix (1) or unique wineprefix for each app (0)
    WINETRICKS_OPT_SHAREDPREFIX=${WINETRICKS_OPT_SHAREDPREFIX:-0}

    # Mac folks tend to not have sha1sum, but we can make do with openssl
    if [ -x "`which sha1sum 2>/dev/null`" ]
    then
        WINETRICKS_SHA1SUM="sha1sum"
    elif [ -x "`which openssl 2>/dev/null`" ]
    then
        WINETRICKS_SHA1SUM="openssl dgst -sha1"
    else
        w_die "No sha1sum utility available."
    fi

    # Which sourceforge mirror to use.  Rotate based on time, since
    # their mirror picker sometimes persistantly sends you to a broken
    # mirror.
    case `date +%S` in
    *[3])  WINETRICKS_SOURCEFORGE=http://surfnet.dl.sourceforge.net/sourceforge ;;
    *)     WINETRICKS_SOURCEFORGE=http://downloads.sourceforge.net;;
    esac

    if ! test "$USERNAME"
    then
        # Posix only requires LOGNAME to be defined, and sure enough, when
        # logging in via console and startx in ubuntu, USERNAME is not set!
        # I tried using only LOGNAME in this script, but it's so easy to slip
        # and use USERNAME, so define it here if needed.
        USERNAME="$LOGNAME"
    fi

    #---- Public Variables ----

    # Where application installers are cached
    # See http://standards.freedesktop.org/basedir-spec/latest/ar01s03.html
    if test -d "$HOME/Library/Caches"
    then
        # MacOSX
        XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/Library/Caches}"
    else
        XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
    fi
    if test "$WINETRICKS_DIR"
    then
        # For backwards compatibility
        W_CACHE="${W_CACHE:-$WINETRICKS_DIR/cache}"
        WINETRICKS_POST="${WINETRICKS_POST:-$WINETRICKS_DIR/postinstall}"
    else
        W_CACHE="${W_CACHE:-$XDG_CACHE_HOME/winetricks}"
        # FIXME: maybe obey XDG_DATA_HOME
        WINETRICKS_POST="${WINETRICKS_POST:-$HOME/.local/share/winetricks/postinstall}"
    fi
    test -d "$W_CACHE" || mkdir -p "$W_CACHE"
    WINETRICKS_AUTH="${WINETRICKS_AUTH:-$HOME/.local/share/winetricks/auth}"

    # System-specific variables
    case "$OS" in
     "Windows_NT")
        WINE=""
        W_DRIVE_C="C:/"
        ;;
     *)
        WINE="${WINE:-wine}"
        if test "$WINEPREFIX"
        then
            WINETRICKS_ORIGINAL_WINEPREFIX="$WINEPREFIX"
        else
            WINETRICKS_ORIGINAL_WINEPREFIX="$HOME/.wine"
        fi
        ;;
    esac
    winetricks_set_wineprefix

    # FIXME: don't hardcode
    W_PROGRAMS_DRIVE=c


    # Whether to automate installs (0=no, 1=yes)
    winetricks_set_unattended ${W_OPT_UNATTENDED:-0}

    # Overridden for windows
    W_ISO_MOUNT_ROOT=/mnt/winetricks
    W_ISO_MOUNT_LETTER=i

    WINETRICKS_WINE_VERSION=`winetricks_early_wine --version | sed 's/.*wine/wine/'`
    WINETRICKS_WINE_MINOR=`echo $WINETRICKS_WINE_VERSION | sed 's/wine-1\.\([0-9]*\)\..*/\1/'`
    WINETRICKS_WINE_MICRO=`echo $WINETRICKS_WINE_VERSION | sed 's/wine-1.[0-9][0-9]*\.\([0-9]*\).*/\1/'`
}

winetricks_usage()
{
    case $LANG in
    da*)
        cat <<_EOF_
Brug: $0 [tilvalg] [verbum|sti-til-verbum] ...
Kører de angivne verber.  Hvert verbum installerer et program eller ændrer en indstilling.
Tilvalg:
-k|--keep_isos: lagr iso'er lokalt (muliggør senere installation uden disk)
-q|--unattended: stil ingen spørgsmål, installér bare automatisk
-r|--ddrescue: brug alternativ disk-tilgangsmetode (hjælper i tilfælde af en ridset disk)
-v|--verbose: vis alle kommandoer som de bliver udført
-V|--version: vis programversionen og afslut
-h|--help: vis denne besked og afslut
Diverse verber:
list: vis en liste over alle verber
list-cached: vis en liste over verber for allerede-hentede installationsprogrammer
list-download: vis en liste over verber for programmer der kan hentes
list-manual-download: list applications which can be downloaded with some help from the user
list-installed: list already-installed applications
_EOF_
        ;;
    de*)
        cat <<_EOF_
Usage: $0 [options] [verb|path-to-verb] ...
Angegebene Verben ausführen.
Jeder Verb installiert z.B. eine Anwendung oder ändert eine Einstellung.
Optionen:
-k|--keep_isos: isos local speichern (erlaubt spätere Installierung ohne Disk)
-q|--unattended: keine Fragen stellen, alles automatisch installieren
-r|--ddrescue: alternative Zugriffsmodus (hilft bei gekratzten Disks)
-v|--verbose: alle ausgeführten Kommandos anzeigen
-V|--version: Programmversion anzeigen
-h|--help: diese Hilfemeldung anzeigen
Verben:
apps: Typ 'Andwendungen' auswählen
games: Typ 'Spiele' auswählen
list: Verben von ausgewählte Typ auflisten
list-cached: Verben für schon gecachte Installers auflisten
list-download: Verben für herunterladbare Anwendungen auflisten
list-manual-download: list applications which can be downloaded with some help from the user
list-installed: Verben für schon installlierte Programme auflisten
_EOF_
        ;;
    *)
        cat <<_EOF_
Usage: $0 [options] [command|verb|path-to-verb] ...
Executes given verbs.  Each verb installs an application or changes a setting.

Options:
    --force           Don't check whether packages were already installed
    --gui             Show gui diagnostics even when driven by commandline
-k, --keep_isos       Cache isos (allows later installation without disc)
    --no-clean        Don't delete temp directories (useful during debugging)
    --no-isolate      Don't install each app or game in its own bottle
-q, --unattended      Don't ask any questions, just install automatically
-r, --ddrescue        Retry hard when caching scratched discs
    --showbroken      Even show verbs that are currently broken in wine
-v, --verbose         Echo all commands as they are executed
-h, --help            Display this message and exit
-V, --version         Display version and exit

Commands:
list                  list categories
apps list             list verbs in category 'applications'
benchmarks list       list verbs in category 'benchmarks'
dlls list             list verbs in category 'dlls'
games list            list verbs in category 'games'
settings list         list verbs in category 'settings'
list-cached           list cached-and-ready-to-install verbs
list-download         list verbs which download automatically
list-manual-download  list verbs which download with some help from the user
list-installed        list already-installed verbs
prefix=foobar         select WINEPREFIX=$W_PREFIXES_ROOT/foobar
_EOF_
        ;;
    esac
}

winetricks_handle_option()
{
    case "$1" in
    -r|--ddrescue) WINETRICKS_OPT_DD=ddrescue ;;
    -k|--keep_isos) WINETRICKS_OPT_KEEPISOS=1 ;;
    -q|--unattended) winetricks_set_unattended 1 ;;
    -v|--verbose) set -x ;;
    -V|--version) winetricks_print_version ; exit 0;;
    -h|--help) winetricks_usage ; exit 0 ;;
    --isolate) WINETRICKS_OPT_SHAREDPREFIX=0 ;;
    --no-isolate) WINETRICKS_OPT_SHAREDPREFIX=1 ;;
    --no-clean) W_OPT_NOCLEAN=1 ;;
    --force) WINETRICKS_FORCE=1;;
    --gui) winetricks_detect_gui;;
    --showbroken) W_OPT_SHOWBROKEN=1 ;;
    --optin) WINETRICKS_STATS_REPORT=1;;
    --optout) WINETRICKS_STATS_REPORT=0;;
    -*) w_die "unknown option $1" ;;
    *) return 1 ;;
    esac
    return 0
}

# Must initialize variables before calling w_metadata
if ! test "$WINETRICKS_LIB"
then
    WINETRICKS_SRCDIR=`dirname "$0"`
    WINETRICKS_SRCDIR=`cd "$WINETRICKS_SRCDIR"; /bin/pwd`

    # Which GUI helper to use (none/zenity/kdialog).  See winetricks_detect_gui.
    WINETRICKS_GUI=none

    # Handle options before init, to avoid starting wine for --help or --version
    while winetricks_handle_option $1
    do
        shift
    done

    winetricks_init
fi
 
winetricks_install_app()
{
    case $LANG in
    da*) fail_msg="Installationen af pakken $1 fejlede" ;;
    de*) fail_msg="Installieren von Pakete $1 gescheitert" ;;
    pl*) fail_msg="Niepowodzenie przy instalacji paczki $1" ;;
    *)   fail_msg="Failed to install package $1" ;;
    esac

    # FIXME: initialize a new wineprefix for this app, set lots of global variables
    if ! w_do_call $1 $2
    then
        w_die "$fail_msg"
    fi
}

#---- Builtin Verbs ----

#----------------------------------------------------------------
# Runtimes
#----------------------------------------------------------------

#----- common download for several verbs

helper_directx_dl()
{
    # February 2010 DirectX 9c User Redistributable
    # http://www.microsoft.com/downloads/details.aspx?displaylang=en&FamilyID=0cef8180-e94a-4f56-b157-5ab8109cb4f5
    # FIXME: none of the verbs that use this will show download status right
    # until file1 metadata is extended to handle common cache dir
    w_download_to directx9 http://download.microsoft.com/download/E/E/1/EE17FF74-6C45-4575-9CF4-7FC2597ACD18/directx_feb2010_redist.exe a97c820915dc20929e84b49646ec275760012a42

    DIRECTX_NAME=directx_feb2010_redist.exe
}

helper_directx_Jun2010()
{
    # June 2010 DirectX 9c User Redistributable
    # http://www.microsoft.com/downloads/en/details.aspx?FamilyID=3b170b25-abab-4bc3-ae91-50ceb6d8fa8d
    w_download_to directx9 http://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe

    DIRECTX_NAME=directx_Jun2010_redist.exe
}

helper_d3dx9_xx()
{
    dllname=d3dx9_$1

    helper_directx_dl

    # Even kinder, less invasive directx - only extract and override d3dx9_xx.dll
    w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x86*" "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "$dllname.dll" "$x"
    done

    w_override_dlls native $dllname
}

#----------------------------------------------------------------

w_metadata  adobeair dlls \
    title="Adobe AIR 2.7" \
    publisher="Adobe" \
    year="2011" \
    media="download" \
    file1="AdobeAIRInstaller.exe" \
    installed_file1="$W_COMMONFILES_X86_WIN/Adobe AIR/Versions/1.0/Adobe AIR.dll" \
    homepage="http://www.adobe.com/products/air/"

load_adobeair()
{
    # 2010-02-02: sha1sum 5c95f51a680f8c175a92755238127be4ad22c53b
    # 2010-02-20: sha1sum 6f03e723bd855abbe00eb8fdf22da54fb49c62db
    # 2010-07-29: 2.0.2 sha1sum 7b93aedaf48ad7854940e7a4e7d9394a255e888b
    # 2010-12-08: 2.5.1 sha1sum 2664207ca8e836f5070ee356064829a39785a92e
    # 2011-04-13: 2.6   sha1sum 3d9c2f9d8f3533424cfea84d61fcb9464278d9fc
    # 2011-10-26: 2.7   sha1sum dfa337d4b53e9d924356febc116450190fa183dd
    w_download http://airdownload.adobe.com/air/win/download/2.7/AdobeAIRInstaller.exe dfa337d4b53e9d924356febc116450190fa183dd
    cd "$W_CACHE"/adobeair
    w_try $WINE AdobeAIRInstaller.exe $W_UNATTENDED_DASH_SILENT
}

#----------------------------------------------------------------

w_metadata amstream dlls \
    title="MS amstream.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/amstream.dll"

load_amstream()
{
    helper_directx_dl
    mkdir "$W_CACHE"/amstream   # kludge so test -f $file1 works

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'amstream.dll' "$W_TMP/dxnt.cab"
    w_try_regsvr amstream.dll

    w_override_dlls native amstream
}

#----------------------------------------------------------------

w_metadata art2kmin dlls \
    title="MS Access 2007 runtime" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="AccessRuntime.exe" \
    installed_file1="$W_COMMONFILES_X86_WIN/Microsoft Shared/OFFICE12/ACEES.DLL"

load_art2kmin()
{
    # See http://www.microsoft.com/downloads/details.aspx?familyid=d9ae78d9-9dc6-4b38-9fa6-2c745a175aed&displaylang=en
    w_download http://download.microsoft.com/download/D/2/A/D2A2FC8B-0447-491C-A5EF-E8AA3A74FB98/AccessRuntime.exe 571811b7536e97cf4e4e53bbf8260cddd69f9b2d
    cd "$W_CACHE"/art2kmin
    w_try $WINE AccessRuntime.exe $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata atmlib dlls \
    title="Adobe Type Manager" \
    publisher="Adobe" \
    year="2009" \
    media="download" \
    file1="W2KSP4_EN.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/atmlib.dll"

load_atmlib()
{
    # http://www.microsoft.com/downloads/details.aspx?FamilyID=1001AAF1-749F-49F4-8010-297BD6CA33A0&displaylang=en
    # FIXME: This is a huge download for a single dll.
    # FIXME: This download is also used to get msasn1.dll, but we can't download into common cache directory until the file1 metadata download check is extended to handle that.  It'd be better to not need the huge download.
    w_download http://download.microsoft.com/download/E/6/A/E6A04295-D2A8-40D0-A0C5-241BFECD095E/W2KSP4_EN.EXE fadea6d94a014b039839fecc6e6a11c20afa4fa8
    cd "$W_TMP"
    w_try_cabextract "$W_CACHE"/atmlib/W2KSP4_EN.EXE i386/atmlib.dl_
    w_try cp atmlib.dll "$W_SYSTEM32_DLLS"
}

#----------------------------------------------------------------

w_metadata comctl32 dlls \
    title="MS common controls 5.80" \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="cc32inst.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/comctl32.dll"

load_comctl32()
{
    # http://www.microsoft.com/downloads/details.aspx?familyid=6f94d31a-d1e0-4658-a566-93af0d8d4a1e
    w_download http://download.microsoft.com/download/platformsdk/redist/5.80.2614.3600/w9xnt4/en-us/cc32inst.exe 94c3c494258cc54bd65d2f0153815737644bffde

    w_try $WINE "$W_CACHE"/comctl32/cc32inst.exe "/T:$W_TMP_WIN" /c $W_UNATTENDED_SLASH_Q
    w_try_unzip -d "$W_TMP" "$W_TMP"/comctl32.exe
    w_try $WINE "$W_TMP"/x86/50ComUpd.Exe "/T:$W_TMP_WIN" /c $W_UNATTENDED_SLASH_Q
    w_try cp "$W_TMP"/comcnt.dll "$W_SYSTEM32_DLLS"/comctl32.dll

    w_override_dlls native,builtin comctl32

    # some builtin apps don't like native comctl32
    w_override_app_dlls winecfg.exe builtin comctl32
    w_override_app_dlls explorer.exe builtin comctl32
    w_override_app_dlls iexplore.exe builtin comctl32
}

#----------------------------------------------------------------

w_metadata comdlg32ocx dlls \
    title="Common Dialog ActiveX Control for VB6" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="comdlg32.cab" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/comdlg32.ocx"

load_comdlg32ocx()
{
    # By analogy with vb5 version in http://support.microsoft.com/kb/168917
    w_download http://activex.microsoft.com/controls/vb6/comdlg32.cab d4f3e193c6180eccd73bad53a8500beb5b279cbf
    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/comdlg32ocx/comdlg32.cab
    w_try cp "$W_TMP"/comdlg32.ocx "$W_SYSTEM32_DLLS"/comdlg32.ocx
    w_try_regsvr comdlg32.ocx
}

#----------------------------------------------------------------

w_metadata crypt32 dlls \
    title="MS crypt32" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="Q823182_XPE_SP2_X86_ENU.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/crypt32.dll"

load_crypt32()
{
    w_call msasn1

    # https://www.microsoft.com/downloads/en/details.aspx?FamilyID=3d733ddd-1182-4d46-87c1-3357ca3fed28&DisplayLang=en
    w_download http://download.microsoft.com/download/1/6/2/1629d13a-dc5e-4dc6-a2a4-a6784942b94e/Q823182_XPE_SP2_X86_ENU.EXE c3e0aa35ab5197ede0d495c0edc242cf0fade54a
    w_try_cabextract -d "$W_SYSTEM32_DLLS" "$W_CACHE"/crypt32/Q823182_XPE_SP2_X86_ENU.EXE -F rep/329115_crypt32.dll
    mv "$W_SYSTEM32_DLLS"/rep/329115_crypt32.dll "$W_SYSTEM32_DLLS"/crypt32.dll
    w_override_dlls native crypt32
}

#----------------------------------------------------------------

w_metadata d3dcompiler_43 dlls \
    title="MS d3dcompiler_43.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dcompiler_43.dll" \
    wine_showstoppers="24013"   # list a showstopper to hide this from average users for now

load_d3dcompiler_43()
{
    dllname=d3dcompiler_43

    helper_directx_Jun2010

    w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x86*" "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "$dllname.dll" "$x"
    done

    w_override_dlls native $dllname
}

#----------------------------------------------------------------

w_metadata d3dx9 dlls \
    title="MS d3dx9_??.dll from DirectX 9 redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_24.dll"

load_d3dx9()
{
    helper_directx_dl

    # Kinder, less invasive directx - only extract and override d3dx9_??.dll
    w_try_cabextract -d "$W_TMP" -L -F '*d3dx9*x86*' "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'd3dx9*.dll' "$x"
    done

    # For now, not needed, but when Wine starts preferring our builtin dll over native it will be.
    w_override_dlls native d3dx9_24 d3dx9_25 d3dx9_26 d3dx9_27 d3dx9_28 d3dx9_29 d3dx9_30
    w_override_dlls native d3dx9_31 d3dx9_32 d3dx9_33 d3dx9_34 d3dx9_35 d3dx9_36 d3dx9_37
    w_override_dlls native d3dx9_38 d3dx9_39 d3dx9_40 d3dx9_41 d3dx9_42 d3dx9_43
}

#----------------------------------------------------------------

w_metadata d3dx9_26 dlls \
    title="MS d3dx9_26.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_26.dll"

load_d3dx9_26()
{
    helper_d3dx9_xx 26
}

#----------------------------------------------------------------

w_metadata d3dx9_28 dlls \
    title="MS d3dx9_28.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_28.dll"

load_d3dx9_28()
{
    helper_d3dx9_xx 28
}

#----------------------------------------------------------------

w_metadata d3dx9_31 dlls \
    title="MS d3dx9_31.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_31.dll"

load_d3dx9_31()
{
    helper_d3dx9_xx 31
}

#----------------------------------------------------------------

w_metadata d3dx9_35 dlls \
    title="MS d3dx9_35.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_35.dll"

load_d3dx9_35()
{
    helper_d3dx9_xx 35
}

#----------------------------------------------------------------

w_metadata d3dx9_36 dlls \
    title="MS d3dx9_36.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_36.dll"

load_d3dx9_36()
{
    helper_d3dx9_xx 36
}

#----------------------------------------------------------------

w_metadata d3dx9_39 dlls \
    title="MS d3dx9_39.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_39.dll"

load_d3dx9_39()
{
    helper_d3dx9_xx 39
}

#----------------------------------------------------------------

w_metadata d3dx9_42 dlls \
    title="MS d3dx9_42.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_42.dll"

load_d3dx9_42()
{
    helper_d3dx9_xx 42
}

#----------------------------------------------------------------

w_metadata d3dx9_43 dlls \
    title="MS d3dx9_43.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx9_43.dll"

load_d3dx9_43()
{
    dllname=d3dx9_43

    helper_directx_Jun2010

    w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x86*" "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "$dllname.dll" "$x"
    done

    w_override_dlls native $dllname
}

#----------------------------------------------------------------

w_metadata d3dx11_42 dlls \
    title="MS d3dx11_42.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx11_42.dll"

load_d3dx11_42()
{
    dllname=d3dx11_42

    helper_directx_Jun2010

    w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x86*" "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "$dllname.dll" "$x"
    done

    w_override_dlls native $dllname
}

#----------------------------------------------------------------

w_metadata d3dx11_43 dlls \
    title="MS d3dx11_43.dll" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx11_43.dll"

load_d3dx11_43()
{
    dllname=d3dx11_43

    helper_directx_Jun2010

    w_try_cabextract -d "$W_TMP" -L -F "*$dllname*x86*" "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "$dllname.dll" "$x"
    done

    w_override_dlls native $dllname
}

#----------------------------------------------------------------

w_metadata d3dx10 dlls \
    title="MS d3dx10_??.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx10_33.dll"

load_d3dx10()
{
    helper_directx_dl

    # Kinder, less invasive directx10 - only extract and override d3dx10_??.dll
    w_try_cabextract -d "$W_TMP" -L -F '*d3dx10*x86*' "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'd3dx10*.dll' "$x"
    done

    # For now, not needed, but when Wine starts preferring our builtin dll over native it will be.
    w_override_dlls native d3dx10_33 d3dx10_34 d3dx10_35 d3dx10_36 d3dx10_37
    w_override_dlls native d3dx10_38 d3dx10_39 d3dx10_40 d3dx10_41 d3dx10_42
}

#----------------------------------------------------------------

w_metadata d3dxof dlls \
    title="MS d3dxof.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dxof.dll"

load_d3dxof()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F 'dxnt.cab' "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'd3dxof.dll' "$W_TMP/dxnt.cab"

    w_override_dlls native d3dxof
}

#----------------------------------------------------------------

w_metadata devenum dlls \
    title="MS devenum.dll from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/devenum.dll"

load_devenum()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F 'dxnt.cab' "$W_CACHE/directx9/$DIRECTX_NAME"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'devenum.dll' "$W_TMP/dxnt.cab"
    w_try_regsvr devenum.dll
    w_override_dlls native devenum
}

#----------------------------------------------------------------

w_metadata dinput dlls \
    title="MS dinput.dll; breaks mouse, use only on Rayman 2 etc." \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dinput.dll"

load_dinput()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F 'dxnt.cab' "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dinput.dll' "$W_TMP/dxnt.cab"
    w_try_regsvr dinput
    w_override_dlls native dinput
}

#----------------------------------------------------------------

w_metadata dinput8 dlls \
    title="MS DirectInput 8 from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dinput8.dll"

load_dinput8()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F 'dxnt.cab' "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dinput8.dll' "$W_TMP/dxnt.cab"
    w_try_regsvr dinput8
    w_override_dlls native dinput8
}

#----------------------------------------------------------------

w_metadata directmusic dlls \
    title="MS DirectMusic from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dmusic.dll"

load_directmusic()
{
# Untested. Based off http://bugs.winehq.org/show_bug.cgi?id=4805 and http://bugs.winehq.org/show_bug.cgi?id=24911
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'devenum.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmband.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmcompos.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmime.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmloader.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmscript.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmstyle.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmsynth.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmusic.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmusic32.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dswave.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'streamci.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'quartz.dll' "$W_TMP/dxnt.cab"

    w_try_regsvr devenum.dll
    w_try_regsvr dmband.dll
    w_try_regsvr dmcompos.dll
    w_try_regsvr dmime.dll
    w_try_regsvr dmloader.dll
    w_try_regsvr dmscript.dll
    w_try_regsvr dmstyle.dll
    w_try_regsvr dmsynth.dll
    w_try_regsvr dmusic.dll
    w_try_regsvr dswave.dll
    w_try_regsvr quartz.dll

    w_override_dlls native devenum dmband dmcompos dmime dmloader dmscript dmstyle dmsynth dmusic dmusic32 dswave streamci quartz
}

#----------------------------------------------------------------

w_metadata directplay dlls \
    title="MS DirectPlay from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dplayx.dll"

load_directplay()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dplaysvr.exe' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dplayx.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dpnet.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dpnhpast.dll' "$W_TMP/dxnt.cab"
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dpwsockx.dll' "$W_TMP/dxnt.cab"

    w_try_regsvr dplayx.dll
    w_try_regsvr dpnet.dll
    w_try_regsvr dpnhpast.dll

    w_override_dlls native dplayx dpnet dpnhpast dpwsockx
}

#----------------------------------------------------------------

w_metadata directx9 dlls \
    title="MS DirectX 9 (Usually overkill.  Try d3dx9_36 first)" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/d3dx10_33.dll"

load_directx9()
{
    helper_directx_dl

    w_warn "You probably shouldn't be using this.  d3dx9 or, better, d3dx9_36 usually suffice."

    # Stefan suggested that, when installing, one should override as follows:
    # 1) use builtin wintrust (we don't run native properly somehow?)
    # 2) disable mscoree (else if it's present some module misbehaves?)
    # 3) override native any directx DLL whose Wine version doesn't register itself well yet
    # For #3, I have no idea which DLLs don't register themselves well yet,
    # so I'm just listing a few of the basic ones.  Let's whittle that
    # list down as soon as we can.

    # Setting windows version to win2k apparently crashes the installer on OS X.
    # See http://code.google.com/p/winezeug/issues/detail?id=71
    w_set_winver winxp

    cd "$W_CACHE"/directx9
    WINEDLLOVERRIDES="wintrust=b,mscoree=,ddraw,d3d8,d3d9,dsound,dinput=n" \
        w_try $WINE $DIRECTX_NAME /t:"$W_TMP_WIN" $W_UNATTENDED_SLASH_Q

    # How many of these do we really need?
    # We should probably remove most of these...?
    w_override_dlls native d3dim d3drm d3dx8 d3dx9_24 d3dx9_25 d3dx9_26 d3dx9_27 d3dx9_28 d3dx9_29
    w_override_dlls native d3dx9_30 d3dx9_31 d3dx9_32 d3dx9_33 d3dx9_34 d3dx9_35 d3dx9_36 d3dx9_37
    w_override_dlls native d3dx9_38 d3dx9_39 d3dx9_40 d3dx9_41 d3dx9_42 d3dx9_43 d3dxof
    w_override_dlls native dciman32 ddrawex devenum dmband dmcompos dmime dmloader dmscript dmstyle
    w_override_dlls native dmsynth dmusic dmusic32 dnsapi dplay dplayx dpnaddr dpnet dpnhpast dpnlobby
    w_override_dlls native dswave dxdiagn msdmo qcap quartz streamci
    w_override_dlls native dxdiag.exe
    w_override_dlls builtin d3d8 d3d9 dinput dinput8 dsound

    w_try $WINE "$W_TMP_WIN"\\DXSETUP.exe $W_UNATTENDED_SLASH_SILENT
}

#----------------------------------------------------------------

w_metadata dmsynth dlls \
    title="MS midi synthesizer from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dmsynth.dll"

load_dmsynth()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dmsynth.dll' "$W_TMP/dxnt.cab"

    w_try_regsvr dmsynth.dll

    w_override_dlls native dmsynth
}

#----------------------------------------------------------------

w_metadata dotnet11 dlls \
    title="MS .NET 1.1" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="dotnetfx.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v1.1.4322/ndpsetup.ico"

load_dotnet11()
{
    if [ $W_ARCH = win64 ]
    then
        w_die "This package does not work on a 64-bit installation"
    fi

    w_call fontfix

    # http://www.microsoft.com/downloads/details.aspx?FamilyId=262D25E3-F589-4842-8157-034D1E7CF3A3
    w_download http://download.microsoft.com/download/a/a/c/aac39226-8825-44ce-90e3-bf8203e74006/dotnetfx.exe 16a354a2207c4c8846b617cbc78f7b7c1856340e

    # Remove bits of Wine that conflict with native .net 11
    rm -rf "$W_WINDIR_UNIX/Microsoft.NET/Framework/v1.1.4322"
    $WINE reg delete "HKLM\Software\Microsoft\.NETFramework\policy\v2.0" /f || true
    $WINE reg delete "HKLM\Software\Microsoft\.NETFramework" /v InstallRoot /f || true

    # need corefonts, else installer crashes
    w_call corefonts

    # Use builtin regsvcs.exe to work around http://bugs.winehq.org/show_bug.cgi?id=25120
    if test $W_OPT_UNATTENDED
    then
        WINEDLLOVERRIDES="regsvcs.exe=b" w_try $WINE "$W_CACHE"/dotnet11/dotnetfx.exe /q /C:"install /q"
    else
        WINEDLLOVERRIDES="regsvcs.exe=b" w_try $WINE "$W_CACHE"/dotnet11/dotnetfx.exe
    fi
}

#----------------------------------------------------------------

w_metadata dotnet11sp1 dlls \
    title="MS .NET 1.1 SP1" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="NDP1.1sp1-KB867460-X86.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v1.1.4322/CONFIG/security.config"

# fixme: sometimes security.config is missing after install, see
# http://blogs.msdn.com/b/shawnfa/archive/2006/02/09/527688.aspx
# If this happens often, we may need to change the install check.
load_dotnet11sp1()
{
    w_call dotnet11
    w_download http://download.microsoft.com/download/8/b/4/8b4addd8-e957-4dea-bdb8-c4e00af5b94b/NDP1.1sp1-KB867460-X86.exe 74a5b25d65a70b8ecd6a9c301a0aea10d8483a23

    if test $W_OPT_UNATTENDED
    then
        WINEDLLOVERRIDES="regsvcs.exe=b" w_try $WINE "$W_CACHE"/dotnet11sp1/NDP1.1sp1-KB867460-X86.exe /q /C:"install /q"
    else
        WINEDLLOVERRIDES="regsvcs.exe=b" w_try $WINE "$W_CACHE"/dotnet11sp1/NDP1.1sp1-KB867460-X86.exe
    fi
}

#----------------------------------------------------------------

w_metadata dotnet20 dlls \
    title="MS .NET 2.0" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="dotnetfx.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v2.0.50727/mscorlib.dll"

load_dotnet20()
{
    w_call fontfix

    # Recipe from http://bugs.winehq.org/show_bug.cgi?id=10467#c57
    w_set_winver win2k

    cd "$W_CACHE"/dotnet20

    if test ! -f l_intl.nls
    then
        # See http://kegel.com/wine/l_intl-sh.txt for how l_intl.nls was generated
        # Use zip rather than naked file to get past strange web proxies
        w_download http://kegel.com/wine/l_intl.zip 5cc2665e9a518a2e560d3aeac6758d0cd8ec3a2a
        # FIXME: w_download changes current directory
        cd "$W_CACHE"/dotnet20

        w_try_unzip -d "$W_SYSTEM32_DLLS" l_intl.zip
    fi

    # Hans' workaround to avoid winehq nonbug 26464, crash in servicemodelreg.exe
    rm -rf "$W_WINDIR_UNIX"/Microsoft.NET/Framework/v2.0.50727

    # Delete registry keys used to indicate .net 2.x's presence
    # Breaks .net 3.5 install, leave it out until we figure that out
    #$WINE reg delete "HKLM\\Software\Microsoft\NET Framework Setup\NDP\v2.0.50727"

    # http://www.microsoft.com/downloads/details.aspx?FamilyID=0856eacb-4362-4b0d-8edd-aab15c5e04f5
    w_download http://download.microsoft.com/download/5/6/7/567758a3-759e-473e-bf8f-52154438565a/dotnetfx.exe a3625c59d7a2995fb60877b5f5324892a1693b2a
    w_try $WINE dotnetfx.exe ${W_OPT_UNATTENDED:+/q /c:"install.exe /q"}
    w_unset_winver

    # We can't stop installing dotnet20 in win2K mode until wine supports
    # reparse/junction points
    # (see http://bugs.winehq.org/show_bug.cgi?id=10467#c57 )
    # so for now just remove the bogus msvc*80.dll files it installs.
    # See also http://bugs.winehq.org/show_bug.cgi?id=16577
    # This affects Victoria 2 demo, see http://forum.paradoxplaza.com/forum/showthread.php?p=11523967
    rm -f "$W_SYSTEM32_DLLS"/msvc?80.dll
}

#----------------------------------------------------------------

w_metadata dotnet20sp1 dlls \
    title="MS .NET 2.0 SP1 (experimental)" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="NetFx20SP1_x86.exe" \
    installed_file1="c:/windows/assembly/NativeImages_v2.0.50727_32/indexb.dat"

load_dotnet20sp1()
{
    if w_workaround_wine_bug 16956 "wine version too old" 1.3.22,
    then
        w_die "wine-1.3.22 or later required to install dotnet20sp1 properly"
    fi

    w_call dotnet20

    WINEDLLOVERRIDES=
    if w_workaround_wine_bug 16956 "Setting windows version so installer works"
    then
        # Stop services
        # Recipe from http://bugs.winehq.org/show_bug.cgi?id=16956
        # FIXME: use a wrapper function for this
        wineserver -k
        # Fight a race condition, see bug 16956 comment 43
        w_set_winver win2k
        wineserver -w
        WINEDLLOVERRIDES=ngen.exe,regsvcs.exe,mscorsvw.exe=b 
        export WINEDLLOVERRIDES
    fi

    w_download http://download.microsoft.com/download/0/8/c/08c19fa4-4c4f-4ffb-9d6c-150906578c9e/NetFx20SP1_x86.exe eef5a36924cdf0c02598ccf96aa4f60887a49840
    cd "$W_CACHE"/dotnet20sp1
    $WINE NetFx20SP1_x86.exe ${W_OPT_UNATTENDED:+/q} 
    status=$?

    case $status in
    0) ;;
    105) echo "exit status $status - normal, user selected 'restart now'" ;;
    194) echo "exit status $status - normal, user selected 'restart later'" ;;
    *) w_die "exit status $status - $W_PACKAGE installation failed" ;;
    esac

    # We can't stop installing dotnet20sp1 in win2K mode until wine supports
    # reparse/junction points
    # (see http://bugs.winehq.org/show_bug.cgi?id=10467#c57 )
    # so for now just remove the bogus msvc*80.dll files it installs.
    # See also http://bugs.winehq.org/show_bug.cgi?id=16577
    # This affects Victoria 2 demo, see http://forum.paradoxplaza.com/forum/showthread.php?p=11523967
    rm -f "$W_SYSTEM32_DLLS"/msvc?80.dll

    w_unset_winver
}

#----------------------------------------------------------------

w_metadata dotnet20sp2 dlls \
    title="MS .NET 2.0 SP2 (experimental)" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="NetFx20SP2_x86.exe" \
    installed_file1="c:/windows/winsxs/manifests/x86_Microsoft.VC80.CRT_1fc8b3b9a1e18e3b_8.0.50727.3053_x-ww_b80fa8ca.cat"

load_dotnet20sp2()
{
    if w_workaround_wine_bug 22521 "wine version too old" 1.3.18,
    then
        w_die "wine-1.3.18 or later required to install dotnet20sp2"
    fi

    w_call dotnet20

    WINEDLLOVERRIDES=
    if w_workaround_wine_bug 22521 "Adding registry key, setting windows version so installer works"
    then
        # Recipe from http://bugs.winehq.org/show_bug.cgi?id=22521
        $WINE reg add "HKLM\Software\Microsoft\Net Framework Setup\NDP\v2.0.50727" /v Version /d "2.0.50727" /f
        # Stop services
        # Recipe from http://bugs.winehq.org/show_bug.cgi?id=16956
        # FIXME: use a wrapper function for this
        wineserver -k
        # Fight a race condition, see bug 16956 comment 43
        w_set_winver win2k
        wineserver -w
        WINEDLLOVERRIDES=regsvcs.exe,mscorsvw.exe=b 
        export WINEDLLOVERRIDES
    fi

    # http://www.microsoft.com/downloads/details.aspx?familyid=5B2C0358-915B-4EB5-9B1D-10E506DA9D0F
    w_download http://download.microsoft.com/download/c/6/e/c6e88215-0178-4c6c-b5f3-158ff77b1f38/NetFx20SP2_x86.exe 22d776d4d204863105a5db99e8b8888be23c61a7
    cd "$W_CACHE"/dotnet20sp2
    $WINE NetFx20SP2_x86.exe ${W_OPT_UNATTENDED:+ /q /c:"install.exe /q"}
    status=$?

    case $status in
    0) ;;
    105) echo "exit status $status - normal, user selected 'restart now'" ;;
    194) echo "exit status $status - normal, user selected 'restart later'" ;;
    *) w_die "exit status $status - $W_PACKAGE installation failed" ;;
    esac

    w_unset_winver
}

#----------------------------------------------------------------

w_metadata dotnet30 dlls \
    title="MS .NET 3.0" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="dotnetfx3.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v3.0/Microsoft .NET Framework 3.0/logo.bmp"

load_dotnet30()
{
    case "$OS" in
    "Windows_NT")
        osver=`cmd /c ver`
        case "$osver" in
        *Version?6*) w_die "Vista and up bundle .net 3.0, so you can't install it like this" ;;
        esac
        ;;
    esac

    w_call dotnet20

    # Delete files and registry keys related to .net 3.x
    # Breaks .net 3.5 installation, so don't do this yet
    #rm -rf "$W_WINDIR_UNIX"/Microsoft.NET/Framework/v3.0
    #$WINE reg delete "HKLM\\Software\Microsoft\NET Framework Setup\NDP\v3.0"

    w_warn "Installing .net 3.0 runtime takes 3 minutes on a very fast machine, and the Finished dialog may hide in the taskbar."
    # http://msdn.microsoft.com/en-us/netframework/bb264589.aspx
    w_download http://download.microsoft.com/download/3/F/0/3F0A922C-F239-4B9B-9CB0-DF53621C57D9/dotnetfx3.exe f3d2c3c7e4c0c35450cf6dab1f9f2e9e7ff50039

    # AF's workaround to avoid long pause
    LANGPACKS_BASE_PATH="${W_WINDIR_UNIX}/SYSMSICache/Framework/v3.0"
    test -d "${LANGPACKS_BASE_PATH}" || mkdir -p "${LANGPACKS_BASE_PATH}"
    for lang in ar cs da de el es fi fr he it jp ko nb nl pl pt-BR pt-PT ru \
                sv tr zh-CHS zh-CHT
    do
        ln -sf "${W_SYSTEM32_DLLS}/spupdsvc.exe" "${LANGPACKS_BASE_PATH}/dotnetfx3langpack${lang}.exe"
    done

    w_set_winver winxp

    # Delete FontCache 3.0 service, it's in Wine for Mono, breaks native .NET
    w_try $WINE sc delete "FontCache3.0.0.0"
    cd "$W_CACHE"/dotnet30
    w_try $WINE $file1 ${W_OPT_UNATTENDED:+ /q /c:"install.exe /q"}
}

#----------------------------------------------------------------

w_metadata dotnet30sp1 dlls \
    title="MS .NET 3.0 SP1" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="NetFx30SP1_x86.exe" \
    installed_file1="c:/windows/system32/XpsFilt.dll"    # we're cheating a bit here

load_dotnet30sp1()
{
    case "$OS" in
    "Windows_NT") ;;
    *) w_warn "dotnet30sp1 does not yet fully work or install on wine.  Caveat emptor." ;;
    esac

    w_call dotnet30

    w_download http://download.microsoft.com/download/8/F/E/8FEEE89D-9E4F-4BA3-993E-0FFEA8E21E1B/NetFx30SP1_x86.exe 8d779e337920b097aa0c01859912950606e9fc12
    cd "$W_CACHE/$W_PACKAGE"

    # Recipe from http://bugs.winehq.org/show_bug.cgi?id=25060#c10
    w_download http://download.microsoft.com/download/2/5/2/2526f55d-32bc-410f-be18-164ba67ae07d/"XPSEP XP and Server 2003 32 bit.msi" 5d332ebd1025e294adafe72030fe33db707b2c82
    w_try $WINE msiexec /i "XPSEP XP and Server 2003 32 bit.msi" # ${W_OPT_UNATTENDED:+/q} broken?
    $WINE sc delete FontCache3.0.0.0

    $WINE $file1 ${W_OPT_UNATTENDED:+/q}
    status=$?
    w_info $file1 exited with status $status
}

#----------------------------------------------------------------

w_metadata dotnet35 dlls \
    title="MS .NET 3.5" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="dotnetfx35.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/v3.5/MSBuild.exe"

load_dotnet35()
{
    case "$OS" in
    "Windows_NT") ;;
    *) w_warn "dotnet35 does not yet fully work or install on wine.  Caveat emptor." ;;
    esac

    # According to AF's recipe, installing dotnet30 first works around msi bugs
    w_call dotnet30

    # http://www.microsoft.com/downloads/details.aspx?FamilyId=333325FD-AE52-4E35-B531-508D977D32A6
    w_download http://download.microsoft.com/download/6/0/f/60fc5854-3cb8-4892-b6db-bd4f42510f28/dotnetfx35.exe 0a271bb44531aadef902829f98dfad66e4a57586

    # See also http://blogs.msdn.com/astebner/archive/2008/07/17/8745415.aspx
    cd "$W_TMP"
    w_try_cabextract $W_UNATTENDED_DASH_Q "$W_CACHE"/dotnet35/dotnetfx35.exe
    cd wcu/dotNetFramework
    $WINE dotNetFx35setup.exe /lang:ENU $W_UNATTENDED_SLASH_Q

    # FIXME: Do this only if the above commmand failed (not sure how to detect it... look for some file, I s'pose)
    if w_workaround_wine_bug 25060
    then
        # Thanks to Louis for this partial recipe
        #w_try $WINE reg add 'HKLM\Software\Microsoft\NET Framework Setup\NDP\v2.0.50727' /v SP /t REG_DWORD /d 0001
        cat > "$W_TMP"/sp1.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\NET Framework Setup\NDP\v2.0.50727]
"SP"=dword:00000001

_EOF_
        w_try $WINE regedit "$W_TMP"/sp1.reg
        cd "$W_TMP"/wcu/dotNetFramework/dotNetFX35/x86
        w_try_cabextract netfx35_x86.exe
        w_try $WINE msiexec /i vs_setup.msi ADDEPLOY=1
    fi
}

#----------------------------------------------------------------

w_metadata dxdiagn dlls \
    title="DirectX Diagnostic Library" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dxdiagn.dll"

load_dxdiagn()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F dxdiagn.dll "$W_TMP/dxnt.cab"
    w_override_dlls native dxdiagn
}

#----------------------------------------------------------------

w_metadata dsound dlls \
    title="MS DirectSound from DirectX user redistributable" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dsound.dll"

load_dsound()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'dsound.dll' "$W_TMP/dxnt.cab"

    w_try_regsvr dsound.dll

    w_override_dlls native dsound
}

#----------------------------------------------------------------

# FIXME: update winetricks_is_installed to look at installed_file2
w_metadata flash dlls \
    title="Flash Player 10" \
    publisher="Adobe" \
    year="2011" \
    media="download" \
    file1="install_flash_player_10.exe" \
    file2="install_flash_player_10_active_x.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/Macromed/Flash/FlashUtil10y_Plugin.exe" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/Macromed/Flash/FlashUtil10y_ActiveX.exe" \
    homepage="http://www.adobe.com/products/flashplayer/"

load_flash()
{
    # Active X plugin
    # http://blogs.adobe.com/psirt/2008/03/preparing_for_april_flash_play.html
    # http://fpdownload.macromedia.com/get/flashplayer/current/licensing/win/install_flash_player_active_x.msi
    # 2010-11-04: sha1sum 58412bcc83e349be50cafe0e1c46e19088620866
    # 2011-02-12: sha1sum 944c1f2055cd85af37ef44629773c2cf1d02a21c
    # 2011-02-24: sha1sum f2e6a3f486423d6c1be48ad80fb3b7d4cdafd29d
    # 2011-03-15: sha1sum 07908231028f68098902d5aa52812b7e27f8497a
    # 2011-04-12: sha1sum 80b547dde20c0e80f739c3ba66be1065a94e4244
    # 2011-05-13: sha1sum ae401aa3ba54ebe12c2fb3b94cd1bb5881074169
    # 2011-06-13: sha1sum 2c1ae9cf04f67ca611af7df695d3ea4337fb73fc
    # 2011-06-23: sha1sum da3f4b28f77a44b25cfb1453278683b888904714
    # 2011-10-26: sha1sum 964199abcbaa9f42273ed5030d039ead03407b76
    # 2011-11-12: sha1sum 1b84a14b4325a6ae17c590b7c9de749daeca7b6f
    w_download http://fpdownload.macromedia.com/get/flashplayer/current/licensing/win/install_flash_player_10_active_x.exe 1b84a14b4325a6ae17c590b7c9de749daeca7b6f
    cd "$W_CACHE"/flash

    w_try $WINE install_flash_player_10_active_x.exe ${W_OPT_UNATTENDED:+ /install}

    # Mozilla / Firefox plugin
    # 2010-11-04: sha1sum 09f2491c5bec7286155234f4e6e1af70c7cef78f
    # 2011-02-12: sha1sum 4a650caf62d8841d14b9d7888ab9b69d5d6f617a
    # 2011-02-24: sha1sum 009c908cdb73fba18b34e798b1f601ed964102a1
    # 2011-03-15: sha1sum 487b7003386ba80da00fa56cfd1d33241b8a0e41
    # 2011-04-12: sha1sum 706523aa1af2e77f9ae7727202ebe0f0f5e71a39
    # 2011-05-13: sha1sum 4d800cbf339f8d4f2a524da1aa79d10a785da42e
    # 3aefb5132f7c326b046e4bc82e41bf399fc7cf5f
    # 2011-06-13: sha1sum f6248cdda8c5b3d36bb414d67d2373f205e257c7
    # 2011-06-23: sha1sum 8c14f60fa625d26698afceb1e234eaae4637389e
    # 2011-10-26: sha1sum a04d5ecc27dbc439d9ca0c994ac7db39a0d3d081
    # 2011-11-12: sha1sum 2e834f95880fd0b96a9db93ff48f1e4178ee0913
    w_download http://fpdownload.macromedia.com/get/flashplayer/current/licensing/win/install_flash_player_10.exe 2e834f95880fd0b96a9db93ff48f1e4178ee0913

    w_try $WINE install_flash_player_10.exe ${W_OPT_UNATTENDED:+ /install}
}

#----------------------------------------------------------------

# FIXME: update winetricks_is_installed to look at installed_file2
w_metadata flash11 dlls \
    title="Flash Player 11" \
    publisher="Adobe" \
    year="2011" \
    media="download" \
    file1="install_flash_player_32bit.exe" \
    file2="install_flash_player_ax_32bit.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/Macromed/Flash/FlashUtil11e_Plugin.exe" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/Macromed/Flash/FlashUtil11e_ActiveX.exe" \
    homepage="http://www.adobe.com/products/flashplayer/"

load_flash11()
{
    # Active X plugin
    # 2011-11-12: sha1sum 8314061c4d73c9957dfb4da525d77437ee6abf0e
    w_download http://fpdownload.macromedia.com/get/flashplayer/pdc/11.1.102.55/install_flash_player_ax_32bit.exe 8314061c4d73c9957dfb4da525d77437ee6abf0e
    cd "$W_CACHE"/flash11

    w_try $WINE install_flash_player_ax_32bit.exe ${W_OPT_UNATTENDED:+ /install}

    # Mozilla / Firefox plugin
    # 2011-11-12: sha1sum f1f76c35564c9f842a7e005d97f5008173466d46
    w_download http://fpdownload.macromedia.com/get/flashplayer/pdc/11.1.102.55/install_flash_player_32bit.exe f1f76c35564c9f842a7e005d97f5008173466d46

    w_try $WINE install_flash_player_32bit.exe ${W_OPT_UNATTENDED:+ /install}
}

#----------------------------------------------------------------

w_metadata gdiplus dlls \
    title="MS GDI+" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="WindowsXP-KB975337-x86-ENU.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/gdiplus.dll"

load_gdiplus()
{
    # FIXME: do newer versions of windows install a gdiplus in winsxs?
    # If so, and one is present, perhaps we should return without doing
    # anything here.

    # http://www.microsoft.com/downloads/details.aspx?familyid=6A63AB9C-DF12-4D41-933C-BE590FEAA05A&displaylang=en
    w_download http://download.microsoft.com/download/a/b/c/abc45517-97a0-4cee-a362-1957be2f24e1/WindowsXP-KB975337-x86-ENU.exe b9a84bc3de92863bba1f5eb1d598446567fbc646
    # Used to use $W_UNATTENDED_SLASH_Q, but that mean that in non-q
    # mode, a mysterious "Extraction Complete" dialog was all user saw.
    # Showing that isn't useful, so always use /q.
    cd "$W_CACHE"/gdiplus
    w_try $WINE WindowsXP-KB975337-x86-ENU.exe /extract:$W_TMP_WIN /q
    # And then make it globally available.
    w_try cp "$W_TMP/asms/10/msft/windows/gdiplus/gdiplus.dll" "$W_SYSTEM32_DLLS"

    # For some reason, native,builtin isn't good enough...?
    w_override_dlls native gdiplus
}

#----------------------------------------------------------------

w_metadata glidewrapper dlls \
    title="GlideWrapper" \
    publisher="Rolf Neuberger" \
    year="2005" \
    media="download" \
    file1="GlideWrapper084c.exe" \
    installed_file1="c:/windows/glide3x.dll"

load_glidewrapper()
{
    w_download http://www.zeckensack.de/glide/archive/GlideWrapper084c.exe 7a9d60a18b660473742b476465e9aea7bd5ab6f8
    cd "$W_CACHE/$W_PACKAGE"
    # NSIS installer
    w_try $WINE $file1 ${W_OPT_UNATTENDED:+ /S}
}

#----------------------------------------------------------------

w_metadata gecko dlls \
    title="Gecko (usually installed by distro)" \
    publisher="WineHQ/Mozilla"

load_gecko()
{
    if test -f /usr/share/wine/gecko/wine_gecko-1.0.0-x86.cab && test -f /usr/share/wine/gecko/wine_gecko-1.1.0-x86.cab && test -f /usr/share/wine/gecko/wine_gecko-1.2.0-x86.msi 
    then
        w_warn "gecko is already installed in /usr/share/wine"
    else
        w_warn "Please install gecko in /usr/share/wine per http://wiki.winehq.org/Gecko.  http://winezeug.googlecode.com/svn/trunk/install-gecko.sh is an easy script to do that.  Then you should never need to do 'winetricks gecko' again."
    fi
}

#----------------------------------------------------------------

w_metadata gecko110 dlls \
    title="Gecko 1.1.0 (not normally needed)" \
    publisher="WineHQ/Mozilla" \
    year="2010" \
    media="download" \
    file1="wine_gecko-1.1.0-x86.cab" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/gecko/1.1.0/wine_gecko/nspr4.dll"

load_gecko110()
{
    w_skip_windows gecko110 && return

    w_warn "You should probably not be using the gecko110 verb, see http://wiki.winehq.org/Gecko"
    case `$WINE --version` in
        wine-1.3.[2-9]|wine-1.3.[2-9]-*|wine-1.3.1[0-5]*)
        ;;
    *)
        w_die "This verb only supports wine-1.3.2 to wine-1.3.15"
        ;;
    esac

    w_download http://downloads.sourceforge.net/project/wine/Wine%20Gecko/1.1.0/wine_gecko-1.1.0-x86.cab 1b6c637207b6f032ae8a52841db9659433482714

    mkdir -p "$W_SYSTEM32_DLLS/gecko/1.1.0"
    cd "$W_SYSTEM32_DLLS/gecko/1.1.0"
    w_try_cabextract $W_UNATTENDED_DASH_Q "$W_CACHE/gecko110/wine_gecko-1.1.0-x86.cab"

    cat > "$W_TMP"/geckopath.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\MSHTML\1.1.0]
"GeckoPath"="c:\\\\windows\\\\system32\\\\gecko\\\\1.1.0\\\\wine_gecko\\\\"
_EOF_
    w_try_regedit "$W_TMP_WIN"\\geckopath.reg

    w_try_regsvr mshtml
}

w_metadata gecko120 dlls \
    title="Gecko 1.2.0 (not normally needed)" \
    publisher="WineHQ/Mozilla" \
    year="2011" \
    media="download" \
    file1="wine_gecko-1.2.0-x86.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/gecko/1.2.0/wine_gecko/nspr4.dll"

load_gecko120()
{
    w_skip_windows gecko120 && return

    w_warn "You should probably not be using the gecko120 verb, see http://wiki.winehq.org/Gecko"
    case `$WINE --version` in
    wine-0*|wine-1.[012]*|wine-1.3|wine-1.3.[0-9]|wine-1.3.1[0-4])
        w_die "This verb only supports wine-1.3.15 and higher at the moment"
        ;;
    esac

    w_download http://downloads.sourceforge.net/project/wine/Wine%20Gecko/1.2.0/wine_gecko-1.2.0-x86.msi 6964d1877668ab7da07a60f6dcf23fb0e261a808

    w_try $WINE msiexec /i "$W_CACHE"/gecko120/wine_gecko-1.2.0-x86.msi $W_UNATTENDED_SLASH_Q
}


#----------------------------------------------------------------

w_metadata gfw dlls \
    title="MS Games For Windows Live (xlive.dll)" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="gfwlivesetupmin.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/xlive.dll"

load_gfw()
{
    # http://www.microsoft.com/games/en-us/live/pages/livejoin.aspx
    # http://www.next-gen.biz/features/should-games-for-windows-live-die
    w_download http://download.microsoft.com/download/5/5/8/55846E20-4A46-4EF8-B272-7F988BC9090A/gfwlivesetupmin.exe 6f9e0ba052c68c8b51bb0e3ce6024d0e1c7b20b2  
    
    # FIXME: Depends on .Net 20, but is it really needed? For now, skip it.
    cd "$W_CACHE"/gfw
    w_try $WINE gfwlivesetupmin.exe /nodotnet $W_UNATTENDED_SLASH_Q

    w_call msasn1
}

#----------------------------------------------------------------

w_metadata glut dlls \
    title="The glut utility library for OpenGL" \
    publisher="Mark J. Kilgard" \
    year="2001" \
    media="download" \
    file1="glut-3.7.6-bin.zip" \
    installed_file1="c:/glut-3.7.6-bin/glut32.lib"

load_glut()
{
    w_download http://www.xmission.com/~nate/glut/glut-3.7.6-bin.zip fb4731885c05b3cf2c79e85aabe8fc9949616ef4
    w_try_unzip -d "$W_DRIVE_C" "$W_CACHE"/glut/glut-3.7.6-bin.zip
    w_try cp "$W_DRIVE_C"/glut-3.7.6-bin/glut32.dll "$W_SYSTEM32_DLLS"
    w_warn "If you want to compile glut programs, add c:/glut-3.7.6-bin to LIB and INCLUDE"
}

#----------------------------------------------------------------
# um, codecs are kind of clustered here.  They probably deserve their own real category.

w_metadata allcodecs dlls \
    title="All codecs (dirac, ffdshow, icodecs, l3codecx, xvid) except wmp" \
    publisher="various" \
    year="1998-2009" \
    media="download"

load_allcodecs()
{
    w_call dirac
    w_call l3codecx
    w_call ffdshow
    w_call icodecs
    w_call xvid
}

#----------------------------------------------------------------

w_metadata dirac dlls \
    title="The Dirac directshow filter v1.0.2" \
    publisher="Dirac" \
    year="2009" \
    media="download" \
    file1="DiracDirectShowFilter-1.0.2.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Dirac/DiracDecoder.dll"

load_dirac()
{
    w_download $WINETRICKS_SOURCEFORGE/dirac/DiracDirectShowFilter-1.0.2.exe c912d30a8fa500c7841444559feb1f49301611c4

    # Avoid mfc90 not found error.  (DiracSplitter-libschroedinger.ax needs mfc90 to register itself, I think.)
    w_call vcrun2008

    cd "$W_CACHE"/dirac
    w_ahk_do "
        SetTitleMatchMode, 2
        run DiracDirectShowFilter-1.0.2.exe
        WinWait, Dirac, Welcome
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button2
            WinWait, Dirac, License
            ControlClick, Button2
            WinWait, Dirac, Location
            ControlClick, Button2
            WinWait, Dirac, Components
            ControlClick, Button2
            WinWait, Dirac, environment
            ControlCLick, Button1
            WinWait, Dirac, installed
            ControlClick, Button2
        }
        WinWaitClose
    "
}

#----------------------------------------------------------------

w_metadata ffdshow dlls \
    title="ffdshow video codecs" \
    publisher="doom9 folks" \
    year="2010" \
    media="download" \
    file1="ffdshow_beta7_rev3154_20091209.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/ffdshow/ff_liba52.dll" \
    homepage="http://ffdshow-tryout.sourceforge.net"

load_ffdshow()
{
    w_download $WINETRICKS_SOURCEFORGE/ffdshow-tryout/ffdshow_beta7_rev3154_20091209.exe 8534c31489e51df70ee9583438d6211e6f0696d0
    cd "$W_CACHE"/ffdshow
    w_try $WINE ffdshow_beta7_rev3154_20091209.exe $W_UNATTENDED_SLASH_SILENT
}

#----------------------------------------------------------------

w_metadata icodecs dlls \
    title="Indeo codecs" \
    publisher="Intel" \
    year="1998" \
    media="download" \
    file1="codinstl.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/ir50_32.dll"

load_icodecs()
{
    # Note: this codec is insecure, see
    # http://support.microsoft.com/kb/954157
    # Original source, ftp://download.intel.com/support/createshare/camerapack/codinstl.exe, had same checksum
    w_download "http://codec.alshow.co.kr/Down/codinstl.exe" 2c5d64f472abe3f601ce352dcca75b4f02996f8a

    cd "$W_CACHE"/icodecs

    w_ahk_do "
        SetTitleMatchMode, 2
        run codinstl.exe
        winwait, Welcome
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button1  ; Next
            winwait, Software License Agreement
            sleep 1000
            controlclick, Button2  ; Yes
        }
        winwait, Setup Complete
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button4  ; Finish
        }
        winwaitclose
    "

    # Work around bug in codec's installer?
    # http://support.britannica.com/other/touchthesky/win/issues/TSTUw_150.htm
    # http://appdb.winehq.org/objectManager.php?sClass=version&iId=7091
    w_try_regsvr ir50_32.dll
}

#----------------------------------------------------------------

w_metadata jet40 dlls \
    title="MS Jet 4.0 Service Pack 8" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="jet40sp8_9xnt.exe" \
    installed_file1="$W_COMMONFILES_X86_WIN/Microsoft Shared/dao/dao360.dll"

load_jet40()
{
    w_call mdac27
    w_call wsh57
    # http://support.microsoft.com/kb/239114
    # See also http://bugs.winehq.org/show_bug.cgi?id=6085
    # FIXME: "failed with error 2"
    w_download http://download.microsoft.com/download/4/3/9/4393c9ac-e69e-458d-9f6d-2fe191c51469/jet40sp8_9xnt.exe 8cd25342030857969ede2d8fcc34f3f7bcc2d6d4
    cd "$W_CACHE"/jet40
    w_try $WINE jet40sp8_9xnt.exe $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata kde apps \
    title="KDE on Windows" \
    publisher="various" \
    year="2011" \
    media="download" \
    file1="kdewin-installer-gui-0.9.8-1.exe" \
    installed_exe1="$W_PROGRAMS_WIN/kde/etc/installer.ini" \
    homepage="http://windows.kde.org" \
    unattended="no"

load_kde()
{
    w_download http://www.winkde.org/pub/kde/ports/win32/installer/kdewin-installer-gui-0.9.8-1.exe b31aaf24d23b9f289bf56aa21e1571efc6bea58a

    mkdir -p "$W_PROGRAMS_UNIX/kde"
    w_try cp "$W_CACHE"/kde/kdewin-installer-gui-0.9.8-1.exe "$W_PROGRAMS_UNIX/kde"
    cd "$W_PROGRAMS_UNIX/kde"
    # There's no unattended option, probably because there are so many choices,
    # it's like cygwin
    w_try $WINE kdewin-installer-gui-0.9.8-1.exe
}

#----------------------------------------------------------------

w_metadata kindle apps \
    title="Amazon Kindle" \
    publisher="Amazon" \
    year="2011" \
    media="download" \
    file1="KindleForPC-installer.exe" \
    installed_exe1="$W_PROGRAMS_WIN/Amazon/Kindle/Kindle.exe" \
    homepage="http://www.amazon.com/gp/feature.html/?docId=1000426311"

load_kindle()
{
    w_download http://kindleforpc.amazon.com/36154/KindleForPC-installer.exe aca576086de7abd1d82c211dbeeb810387e046f5
    cd "$W_CACHE"/kindle
    w_try $WINE $file1 ${W_OPT_UNATTENDED:+ /S}
    w_declare_exe "$W_PROGRAMS_WIN\\Amazon\\Kindle" Kindle.exe
}

#----------------------------------------------------------------

w_metadata l3codecx dlls \
    title="MPEG Layer-3 Audio Codec for Microsoft DirectShow" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/l3codecx.ax"

load_l3codecx()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'l3codecx.ax' "$W_TMP/dxnt.cab"

    w_try_regsvr l3codecx.ax
}

#----------------------------------------------------------------

# FIXME: installed location is
# $W_PROGRAMS_X86_WIN/Gemeinsame Dateien/System/ADO/msado26.tlb
# in German... need a variable W_COMMONFILES or something like that

w_metadata mdac27 dlls \
    title="Microsoft Data Access Components 2.7 sp1" \
    publisher="Microsoft" \
    year="2006" \
    media="manual_download" \
    file1="mdac_typ.exe" \
    installed_file1="$W_COMMONFILES_X86_WIN/System/ADO/msado26.tlb"

load_mdac27()
{
    # http://www.microsoft.com/downloads/en/details.aspx?FamilyId=9AD000F2-CAE7-493D-B0F3-AE36C570ADE8&displaylang=en
    w_download_manual http://download.cnet.com/Microsoft-Data-Access-Components-MDAC-2-7-Service-Pack-1-Refresh/3000-10250_4-10729498.html mdac_typ.exe f68594d1f578c3b47bf0639c46c11c5da161feee
    load_native_mdac
    w_set_winver nt40
    w_try $WINE "$W_CACHE"/mdac27/mdac_typ.exe ${W_OPT_UNATTENDED:+ /q /C:"setup /QNT"}
    w_unset_winver
}

#----------------------------------------------------------------

w_metadata mdac28 dlls \
    title="Microsoft Data Access Components 2.8 sp1" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="MDAC_TYP.EXE" \
    installed_file1="$W_COMMONFILES_X86_WIN/System/ADO/msado27.tlb"

load_mdac28()
{
    # http://www.microsoft.com/downloads/en/details.aspx?familyid=78cac895-efc2-4f8e-a9e0-3a1afbd5922e
    w_download http://download.microsoft.com/download/4/a/a/4aafff19-9d21-4d35-ae81-02c48dcbbbff/MDAC_TYP.EXE 4fbc272c79da59e38818924d8575accb0af776fb
    load_native_mdac
    w_set_winver win98
    cd "$W_CACHE"/mdac28
    if [ $W_UNATTENDED_SLASH_Q ]
    then
        w_try $WINE mdac_typ.exe /q /C:"setup /QNT"
    else
        w_try $WINE mdac_typ.exe
    fi
    w_unset_winver
}

#----------------------------------------------------------------

w_metadata mfc40 dlls \
    title="MS mfc40 (Microsoft Foundation Classes from Visual C++ 4.0)" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="ole2v.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/MFC40.DLL"

load_mfc40()
{
    # See http://support.microsoft.com/kb/122244
    w_download http://download.microsoft.com/download/ole/ole2v/3.5/w351/en-us/ole2v.exe c6cac71f32405ccb09c6f375e0738e6e13f073e4
    w_try_unzip -d "$W_TMP" "$W_CACHE"/mfc40/ole2v.exe
    w_try cp -f "$W_TMP"/MFC40.DLL "$W_SYSTEM32_DLLS"
}

#----------------------------------------------------------------

w_metadata mono26 dlls \
    title="Mono 2.6 (.NET compatability)" \
    publisher="Novell" \
    year="2009" \
    media="download" \
    file1="mono-2.6.7-gtksharp-2.12.10-win32-2.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Mono-2.6.7/bin/mono.dll"

load_mono26()
{
    # Load Mono, have it handle all .net requests
    w_download http://ftp.novell.com/pub/mono/archive/2.6.7/windows-installer/2/mono-2.6.7-gtksharp-2.12.10-win32-2.exe c31c06063aa82006dff2f8df22dcc6ba046afbc2
    w_try $WINE "$W_CACHE"/mono26/mono-2.6.7-gtksharp-2.12.10-win32-2.exe $W_UNATTENDED_SLASH_SILENT
}

#----------------------------------------------------------------

w_metadata mono28 dlls \
    title="Mono 2.8 (.NET compatability)" \
    publisher="Novell" \
    year="2010" \
    media="download" \
    file1="mono-2.8.2-gtksharp-2.12.10-win32-1.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Mono-2.8.2/bin/mono-2.0.dll"

load_mono28()
{
    # Load Mono, have it handle all .net requests
    w_download http://ftp.novell.com/pub/mono/archive/2.8.2/windows-installer/1/mono-2.8.2-gtksharp-2.12.10-win32-1.exe d0ee2360b6fb7f16c35b54ee67044ff22bb1487e 
    w_try $WINE "$W_CACHE"/mono28/mono-2.8.2-gtksharp-2.12.10-win32-1.exe $W_UNATTENDED_SLASH_SILENT
}

#----------------------------------------------------------------

w_metadata mono210 dlls \
    title="Mono 2.10 (.NET compatability)" \
    publisher="Novell" \
    year="2011" \
    media="download" \
    file1="mono-2.10.6-gtksharp-2.12.11-win32-1.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Mono-2.10.6/bin/mono-2.0.dll"

load_mono210()
{
    w_download http://download.mono-project.com/archive/2.10.6/windows-installer/1/mono-2.10.6-gtksharp-2.12.11-win32-1.exe da2126bdee1b6424533fb2d94c5fa295e2f15b74
    cd "$W_CACHE"/mono210
    w_try $WINE $file1 $W_UNATTENDED_SLASH_SILENT
}

#----------------------------------------------------------------

w_metadata mozillabuild apps \
    title="Mozilla build environment" \
    publisher="The Mozilla Foundation" \
    year="2010" \
    media="download" \
    file1="MozillaBuildSetup-1.5.1.exe" \
    installed_file1="c:/mozilla-build/start-l10n.bat" \
    homepage="https://wiki.mozilla.org/MozillaBuild"

load_mozillabuild()
{
    w_download http://ftp.mozilla.org/pub/mozilla.org/mozilla/libraries/win32/MozillaBuildSetup-1.5.1.exe 216c52eafe42df7559e8451f4e40a28e9c0f8133
    cd "$W_CACHE/$W_PACKAGE"
    w_try $WINE MozillaBuildSetup-1.5.1.exe $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata msasn1 dlls \
    title="MS ASN1" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="W2KSP4_EN.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msasn1.dll"

load_msasn1()
{
    # http://www.microsoft.com/downloads/details.aspx?FamilyID=1001AAF1-749F-49F4-8010-297BD6CA33A0&displaylang=en
    # FIXME: This is a huge download for a single dll.
    w_download http://download.microsoft.com/download/E/6/A/E6A04295-D2A8-40D0-A0C5-241BFECD095E/W2KSP4_EN.EXE fadea6d94a014b039839fecc6e6a11c20afa4fa8
    cd "$W_TMP"
    w_try_cabextract -F i386/msasn1.dl_ "$W_CACHE"/msasn1/W2KSP4_EN.EXE
    w_try_cabextract i386/msasn1.dl_
    w_try cp msasn1.dll "$W_SYSTEM32_DLLS"
    w_try rm -rf i386
}

#----------------------------------------------------------------

w_metadata msflxgrd dlls \
    title="MS FlexGrid Control (msflxgrd.ocx)" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="msflxgrd.cab" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/MSFlxGrd.Ocx"

load_msflxgrd()
{
    # http://msdn.microsoft.com/en-us/library/aa240864(VS.60).aspx
    # may 2011: f497c3b390cd80d5bcd1f13d5c0c68b206369aa7
    w_download http://activex.microsoft.com/controls/vb6/msflxgrd.cab f497c3b390cd80d5bcd1f13d5c0c68b206369aa7

    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/msflxgrd/msflxgrd.cab
    w_try cp -f "$W_TMP"/[Mm][Ss][Ff][Ll][Xx][Gg][Rr][Dd].[Oo][Cc][Xx] "$W_SYSTEM32_DLLS"
    w_try_regsvr MSFlxGrd.Ocx
}

#----------------------------------------------------------------

w_metadata mshflxgd dlls \
    title="MS Hierarchical FlexGrid Control (mshflxgd.ocx)" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="MSHFLXGD.CAB" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mshflxgd.ocx"

load_mshflxgd()
{
    # http://msdn.microsoft.com/en-us/library/aa240864(VS.60).aspx
    # orig: 5f9c7a81022949bfe39b50f2bbd799c448bb7377
    # Jan 2009: 7ad74e589d5eefcee67fa14e65417281d237a6b6
    # May 2009: bd8aa796e16e5f213414af78931e0379d9cbe292
    w_download http://activex.microsoft.com/controls/vb6/MSHFLXGD.CAB bd8aa796e16e5f213414af78931e0379d9cbe292

    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/mshflxgd/MSHFLXGD.CAB
    w_try cp -f "$W_TMP"/[Mm][Ss][Hh][Ff][Ll][Xx][Gg][Dd].[Oo][Cc][Xx] "$W_SYSTEM32_DLLS"
    w_try_regsvr mshflxgd.ocx
}

#----------------------------------------------------------------

w_metadata msi2 dlls \
    title="Windows Installer 2.0" \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="InstMsiA.exe" \
    installed_exe1="$W_SYSTEM32_DLLS_WIN/msiexec.exe"

load_msi2()
{
    # Install native msi per http://wiki.winehq.org/NativeMsi
    # http://www.microsoft.com/downloads/details.aspx?displaylang=en&FamilyID=CEBBACD8-C094-4255-B702-DE3BB768148F
    w_download http://download.microsoft.com/download/WindowsInstaller/Install/2.0/W9XMe/EN-US/InstMsiA.exe e739c40d747e7c27aacdb07b50925b1635ee7366

    # Pick win98 so we can install native msi
    w_set_winver win98

    # Avoid "err:setupapi:SetupDefaultQueueCallbackA copy error 5 ..."
    rm -f "$W_SYSTEM32_DLLS"/msi.dll
    rm -f "$W_SYSTEM32_DLLS"/msiexec.exe

    # Avoid "instMSIA.exe returned status 20.  Aborting."
    if w_workaround_wine_bug 26816 "Removing fake mspatcha to skip version check" ,1.3.16
    then
        rm -f "$W_SYSTEM32_DLLS"/mspatcha.dll
    fi

    cd "$W_CACHE"/msi2
    WINEDLLOVERRIDES="msi,msiexec.exe=n" w_try $WINE InstMSIA.exe $W_UNATTENDED_SLASH_Q

    w_override_dlls native,builtin msi msiexec.exe

    # and undo version win98
    w_unset_winver
}

#----------------------------------------------------------------

w_metadata msscript dlls \
    title="MS Windows Script Control" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="sct10en.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msscript.ocx"

load_msscript()
{
    # http://msdn.microsoft.com/scripting/scriptcontrol/x86/sct10en.exe
    # http://www.microsoft.com/downloads/details.aspx?familyid=d7e31492-2595-49e6-8c02-1426fec693ac
    w_download http://download.microsoft.com/download/d/2/a/d2a7430c-6d5b-48e9-96c4-3c751be7bffe/sct10en.exe fd9f2f23357ab11ae70682d6864f7e9f188adf2a

    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/msscript/sct10en.exe
    w_try cp -f "$W_TMP"/msscript.ocx "$W_SYSTEM32_DLLS"
    w_try_regsvr msscript.ocx
}
#----------------------------------------------------------------

w_metadata msls31 dlls \
    title="MS Line Services" \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="../msi2/InstMsiA.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msls31.dll"

load_msls31()
{
    # Needed by native richedit and internet explorer
    w_download http://download.microsoft.com/download/WindowsInstaller/Install/2.0/W9XMe/EN-US/InstMsiA.exe e739c40d747e7c27aacdb07b50925b1635ee7366
    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/msls31/InstMsiA.exe
    w_try cp -f "$W_TMP"/msls31.dll "$W_SYSTEM32_DLLS"
}

#----------------------------------------------------------------

w_metadata msmask dlls \
    title="MS Masked Edit Control" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="MSMASK32.CAB" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msmask32.ocx"

load_msmask()
{
    # http://msdn.microsoft.com/en-us/library/11405hcf(VS.71).aspx
    # http://bugs.winehq.org/show_bug.cgi?id=2934
    # old: 3c6b26f68053364ea2e09414b615dbebafb9d5c3
    # May 2009: 30e55679e4a13fe4d9620404476f215f93239292
    w_download http://activex.microsoft.com/controls/vb6/MSMASK32.CAB 30e55679e4a13fe4d9620404476f215f93239292
    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/msmask/MSMASK32.CAB
    w_try cp -f "$W_TMP"/[Mm][Ss][Mm][Aa][Ss][Kk]32.[Oo][Cc][Xx] "$W_SYSTEM32_DLLS"/msmask32.ocx
    w_try_regsvr msmask32.ocx
}

#----------------------------------------------------------------

w_metadata msxml3 dlls \
    title="MS XML Core Services 3.0" \
    publisher="Microsoft" \
    year="2005" \
    media="manual_download" \
    file1="msxml3.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msxml3.dll"

load_msxml3()
{
    # Service Pack 5
    #w_download http://download.microsoft.com/download/a/5/e/a5e03798-2454-4d4b-89a3-4a47579891d8/msxml3.msi
    # Service Pack 7
    #w_download http://download.microsoft.com/download/8/8/8/888f34b7-4f54-4f06-8dac-fa29b19f33dd/msxml3.msi d4c2178dfb807e1a0267fce0fd06b8d51106d913
    # Hmm.  Anyone know of a better source?  At least it has the right checksum.
    w_download_manual http://download.cnet.com/Microsoft-XML-Parser-MSXML-3-0-Service-Pack-7-SP7/3000-7241_4-10731613.html msxml3.msi d4c2178dfb807e1a0267fce0fd06b8d51106d913

    # it won't install on top of wine's msxml3, which has a pretty high version number, so delete wine's fake dll
    rm "$W_SYSTEM32_DLLS"/msxml3.dll
    w_override_dlls native msxml3
    cd "$W_CACHE"/msxml3
    w_try $WINE msiexec /i msxml3.msi $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata msxml4 dlls \
    title="MS XML Core Services 4.0" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="msxml.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msxml4.dll"

load_msxml4()
{
    # MS06-071: http://www.microsoft.com/downloads/details.aspx?familyid=24B7D141-6CDF-4FC4-A91B-6F18FE6921D4
    # w_download http://download.microsoft.com/download/e/2/e/e2e92e52-210b-4774-8cd9-3a7a0130141d/msxml4-KB927978-enu.exe d364f9fe80c3965e79f6f64609fc253dfeb69c25
    # MS07-042: http://www.microsoft.com/downloads/details.aspx?FamilyId=021E12F5-CB46-43DF-A2B8-185639BA2807
    # w_download http://download.microsoft.com/download/9/4/2/9422e6b6-08ee-49cb-9f05-6c6ee755389e/msxml4-KB936181-enu.exe 73d75d7b41f8a3d49f272e74d4f73bb5e82f1acf
    # SP3 (2009): http://www.microsoft.com/downloads/details.aspx?familyid=7F6C0CB4-7A5E-4790-A7CF-9E139E6819C0
    w_download http://download.microsoft.com/download/A/2/D/A2D8587D-0027-4217-9DAD-38AFDB0A177E/msxml.msi aa70c5c1a7a069af824947bcda1d9893a895318b
    w_override_dlls native,builtin msxml4
    cd "$W_CACHE"/msxml4
    w_try $WINE msiexec /i msxml.msi $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata msxml6 dlls \
    title="MS XML Core Services 6.0 sp1" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="msxml6_x86.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msxml6.dll"

load_msxml6()
{
    # Service Pack 1
    # http://www.microsoft.com/downloads/details.aspx?familyid=D21C292C-368B-4CE1-9DAB-3E9827B70604
    w_download http://download.microsoft.com/download/e/a/f/eafb8ee7-667d-4e30-bb39-4694b5b3006f/msxml6_x86.msi 5125220e985b33c946bbf9f60e2b222c7570bfa2
    w_override_dlls native,builtin msxml6
    rm -f "$W_SYSTEM32_DLLS/msxml6.dll"
    w_try $WINE msiexec /i "$W_CACHE"/msxml6/msxml6_x86.msi $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata ogg dlls \
    title="OpenCodecs 0.85: flac, speex, theora, vorbis, WebM" \
    publisher="xiph.org" \
    year="2011" \
    media="download" \
    file1="opencodecs_0.85.17777.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Xiph.Org/Open Codecs/AxPlayer.dll" \
    homepage="http://xiph.org/dshow"

load_ogg()
{
    w_download http://downloads.xiph.org/releases/oggdsf/opencodecs_0.85.17777.exe 386cf7cd29ffcbf8705eff8c8233de448ecf33ab
    cd "$W_CACHE"/ogg
    w_try $WINE $file1 $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata openwatcom apps \
    title="Open Watcom C/C++ compiler (can compile win16 code!)" \
    publisher="Watcom" \
    year="2010" \
    media="download" \
    file1="open-watcom-c-win32-1.9.exe" \
    installed_file1="c:/WATCOM/owsetenv.bat" \
    homepage="http://www.openwatcom.org"

load_openwatcom()
{
    w_download "http://ftp.openwatcom.org/ftp/open-watcom-c-win32-1.9.exe" 236ac33ebd463006be4ecd83d7ebea1c026eb55a

    if [ $W_UNATTENDED_SLASH_Q ]
    then
        # Options documented at http://bugzilla.openwatcom.org/show_bug.cgi?id=898
        # But they don't seem to work on wine, so jam them into setup.inf
        # Pick smallest installation that supports 16 bit C and C++
        cd "$W_TMP"
        cp "$W_CACHE"/openwatcom/open-watcom-c-win32-1.9.exe .
        w_try_unzip open-watcom-c-win32-1.9.exe setup.inf
        sed -i 's/tools16=.*/tools16=true/' setup.inf
        w_try zip -f open-watcom-c-win32-1.9.exe
        w_try $WINE open-watcom-c-win32-1.9.exe -s
    else
        cd "$W_CACHE/$W_PACKAGE"
        w_try $WINE open-watcom-c-win32-1.9.exe
    fi

    if test ! -f "$W_DRIVE_C"/WATCOM/binnt/wcc.exe
    then
        w_warn "c:/watcom/binnt/wcc.exe not found; you probably didn't select 16 bit tools, and won't be able to buld win16test"
    fi
}

#----------------------------------------------------------------

w_metadata pdh dlls \
    title="MS pdh.dll (Performance Data Helper)" \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="pdhinst.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/pdh.dll"

load_pdh()
{
    # http://support.microsoft.com/kb/284996
    w_download http://download.microsoft.com/download/platformsdk/Redist/5.0.2195.2668/NT4/EN-US/pdhinst.exe f42448660def8cd7f42b34aa7bc7264745f4425e

    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/pdh/pdhinst.exe
    w_try_unzip -d "$W_TMP" "$W_TMP"/pdh.exe
    w_try cp -f "$W_TMP"/x86/Pdh.Dll "$W_SYSTEM32_DLLS"/pdh.dll
}

#----------------------------------------------------------------

w_metadata physx dlls \
    title="PhysX" \
    publisher="NVidia" \
    year="2010" \
    media="download" \
    file1="PhysX_9.10.0129_SystemSoftware.exe" \
    installed_file1="$W_PROGRAMS_WIN/NVIDIA Corporation/PhysX/Engine/v2.8.3/PhysXCore.dll"

load_physx()
{
    # http://www.nvidia.com/object/physx_9.09.0814.html
    # w_download http://us.download.nvidia.com/Windows/9.09.0814/PhysX_9.09.0814_SystemSoftware.exe e19f7c3385a4a68e7acb85301bb4d2d0d1eaa1e2
    # http://www.nvidia.com/object/physx_9.10.0129.html
    w_download http://us.download.nvidia.com/Windows/9.10.0129/PhysX_9.10.0129_SystemSoftware.exe 33a8b54d842c7246946de15b1a48209c386c9c4b
    cd "$W_CACHE"/physx
    w_try $WINE PhysX_9.10.0129_SystemSoftware.exe $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata pngfilt dlls \
    title="pngfilt.dll (from ie6)" \
    publisher="Microsoft" \
    year="2002" \
    media="download" \
    file1="q328970.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/pngfilt.dll"

load_pngfilt()
{
    # http://support.microsoft.com/kb/328970
    w_download http://download.microsoft.com/download/IE60/30secpac/6/W98NT42KMeXP/EN-US/q328970.exe 5fd84a335c43d194c0138a091dc0ea151ecc331c
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F pngfilt.dll "$W_CACHE"/pngfilt/q328970.exe
    w_try_regsvr pngfilt.dll
}

#----------------------------------------------------------------

w_metadata quartz dlls \
    title="quartz.dll (from Directx 9 user redistributable)" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/quartz.dll"

load_quartz()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F quartz.dll "$W_TMP/dxnt.cab"

    w_try_regsvr quartz.dll

    w_override_dlls native quartz
}

#----------------------------------------------------------------

w_metadata quicktime72 dlls \
    title="Apple Quicktime 7.2" \
    publisher="Apple" \
    year="2010" \
    media="download" \
    file1="quicktimeplayer72.exe" \
    installed_file1="c:/windows/Installer/{95A890AA-B3B1-44B6-9C18-A8F7AB3EE7FC}/QTPlayer.ico"

load_quicktime72()
{
    # http://www.apple.com/support/downloads/quicktime72forwindows.html
    # http://www.oldapps.com/quicktime_player.php?old_quicktime=6
    w_download http://download.oldapps.com/Quicktime/quicktimeplayer72.exe bb89981f10cf21de57b9453e53cf81b9194271a9

    unset QUICKTIME_QUIET
    if test "$W_UNATTENDED_SLASH_Q" != ""
    then
        QUICKTIME_QUIET="/qn"  # ISSETUPDRIVEN=0
    fi

    if w_workaround_wine_bug 9366 ""  1.1.22,
    then
        w_call gdiplus
        w_call vcrun2005      # no bug number, but same era
    fi

    if w_workaround_wine_bug 1347
    then
        w_warn "Setting vista mode to avoid blacking the whole screen in quicktime"
        w_set_winver vista
    fi

    cd "$W_CACHE"/quicktime72
    w_try $WINE quicktimeplayer72.exe ALLUSERS=1 DESKTOP_SHORTCUTS=0 QTTaskRunFlags=0 QTINFO.BISQTPRO=1 SCHEDULE_ASUW=0 REBOOT_REQUIRED=No $QUICKTIME_QUIET > /dev/null 2>&1

    if w_workaround_wine_bug 11681
    then
        # Following advice verified with test movies from 
        # http://support.apple.com/kb/HT1425
        # in QuickTimePlayer.

        w_warn "In Quicktime preferences, check Advanced / Safe Mode (gdi), or movies won't play."
        if test "$W_UNATTENDED_SLASH_Q" = ""
        then
            w_try $WINE control "$W_PROGRAMS_WIN\\QuickTime\\QTSystem\\QuickTime.cpl"
        else
            # FIXME: script the control panel with autohotkey?
            # We could probably also overwrite QuickTime.qtp but
            # the format isn't known, so we'd have to override all other settings, too.
            :
        fi
    fi
}

#----------------------------------------------------------------

w_metadata quicktime76 dlls \
    title="Apple Quicktime 7.6" \
    publisher="Apple" \
    year="2010" \
    media="download" \
    file1="QuickTimeInstaller.exe" \
    installed_file1="c:/windows/Installer/{57752979-A1C9-4C02-856B-FBB27AC4E02C}/QTPlayer.ico"

load_quicktime76()
{
    # http://www.apple.com/quicktime/download/
    w_download http://appldnld.apple.com/QuickTime/041-0025.20101207.Ptrqt/QuickTimeInstaller.exe 1eec8904f041d9e0ad3459788bdb690e45dbc38e

    unset QUICKTIME_QUIET
    if test "$W_UNATTENDED_SLASH_Q"
    then
        QUICKTIME_QUIET="/qn"  # ISSETUPDRIVEN=0
    fi

    if w_workaround_wine_bug 9366 ""  1.1.22,
    then
        w_call gdiplus
        w_call vcrun2005      # no bug number, but same era
    fi

    if w_workaround_wine_bug 1347
    then
        w_warn "Setting vista mode to avoid blacking the whole screen in quicktime"
        w_set_winver vista
    fi

    cd "$W_CACHE"/quicktime76
    w_try $WINE QuickTimeInstaller.exe ALLUSERS=1 DESKTOP_SHORTCUTS=0 QTTaskRunFlags=0 QTINFO.BISQTPRO=1 SCHEDULE_ASUW=0 REBOOT_REQUIRED=No $QUICKTIME_QUIET > /dev/null 2>&1

    if w_workaround_wine_bug 11681
    then
        # Following advice verified with test movies from 
        # http://support.apple.com/kb/HT1425
        # in QuickTimePlayer.

        w_warn "In Quicktime preferences, check Advanced / Safe Mode (gdi), or movies won't play."
        if test "$W_UNATTENDED_SLASH_Q" = ""
        then
            w_try $WINE control "$W_PROGRAMS_WIN\\QuickTime\\QTSystem\\QuickTime.cpl"
        else
            # FIXME: script the control panel with autohotkey?
            # We could probably also overwrite QuickTime.qtp but
            # the format isn't known, so we'd have to override all other settings, too.
            :
        fi
    fi
}
#----------------------------------------------------------------

w_metadata riched20 dlls \
    title="MS RichEdit Control version 2.0 (riched20.dll, riched32.dll)" \
    publisher="Microsoft" \
    year="1999" \
    media="download" \
    file1="Q249973i.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/riched20.dll"

load_riched20()
{
    # http://support.microsoft.com/?kbid=249973
    w_download http://download.microsoft.com/download/winntsp/Patch/RTF/NT4/EN-US/Q249973i.EXE f0b7663f15dbd31410435483ba832318c7a70470
    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/riched20/Q249973i.EXE
    w_try cp -f "$W_TMP"/riched??.dll "$W_SYSTEM32_DLLS"
    w_override_dlls native,builtin riched20 riched32
}

#----------------------------------------------------------------

# Problem - riched20 and riched30 both install riched20.dll!
# We may need a better way to distinguish between installed files.

w_metadata riched30 dlls \
    title="MS RichEdit Control version 3.0 (riched20.dll, msls31.dll)" \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="InstMsiA.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/riched20.dll" \
    installed_file2="$W_SYSTEM32_DLLS_WIN/msls31.dll"

load_riched30()
{
    # http://www.novell.com/documentation/nm1/readmeen_web/readmeen_web.html#Akx3j64
    # claims that Groupwise Messenger's View / Text Size command
    # only works with riched30, and recommends getting it by installing
    # msi 2, which just happens to come with riched30 version of riched20
    # (though not with a corresponding riched32, which might be a problem)
    # http://www.microsoft.com/downloads/details.aspx?displaylang=en&FamilyID=CEBBACD8-C094-4255-B702-DE3BB768148F
    w_download http://download.microsoft.com/download/WindowsInstaller/Install/2.0/W9XMe/EN-US/InstMsiA.exe e739c40d747e7c27aacdb07b50925b1635ee7366
    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/riched30/InstMsiA.exe
    w_try cp -f "$W_TMP"/riched20.dll "$W_SYSTEM32_DLLS"
    w_try cp -f "$W_TMP"/msls31.dll "$W_SYSTEM32_DLLS"
    w_override_dlls native,builtin riched30
}

#----------------------------------------------------------------

w_metadata richtx32 dlls \
    title="MS Rich TextBox Control 6.0" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="richtx32.cab" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/RichTx32.Ocx"

load_richtx32()
{
    w_download http://activex.microsoft.com/controls/vb6/richtx32.cab da404b566df3ad74fe687c39404a36c3e7cadc07
    w_try_cabextract "$W_CACHE"/richtx32/richtx32.cab -d "$W_SYSTEM32_DLLS" -F RichTx32.ocx
    w_try_regsvr RichTx32.ocx
}

#----------------------------------------------------------------

w_metadata secur32 dlls \
    title="MS Security Support Provider Interface" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="Windows2000-KB959426-x86-ENU.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/secur32.dll"

load_secur32()
{
    # http://www.microsoft.com/downloads/details.aspx?familyid=c4e408d7-6716-4a12-ad3a-8029667f5c84
    w_download http://download.microsoft.com/download/6/9/5/69501788-B62F-44D8-933F-B6FAA576CA87/Windows2000-KB959426-x86-ENU.EXE bf930a4d2982165a0793465bb255d494ba5b4cf7
    w_try_cabextract "$W_CACHE"/secur32/Windows2000-KB959426-x86-ENU.EXE -d "$W_SYSTEM32_DLLS" -F secur32.dll
    w_override_dlls native,builtin secur32
}

#----------------------------------------------------------------

w_metadata shockwave dlls \
    title="Shockwave" \
    publisher="Adobe" \
    year="2010" \
    media="download" \
    file1="sw_lic_full_installer.msi" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/Adobe/Shockwave 11/shockwave_Projector_Loader.dcr"

load_shockwave() {
    # Not silent enough, use msi instead
    #w_download http://fpdownload.macromedia.com/get/shockwave/default/english/win95nt/latest/Shockwave_Installer_Full.exe 840e34e9b067cf247bfa9092665b8966158f38e3
    #w_try $WINE "$W_CACHE"/Shockwave_Installer_Full.exe $W_UNATTENDED_SLASH_S
    # old sha1sum: 6a91a9da4b54c3fdc97130a15e1a173117e5f4ff
    # 2009-07-31 sha1sum: 0bb506ef67a268e8d3fb6c7ce556320ee10b9da5
    # 2009-12-13 sha1sum: d35649883bf13cb1a86f5650e1050d15533ac0f4
    # 2010-01-23 sha1sum: 4a837d238c28c5f345d73f105711f20c6d059273
    # 2010-05-15 sha1sum: bdce02afc82233801e84137e78c2c5fe574db253
    # 2010-09-02 sha1sum: fed20eccc29fec2f64162b7265343514d43884bc
    # 2010-11-03 sha1sum: 2ff28665543e80f3bd4ff1933ac05ec9314aaac6
    # 2011-02-03 sha1sum: e71ddc4fa42662208b2f52c1bd34a40e7775ad75
    # 2011-06-13 sha1sum: 7fd6cc61bb20d0bef654a44f4501a5a65b55b0c9
    # 2011-11-10 sha1sum: b55974b471c516f13fb032424247c07390baf380

    w_download http://fpdownload.macromedia.com/get/shockwave/default/english/win95nt/latest/sw_lic_full_installer.msi b55974b471c516f13fb032424247c07390baf380
    cd "$W_CACHE"/shockwave
    w_try $WINE msiexec /i sw_lic_full_installer.msi $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata speechsdk dlls \
    title="MS Speech SDK 5.1" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="SpeechSDK51.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Microsoft Speech SDK 5.1/Bin/SAPI51SampleApp.exe"

load_speechsdk()
{
    # http://www.microsoft.com/download/en/details.aspx?id=10121
    w_download http://download.microsoft.com/download/B/4/3/B4314928-7B71-4336-9DE7-6FA4CF00B7B3/SpeechSDK51.exe f69efaee8eb47f8c7863693e8b8265a3c12c4f51

    w_try_unzip -d "$W_TMP" "$W_CACHE"/speechsdk/SpeechSDK51.exe

    # Otherwise it only installs the SDK and not the redistributable:
    w_set_winver win2k
    
    cd "$W_TMP"
    w_try $WINE msiexec /i "Microsoft Speech SDK 5.1.msi" $W_UNATTENDED_SLASH_Q

    w_unset_winver
}

#----------------------------------------------------------------

w_metadata usp10 dlls \
    title="Uniscribe 1.325 " \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="../msi2/InstMsiA.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/usp10.dll"

load_usp10()
{
    # http://en.wikipedia.org/wiki/Uniscribe
    # http://www.microsoft.com/downloads/details.aspx?familyid=cebbacd8-c094-4255-b702-de3bb768148f
    w_download_to msi2 http://download.microsoft.com/download/WindowsInstaller/Install/2.0/W9XMe/EN-US/InstMsiA.exe e739c40d747e7c27aacdb07b50925b1635ee7366
    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/msi2/InstMsiA.exe
    w_try cp -f "$W_TMP"/usp10.dll "$W_SYSTEM32_DLLS"
    w_override_dlls native,builtin usp10
}

#----------------------------------------------------------------

w_metadata vb2run dlls \
    title="MS Visual Basic 2 runtime" \
    publisher="Microsoft" \
    year="1993" \
    media="download" \
    file1="VBRUN200.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/VBRUN200.DLL"

load_vb2run()
{
    # Not referenced on MS web anymore, but the old Microsoft Software Library FTP still has it.
    # See ftp://ftp.microsoft.com/Softlib/index.txt
    w_download ftp://ftp.microsoft.com/Softlib/MSLFILES/VBRUN200.EXE ac0568b73ee375408778e9b505df995f79ab907e
    w_try_unzip -d "$W_TMP" "$W_CACHE"/vb2run/VBRUN200.EXE
    w_try cp -f "$W_TMP/VBRUN200.DLL" "$W_SYSTEM32_DLLS"
}

#----------------------------------------------------------------

w_metadata vb3run dlls \
    title="MS Visual Basic 3 runtime" \
    publisher="Microsoft" \
    year="1998" \
    media="download" \
    file1="vb3run.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/Vbrun300.dll"

load_vb3run()
{
    # See http://support.microsoft.com/kb/196285
    w_download http://download.microsoft.com/download/vb30/utility/1/w9xnt4/en-us/vb3run.exe 518fcfefde9bf680695cadd06512efadc5ac2aa7
    w_try_unzip -d "$W_TMP" "$W_CACHE"/vb3run/vb3run.exe
    w_try cp -f "$W_TMP/Vbrun300.dll" "$W_SYSTEM32_DLLS"
}

#----------------------------------------------------------------

w_metadata vb4run dlls \
    title="MS Visual Basic 4 runtime" \
    publisher="Microsoft" \
    year="1998" \
    media="download" \
    file1="vb4run.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/Vb40032.dll"

load_vb4run()
{
    # See http://support.microsoft.com/kb/196286
    w_download http://download.microsoft.com/download/vb40ent/sample27/1/w9xnt4/en-us/vb4run.exe 83e968063272e97bfffd628a73bf0ff5f8e1023b
    w_try_unzip -d "$W_TMP" "$W_CACHE"/vb4run/vb4run.exe
    w_try cp -f "$W_TMP/Vb40032.dll" "$W_SYSTEM32_DLLS"
    w_try cp -f "$W_TMP/Vb40016.dll" "$W_SYSTEM32_DLLS"
}

#----------------------------------------------------------------

w_metadata vb5run dlls \
    title="MS Visual Basic 5 runtime" \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="msvbvm50.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msvbvm50.dll"

load_vb5run()
{
    w_download http://download.microsoft.com/download/vb50pro/utility/1/win98/en-us/msvbvm50.exe 28bfaf09b8ac32cf5ffa81252f3e2fadcb3a8f27
    cd "$W_CACHE"/vb5run
    w_try $WINE msvbvm50.exe $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata vb6run dlls \
    title="MS Visual Basic 6 runtime sp6" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="vbrun60sp6.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/MSVBVM60.DLL"

load_vb6run()
{
    # http://support.microsoft.com/kb/290887
    if test ! -f "$W_CACHE"/vb6run/vbrun60sp6.exe
    then
        w_download http://download.microsoft.com/download/5/a/d/5ad868a0-8ecd-4bb0-a882-fe53eb7ef348/VB6.0-KB290887-X86.exe 73ef177008005675134d2f02c6f580515ab0d842

        w_try $WINE "$W_CACHE"/vb6run/VB6.0-KB290887-X86.exe "/T:$W_TMP_WIN" /c $W_UNATTENDED_SLASH_Q
        if test ! -f "$W_TMP"/vbrun60sp6.exe
        then
            w_die vbrun60sp6.exe not found
        fi
        w_try mv "$W_TMP"/vbrun60sp6.exe "$W_CACHE"/vb6run
    fi

    # Delete some fake DLLs to ensure that the installer overwrites them.
    rm -f "$W_SYSTEM32_DLLS"/comcat.dll
    rm -f "$W_SYSTEM32_DLLS"/oleaut32.dll
    rm -f "$W_SYSTEM32_DLLS"/olepro32.dll
    rm -f "$W_SYSTEM32_DLLS"/stdole2.tlb

    cd "$W_CACHE"/vb6run
    # Exits with status 43 for some reason?
    $WINE vbrun60sp6.exe $W_UNATTENDED_SLASH_Q

    status=$?
    case $status in
    0|43) ;;
    *) w_die $W_PACKAGE installation failed
    esac
}

#----------------------------------------------------------------

winetricks_vcrun6_helper() {
    if test ! -f "$W_CACHE"/vcrun6/vcredist.exe
    then
        w_download_to vcrun6 http://download.microsoft.com/download/vc60pro/update/1/w9xnt4/en-us/vc6redistsetup_enu.exe 382c8f5a7f41189af8d4165cf441f274b7e2a457

        w_try $WINE "$W_CACHE"/vcrun6/vc6redistsetup_enu.exe "/T:$W_TMP_WIN" /c $W_UNATTENDED_SLASH_Q
        if test ! -f "$W_TMP"/vcredist.exe
        then
            w_die vcredist.exe not found
        fi
        mv "$W_TMP"/vcredist.exe "$W_CACHE"/vcrun6
    fi
}

w_metadata vcrun6 dlls \
    title="Visual C++ 6 sp4 libraries (mfc42, msvcp60, msvcrt)" \
    publisher="Microsoft" \
    year="2000" \
    media="download" \
    file1="vc6redistsetup_enu.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msvcrt.dll"

load_vcrun6()
{
    # Load the Visual C++ 6 runtime libraries, including the elusive mfc42u.dll
    winetricks_vcrun6_helper

    # Delete some fake dlls to avoid vcredist installer warnings
    rm -f "$W_SYSTEM32_DLLS"/comcat.dll
    rm -f "$W_SYSTEM32_DLLS"/msvcrt.dll
    rm -f "$W_SYSTEM32_DLLS"/oleaut32.dll
    rm -f "$W_SYSTEM32_DLLS"/olepro32.dll
    rm -f "$W_SYSTEM32_DLLS"/stdole2.tlb
    $WINE "$W_CACHE"/vcrun6/vcredist.exe

    status=$?
    case $status in
    0|43) ;;
    *) w_die vcrun6 installation failed
    esac

    # And then some apps need mfc42u.dll, dunno what right way
    # is to get it, vcredist doesn't install it by default?
    load_mfc42

    w_override_dlls native,builtin msvcrt
}

w_metadata mfc42 dlls \
    title="Visual C++ 6 sp4 mfc42 library (mfc42); same as vcrun6" \
    publisher="Microsoft" \
    year="2000" \
    media="download" \
    file1="../vcrun6/vc6redistsetup_enu.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mfc42u.dll"

load_mfc42()
{
    winetricks_vcrun6_helper

    w_try_cabextract "$W_CACHE"/vcrun6/vcredist.exe -d "$W_SYSTEM32_DLLS" -F "mfc42*.dll"
}

#----------------------------------------------------------------

# FIXME: we don't currently have an install check that can distinguish
# between sp4 and sp6, it would have to check size or version of a file,
# or maybe a registry key.

w_metadata vcrun6sp6 dlls \
    title="Visual C++ 6 sp6 libraries (with fixes in atl and mfc)" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="Vs6sp6.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msvcrt.dll"

load_vcrun6sp6()
{
    w_download http://download.microsoft.com/download/1/9/f/19fe4660-5792-4683-99e0-8d48c22eed74/Vs6sp6.exe 2292437a8967349261c810ae8b456592eeb76620

    # No EULA is presented when passing command-line extraction arguments,
    # so we'll simplify extraction with cabextract.
    w_try_cabextract "$W_CACHE"/vcrun6sp6/Vs6sp6.exe -d "$W_TMP" -F vcredist.exe
    cd "$W_TMP"

    # Delete some fake dlls to avoid vcredist installer warnings
    w_try rm -f "$W_SYSTEM32_DLLS"/comcat.dll
    w_try rm -f "$W_SYSTEM32_DLLS"/msvcrt.dll
    w_try rm -f "$W_SYSTEM32_DLLS"/oleaut32.dll
    w_try rm -f "$W_SYSTEM32_DLLS"/olepro32.dll
    w_try rm -f "$W_SYSTEM32_DLLS"/stdole2.tlb
    # vcredist still exits with status 43.  Anyone know why?
    $WINE vcredist.exe

    status=$?
    case $status in
    0|43) ;;
    *) w_die $W_PACKAGE installation failed
    esac

    # And then some apps need mfc42u.dll, dunno what right way
    # is to get it, vcredist doesn't install it by default?
    w_try_cabextract vcredist.exe -d "$W_SYSTEM32_DLLS" -F mfc42u.dll
    # Should the mfc42 verb install this one instead?

    w_override_dlls native,builtin msvcrt
}

#----------------------------------------------------------------

w_metadata vcrun2003 dlls \
    title="Visual C++ 2003 libraries (mfc71,msvcp71,msvcr71)" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="BZEditW32_1.6.5_Installer.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/msvcp71.dll"

load_vcrun2003()
{
    # Load the Visual C++ 2003 runtime libraries
    # Sadly, I know of no Microsoft URL for these
    echo "Installing BZFlag (which comes with the Visual C++ 2003 runtimes)"
    w_download $WINETRICKS_SOURCEFORGE/bzflag/BZEditW32_1.6.5_Installer.exe bdd1b32c4202fd77e6513fd507c8236888b09121
    w_try $WINE "$W_CACHE"/vcrun2003/BZEditW32_1.6.5_Installer.exe $W_UNATTENDED_SLASH_S
    w_try cp "$W_PROGRAMS_X86_UNIX/BZEdit1.6.5"/m*71* "$W_SYSTEM32_DLLS"
}

#----------------------------------------------------------------

w_metadata vcrun2005 dlls \
    title="Visual C++ 2005 libraries (mfc80,msvcp80,msvcr80)" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="vcredist_x86.EXE" \
    installed_file1="c:/windows/winsxs/x86_Microsoft.VC80.MFC_1fc8b3b9a1e18e3b_8.0.50727.6195_x-ww_150c9e8b/mfc80.dll"

load_vcrun2005()
{
    # June 2011 security update, see 
    # http://www.microsoft.com/technet/security/bulletin/MS11-025.mspx or
    # http://support.microsoft.com/kb/2538242
    w_download http://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE b8fab0bb7f62a24ddfe77b19cd9a1451abd7b847

    cd "$W_CACHE"/vcrun2005
    w_override_dlls native,builtin msvcr80
    w_try $WINE $file1 $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata vcrun2008 dlls \
    title="Visual C++ 2008 libraries (mfc90,msvcp90,msvcr90)" \
    publisher="Microsoft" \
    year="2011" \
    media="download" \
    file1="vcredist_x86.exe" \
    installed_file1="C:/windows/winsxs/x86_Microsoft.VC90.MFC_1fc8b3b9a1e18e3b_9.0.30729.6161_x-ww_028bc148/mfc90.dll"

load_vcrun2008()
{
    # June 2011 security update, see 
    # http://www.microsoft.com/technet/security/bulletin/MS11-025.mspx or
    # http://support.microsoft.com/kb/2538242
    w_download http://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe 470640aa4bb7db8e69196b5edb0010933569e98d
    w_override_dlls native,builtin msvcr90
    cd "$W_CACHE"/vcrun2008
    w_try $WINE $file1 $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata vcrun2010 dlls \
    title="Visual C++ 2010 libraries (mfc100,msvcp100,msvcr100)" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="vcredist_x86.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/mfc100.dll"

load_vcrun2010()
{
    # See http://www.microsoft.com/downloads/details.aspx?FamilyID=a7b7a05e-6de6-4d3a-a423-37bf0912db84
    w_download http://download.microsoft.com/download/5/B/C/5BC5DBB3-652D-4DCE-B14A-475AB85EEF6E/vcredist_x86.exe 372d9c1670343d3fb252209ba210d4dc4d67d358

    if w_workaround_wine_bug 23427 ""  1.3.5,
    then
        w_call msxml3
    fi

    w_override_dlls native,builtin msvcr100
    cd "$W_CACHE"/vcrun2010
    w_try $WINE vcredist_x86.exe $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata vjrun20 dlls \
    title="MS Visual J# 2.0 SE libraries (requires dotnet20)" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="vjredist.exe" \
    installed_file1="c:/windows/Microsoft.NET/Framework/VJSharp/VJSharpSxS10.dll"

load_vjrun20()
{
    if [ $W_ARCH = win64 ]
    then
        w_warn "vjrun20 depends on dotnet20, which doesn't work on 64-bit wine yet. Skipping."
        return
    fi

    w_call dotnet20

    # See http://www.microsoft.com/downloads/details.aspx?FamilyId=E9D87F37-2ADC-4C32-95B3-B5E3A21BAB2C
    w_download http://download.microsoft.com/download/9/2/3/92338cd0-759f-4815-8981-24b437be74ef/vjredist.exe 80a098e36b90d159da915aebfbfbacf35f302bd8

    if [ $W_UNATTENDED_SLASH_Q ]
    then
        w_try $WINE "$W_CACHE"/vjrun20/vjredist.exe /q /C:"install /QNT"
    else
        w_try $WINE "$W_CACHE"/vjrun20/vjredist.exe
    fi
}

#----------------------------------------------------------------

w_metadata windowscodecs dlls \
    title="MS Windows Imaging Component" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="wic_x86_enu.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/WindowsCodecs.dll"

load_windowscodecs()
{
    w_download http://download.microsoft.com/download/f/f/1/ff178bb1-da91-48ed-89e5-478a99387d4f/wic_x86_enu.exe 53c18652ac2f8a51303deb48a1b7abbdb1db427f

    # Avoid a file existence check.
    w_try rm -f "$W_SYSTEM32_DLLS"/windowscodecs.dll
    w_override_dlls native,builtin windowscodecs

    # Always run the WIC installer in passive mode.
    # See http://bugs.winehq.org/show_bug.cgi?id=16876 and
    # http://bugs.winehq.org/show_bug.cgi?id=23232
    cd "$W_CACHE/$W_PACKAGE"
    w_try $WINE wic_x86_enu.exe /passive
}

#----------------------------------------------------------------

w_metadata winhttp dlls \
    title="MS Windows HTTP Services" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="Windows2000-KB842773-x86-ENU.EXE" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/winhttp.dll"

load_winhttp()
{
    # See https://www.microsoft.com/downloads/en/details.aspx?FamilyID=3ee866a0-3a09-4fdf-8bdb-c906850ab9f2
    w_download http://download.microsoft.com/download/5/d/8/5d802926-6bab-45fa-b96e-bee15413523b/Windows2000-KB842773-x86-ENU.EXE e676d47e065a314bbf1d15b096a67aede6b0539a
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F winhttp.dll "$W_CACHE"/winhttp/Windows2000-KB842773-x86-ENU.EXE
    w_override_dlls native,builtin winhttp
}

#----------------------------------------------------------------

w_metadata wininet dlls \
    title="MS Windows Internet API" \
    publisher="Microsoft" \
    year="1999" \
    media="download" \
    file1="3725.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/wininet.dll"

load_wininet()
{
    # This is an updated wininet from IE 5.0.1.
    # (Good enough for Active Worlds browser.  Also helps "Avatar - Legends of the Arena" get to login screen.)
    # See http://www.microsoft.com/downloads/details.aspx?familyid=6DEE32AB-B618-4FB3-9A45-CDD08162E167
    w_download http://download.microsoft.com/download/ie5/Update/1/WIN98/EN-US/3725.exe b048e0b4e303298de3317b16f7008c43ca71ddfe
    w_try_cabextract --directory="$W_TMP" "$W_CACHE/wininet/3725.exe"
    w_try cp -f "$W_TMP"/Wininet.dll "$W_SYSTEM32_DLLS"/wininet.dll
    w_override_dlls native,builtin wininet
}

#----------------------------------------------------------------

w_metadata wmi dlls \
    title="Windows Management Instrumentation (aka WBEM) Core 1.5" \
    publisher="Microsoft" \
    year="2000" \
    media="download" \
    file1="wmi9x.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/wbem/wbemcore.dll"

load_wmi()
{
    if test $W_ARCH = win64
    then
        w_die "Installer doesn't support 64-bit architecture."
    fi

    # WMI for NT4.0 need validation: http://www.microsoft.com/downloads/en/details.aspx?FamilyID=c174cfb1-ef67-471d-9277-4c2b1014a31e
    # See also http://www.microsoft.com/downloads/en/details.aspx?FamilyId=98A4C5BA-337B-4E92-8C18-A63847760EA5
    w_download http://download.microsoft.com/download/platformsdk/wmi9x/1.5/W9X/EN-US/wmi9x.exe 62752e9c1b879688c26f205eebf07d3783906c3e

    w_set_winver win98
    w_override_dlls native,builtin wbemprox wmiutils
    # Note: there is a crash in the background towards the end, doesn't seem to hurt; see http://bugs.winehq.org/show_bug.cgi?id=7920
    cd "$W_CACHE"/wmi
    w_try $WINE wmi9x.exe $W_UNATTENDED_SLASH_S
    w_unset_winver
}

#----------------------------------------------------------------

w_metadata wsh56js dlls \
    title="MS Windows scripting 5.6, jscript only, no cscript" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="Windows2000-KB917344-56-x86-enu.exe" \
    installed_file1="c:/windows/inf/jscren.inf"

load_wsh56js()
{
    # This installs jscript 5.6 (but not vbscript)
    # See also http://www.microsoft.com/downloads/details.aspx?FamilyID=16dd21a1-c4ee-4eca-8b80-7bd1dfefb4f8&DisplayLang=en
    w_download http://download.microsoft.com/download/b/c/3/bc3a0c36-fada-497d-a3de-8b0139766f3b/Windows2000-KB917344-56-x86-enu.exe add5f74c5bd4da6cfae47f8306de213ec6ed52c8

    cd "$W_CACHE/$W_PACKAGE"
    w_override_dlls native,builtin jscript
    # setupapi looks at the versions in new and original jscript.dll, and wine's original is newer than wsh56js's, so have to nuke the original
    w_try rm "$W_SYSTEM32_DLLS/jscript.dll"
    w_try $WINE Windows2000-KB917344-56-x86-enu.exe $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata wsh56vb dlls \
    title="MS Windows scripting 5.6, vbscript only, no cscript" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="vbs56men.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/vbscript.dll"

load_wsh56vb()
{
    # This installs vbscript 5.6 (but not jscript)
    # See also http://www.microsoft.com/downloads/details.aspx?familyid=4F728263-83A3-464B-BCC0-54E63714BC75
    w_download http://download.microsoft.com/download/IE60/Patch/Q318089/W9XNT4Me/EN-US/vbs56men.exe 48f14a93db33caff271da0c93f334971f9d7cb22

    cd "$W_CACHE"/wsh56vb
    w_override_dlls native,builtin vbscript
    # setupapi looks at the versions in new and original vbscript.dll, and wine's original is newer than wsh56vb's, so have to nuke the original
    w_try rm "$W_SYSTEM32_DLLS/vbscript.dll"
    w_try $WINE vbs56men.exe $W_UNATTENDED_SLASH_Q
}

#----------------------------------------------------------------

w_metadata wsh57 dlls \
    title="MS Windows Scripting Host 5.7" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="scripten.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/scrrun.dll"

load_wsh57()
{
    # See also http://www.microsoft.com/downloads/details.aspx?FamilyID=47809025-D896-482E-A0D6-524E7E844D81&displaylang=en
    w_download http://download.microsoft.com/download/4/4/d/44de8a9e-630d-4c10-9f17-b9b34d3f6417/scripten.exe b15c6a834b7029e2dfed22127cf905b06857e6f5

    w_try_cabextract -d "$W_SYSTEM32_DLLS" "$W_CACHE"/wsh57/scripten.exe

    # Wine doesn't provide the other dll's (yet?)
    w_override_dlls native,builtin jscript
    w_try_regsvr dispex.dll jscript.dll scrobj.dll scrrun.dll vbscript.dll wshcon.dll wshext.dll
}

#----------------------------------------------------------------

w_metadata xact dlls \
    title="MS XACT Engine" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/xactengine2_0.dll"

load_xact()
{
    helper_directx_dl

    # Extract xactengine?_?.dll, X3DAudio?_?.dll, xaudio?_?.dll, xapofx?_?.dll
    w_try_cabextract -d "$W_TMP" -L -F '*_xact_*x86*' "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_TMP" -L -F '*_x3daudio_*x86*' "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_TMP" -L -F '*_xaudio_*x86*' "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'xactengine*.dll' "$x"
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'xaudio*.dll' "$x"
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'x3daudio*.dll' "$x"
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'xapofx*.dll' "$x"
    done

    # Register xactengine?_?.dll, xaudio?_?.dll
    for x in "$W_SYSTEM32_DLLS"/xactengine* "$W_SYSTEM32_DLLS"/xaudio*
    do
      w_try_regsvr `basename "$x"`
    done
}

#----------------------------------------------------------------

w_metadata xact_jun2010 dlls \
    title="MS XACT Engine" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_Jun2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/xactengine2_0.dll"

load_xact_jun2010()
{
    helper_directx_Jun2010

    # Extract xactengine?_?.dll, X3DAudio?_?.dll, xaudio?_?.dll, xapofx?_?.dll
    w_try_cabextract -d "$W_TMP" -L -F '*_xact_*x86*' "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_TMP" -L -F '*_x3daudio_*x86*' "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_TMP" -L -F '*_xaudio_*x86*' "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'xactengine*.dll' "$x"
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'xaudio*.dll' "$x"
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'x3daudio*.dll' "$x"
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'xapofx*.dll' "$x"
    done

    # Register xactengine?_?.dll, xaudio?_?.dll
    for x in "$W_SYSTEM32_DLLS"/xactengine* "$W_SYSTEM32_DLLS"/xaudio*
    do
      w_try_regsvr `basename "$x"`
    done
}

#----------------------------------------------------------------

w_metadata xinput dlls \
    title="Microsoft XInput (Xbox controller support)" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/xinput1_1.dll"

load_xinput()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F '*_xinput_*x86*' "$W_CACHE"/directx9/$DIRECTX_NAME
    for x in "$W_TMP"/*.cab
    do
      w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F 'xinput*.dll' "$x"
    done
    w_try_regsvr xinput1_1.dll
    w_try_regsvr xinput1_2.dll
    w_try_regsvr xinput1_3.dll
    w_try_regsvr xinput9_1_0.dll
    w_override_dlls native xinput1_1
    w_override_dlls native xinput1_2
    w_override_dlls native xinput1_3
    w_override_dlls native xinput9_1_0
}

#----------------------------------------------------------------

# FIXME: extend metadata to allow file1_en, file1_fr, etc.
w_metadata xmllite dlls \
    title="MS xmllite dll" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/xmllite.dll"

load_xmllite()
{
    case $LANG in
    en*) w_download http://download.microsoft.com/download/f/9/6/f964059a-3747-4ed8-9326-ba1e639031b1/WindowsXP-KB915865-v11-x86-ENU.exe 226d246a1c64e693791de5c727509002d089b0d5 ;;
    fr*) w_download http://download.microsoft.com/download/4/1/d/41de58a0-6715-4d3e-99e7-ff0c11283d1b/WindowsXP-KB915865-v11-x86-FRA.exe abb70b6a96be7dce453b00877739e90c6f3efba0 ;;
    *) w_die "sorry, xmllite install not yet implemented for language $LANG" ;;
    esac

    if w_workaround_wine_bug 16013
    then
        # Find instructions to create this file in dlls/wintrust/tests/crypt.c
        w_download http://winezeug.googlecode.com/svn/trunk/winetricks_files/winetest.cat ac8f50dd54d011f3bb1dd79240dae9378748449f
        # Put a dummy catalog file in place
        mkdir -p "$W_SYSTEM32_DLLS"/catroot/\{f750e6c3-38ee-11d1-85e5-00c04fc295ee\}
        w_try cp -f "$W_CACHE"/xmllite/winetest.cat "$W_SYSTEM32_DLLS"/catroot/\{f750e6c3-38ee-11d1-85e5-00c04fc295ee\}/oem0.cat
        if test ! "$W_OPT_UNATTENDED"
        then
            w_warn "xmllite's interactive installer will hang at the end, but otherwise work."
        fi
    fi

    cd "$W_CACHE"/xmllite
    w_override_dlls native xmllite
    case $LANG in
    en*) w_try $WINE WindowsXP-KB915865-v11-x86-ENU.exe $W_UNATTENDED_SLASH_Q ;;
    fr*) w_try $WINE WindowsXP-KB915865-v11-x86-FRA.exe $W_UNATTENDED_SLASH_Q ;;
    esac
}

#----------------------------------------------------------------

w_metadata xna31 dlls \
    title="MS XNA Framework Redistributable 3.1" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="xnafx31_redist.msi" \
    installed_file1="C:/windows/assembly/GAC_32/Microsoft.Xna.Framework.Game/3.1.0.0__6d5c3888ef60e27d/Microsoft.Xna.Framework.Game.dll"

load_xna31()
{
    w_call dotnet20sp2
    w_download http://download.microsoft.com/download/5/9/1/5912526C-B950-4662-99B6-119A83E60E5C/xnafx31_redist.msi bdd33b677c9576a63ff2a6f65e12c0563cc116e6
    cd "$W_CACHE"/xna31
    w_try $WINE msiexec ${W_OPT_UNATTENDED:+/quiet} /i $file1 
}

#----------------------------------------------------------------

w_metadata xvid dlls \
    title="Xvid Video Codec" \
    publisher="xvid.org" \
    year="2009" \
    media="download" \
    file1="Xvid-1.3.2-20110601.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Xvid/xvid.ico"

load_xvid()
{
    w_call vcrun6
    w_download http://www.koepi.info/Xvid-1.3.2-20110601.exe 0a11498a96f75ad019c4c7d06161504140337dc0
    cd "$W_CACHE"/xvid
    if w_workaround_wine_bug 27380 "Installing msvcr80 to avoid crash in setavi32.exe"
    then
        w_call vcrun2008
    fi
    w_try $WINE $file1 ${W_OPT_UNATTENDED:+ --mode unattended --decode_divx 1 --decode_3ivx 1 --decode_other 1}
}

#----------------------------------------------------------------
# Fonts
#----------------------------------------------------------------

w_metadata baekmuk fonts \
    title="Baekmuk Korean fonts" \
    publisher="Wooderart Inc. / kldp.net" \
    year="1999" \
    media="download" \
    file1="ttf-baekmuk_2.2.orig.tar.gz" \
    installed_file1="$W_FONTSDIR_WIN/batang.ttf"

load_baekmuk()
{
    # See http://kldp.net/projects/baekmuk for project page
    # Need to download from Debian as the project page has unique captcha tokens per visitor
    w_download http://ftp.debian.org/debian/pool/main/t/ttf-baekmuk/ttf-baekmuk_2.2.orig.tar.gz afdee34f700007de6ea87b43c92a88b7385ba65b
    cd "$W_TMP/"
    gunzip -dc "$W_CACHE/baekmuk/ttf-baekmuk_2.2.orig.tar.gz" | tar -xf -
    w_try mv baekmuk-ttf-2.2/ttf/*.ttf "$W_FONTSDIR_UNIX"
    w_register_font batang.ttf "Baekmuk Batang"
    w_register_font gulim.ttf "Baekmuk Gulim"
    w_register_font dotum.ttf "Baekmuk Dotum"
    w_register_font hline.ttf "Baekmuk Headline"
}

#----------------------------------------------------------------

w_metadata cjkfonts fonts \
    title="All Chinese, Japanese, Korean fonts and aliases" \
    publisher="various" \
    date="1999-2010" \
    media="download"

load_cjkfonts()
{
    w_call fakechinese
    w_call fakejapanese
    w_call fakekorean
    w_call unifont
}

#----------------------------------------------------------------

w_metadata corefonts fonts \
    title="MS Arial, Courier, Times fonts" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="arial32.exe" \
    installed_file1="$W_FONTSDIR_WIN/Arial.TTF"

load_corefonts()
{
    # See http://corefonts.sf.net
    # TODO: let user pick mirror,
    # see http://corefonts.sourceforge.net/msttcorefonts-2.0-1.spec for how
    # TODO: add more fonts

    # Added More Fonts (see msttcorefonts)
    # [*] Pointed w_download to sites that actually contained the
    # fonts to w_download of 04-03-2008)
    #w_download $WINETRICKS_SOURCEFORGE/project/corefonts/the%20fonts/final/andale32.exe c4db8cbe42c566d12468f5fdad38c43721844c69
    w_download $WINETRICKS_SOURCEFORGE/project/corefonts/the%20fonts/final/arial32.exe 6d75f8436f39ab2da5c31ce651b7443b4ad2916e
    w_download $WINETRICKS_SOURCEFORGE/project/corefonts/the%20fonts/final/arialb32.exe d45cdab84b7f4c1efd6d1b369f50ed0390e3d344
    w_download $WINETRICKS_SOURCEFORGE/project/corefonts/the%20fonts/final/comic32.exe 2371d0327683dcc5ec1684fe7c275a8de1ef9a51
    w_download $WINETRICKS_SOURCEFORGE/project/corefonts/the%20fonts/final/courie32.exe 06a745023c034f88b4135f5e294fece1a3c1b057
    w_download $WINETRICKS_SOURCEFORGE/project/corefonts/the%20fonts/final/georgi32.exe 90e4070cb356f1d811acb943080bf97e419a8f1e
    w_download $WINETRICKS_SOURCEFORGE/project/corefonts/the%20fonts/final/impact32.exe 86b34d650cfbbe5d3512d49d2545f7509a55aad2
    w_download $WINETRICKS_SOURCEFORGE/project/corefonts/the%20fonts/final/times32.exe 20b79e65cdef4e2d7195f84da202499e3aa83060
    w_download $WINETRICKS_SOURCEFORGE/project/corefonts/the%20fonts/final/trebuc32.exe 50aab0988423efcc9cf21fac7d64d534d6d0a34a
    w_download $WINETRICKS_SOURCEFORGE/project/corefonts/the%20fonts/final/verdan32.exe f5b93cedf500edc67502f116578123618c64a42a
    w_download $WINETRICKS_SOURCEFORGE/project/corefonts/the%20fonts/final/webdin32.exe 2fb4a42c53e50bc70707a7b3c57baf62ba58398f

    # Natively installed versions of these fonts will cause the installers
    # to exit silently. Because there are apps out there that depend on the
    # files being present in the Windows font directory we use cabextract
    # to obtain the files and register the fonts by hand.

    # Andale needs a FontSubstitutes entry
    # w_try_cabextract --directory="$W_TMP" "$W_CACHE"/corefonts/andale32.exe

    # Display EULA
    test x"$W_UNATTENDED_SLASH_Q" = x"" || w_try $WINE "$W_CACHE"/corefonts/arial32.exe $W_UNATTENDED_SLASH_Q

    w_try_cabextract -q --directory="$W_TMP" "$W_CACHE"/corefonts/arial32.exe
    w_try cp -f "$W_TMP"/Arial*.TTF "$W_FONTSDIR_UNIX"
    w_register_font Arial.TTF "Arial"
    w_register_font Arialbd.TTF "Arial Bold"
    w_register_font Arialbi.TTF "Arial Bold Italic"
    w_register_font Ariali.TTF "Arial Italic"

    w_try_cabextract -q --directory="$W_TMP" "$W_CACHE"/corefonts/arialb32.exe
    w_try cp -f "$W_TMP"/AriBlk.TTF "$W_FONTSDIR_UNIX"
    w_register_font AriBlk.TTF "Arial Black"

    w_try_cabextract -q --directory="$W_TMP" "$W_CACHE"/corefonts/comic32.exe
    w_try cp -f "$W_TMP"/Comic*.TTF "$W_FONTSDIR_UNIX"
    w_register_font Comic.TTF "Comic Sans MS"
    w_register_font Comicbd.TTF "Comic Sans MS Bold"

    w_try_cabextract -q --directory="$W_TMP" "$W_CACHE"/corefonts/courie32.exe
    w_try cp -f "$W_TMP"/cour*.ttf "$W_FONTSDIR_UNIX"
    w_register_font Cour.TTF "Courier New"
    w_register_font CourBD.TTF "Courier New Bold"
    w_register_font CourBI.TTF "Courier New Bold Italic"
    w_register_font Couri.TTF "Courier New Italic"

    w_try_cabextract -q --directory="$W_TMP" "$W_CACHE"/corefonts/georgi32.exe
    w_try cp -f "$W_TMP"/Georgia*.TTF "$W_FONTSDIR_UNIX"
    w_register_font Georgia.TTF "Georgia"
    w_register_font Georgiab.TTF "Georgia Bold"
    w_register_font Georgiaz.TTF "Georgia Bold Italic"
    w_register_font Georgiai.TTF "Georgia Italic"

    w_try_cabextract -q --directory="$W_TMP" "$W_CACHE"/corefonts/impact32.exe
    w_try cp -f "$W_TMP"/Impact.TTF "$W_FONTSDIR_UNIX"
    w_register_font Impact.TTF "Impact"

    w_try_cabextract -q --directory="$W_TMP" "$W_CACHE"/corefonts/times32.exe
    w_try cp -f "$W_TMP"/Times*.TTF "$W_FONTSDIR_UNIX"
    w_register_font Times.TTF "Times New Roman"
    w_register_font Timesbd.TTF "Times New Roman Bold"
    w_register_font Timesbi.TTF "Times New Roman Bold Italic"
    w_register_font Timesi.TTF "Times New Roman Italic"

    w_try_cabextract -q --directory="$W_TMP" "$W_CACHE"/corefonts/trebuc32.exe
    w_try cp -f "$W_TMP"/[tT]rebuc*.ttf "$W_FONTSDIR_UNIX"
    w_register_font Trebuc.TTF "Trebucet MS"
    w_register_font Trebucbd.TTF "Trebucet MS Bold"
    w_register_font Trebucbi.TTF "Trebucet MS Bold Italic"
    w_register_font Trebucit.TTF "Trebucet MS Italic"

    w_try_cabextract -q --directory="$W_TMP" "$W_CACHE"/corefonts/verdan32.exe
    w_try cp -f "$W_TMP"/Verdana*.TTF "$W_FONTSDIR_UNIX"
    w_register_font Verdana.TTF "Verdana"
    w_register_font Verdanab.TTF "Verdana Bold"
    w_register_font Verdanaz.TTF "Verdana Bold Italic"
    w_register_font Verdanai.TTF "Verdana Italic"

    w_try_cabextract -q --directory="$W_TMP" "$W_CACHE"/corefonts/webdin32.exe
    w_try cp -f "$W_TMP"/Webdings.TTF "$W_FONTSDIR_UNIX"
    w_register_font Webdings.TTF "Webdings"
}

#----------------------------------------------------------------

w_metadata droid fonts \
    title="Droid fonts" \
    publisher="Ascender Corporation" \
    year="2009" \
    media="download" \
    file1="DroidSans-Bold.ttf" \
    installed_file1="$W_FONTSDIR_WIN/DroidSans-Bold.ttf"

do_droid() {
    w_download ${DROID_URL}$1'?raw=true'   $3  $1
    w_try cp -f "$W_CACHE"/droid/$1 "$W_FONTSDIR_UNIX"
    w_register_font $1 "$2"
}

load_droid()
{
    # See http://en.wikipedia.org/wiki/Droid_(font)
    # Old url was http://android.git.kernel.org/?p=platform/frameworks/base.git;a=blob_plain;f=data/fonts/'
    DROID_URL='https://github.com/android/platform_frameworks_base/blob/master/data/fonts/'

    do_droid DroidSans-Bold.ttf        "Droid Sans Bold"         560e4bcafdebaf29645fbf92633a2ae0d2f9801f
    do_droid DroidSansFallback.ttf     "Droid Sans Fallback"     64de2fde75868ab8d4c6714add08c8f08b3fae1e
    do_droid DroidSansJapanese.ttf     "Droid Sans Japanese"     b3a248c11692aa88a30eb25df425b8910fe05dc5
    do_droid DroidSansMono.ttf         "Droid Sans Mono"         133fb6cf26ea073b456fb557b94ce8c46143b117
    do_droid DroidSans.ttf             "Droid Sans"              62f2841f61e4be66a0303cd1567ed2d300b4e31c
    do_droid DroidSerif-BoldItalic.ttf "Droid Serif Bold Italic" b7f2d37c3a062be671774ff52f4fd95cbef813ce
    do_droid DroidSerif-Bold.ttf       "Droid Serif Bold"        294fa99ceaf6077ab633b5a7c7db761e2f76cf8c
    do_droid DroidSerif-Italic.ttf     "Droid Serif Italic"      bdd8aad5e6ac546d11e7378bdfabeac7ccbdadfc
    do_droid DroidSerif-Regular.ttf    "Droid Serif"             805c5f975e02f488fa1dd1dd0d44ed4f93b0fab4
}

#----------------------------------------------------------------

w_metadata eufonts fonts \
    title="Updated fonts for Romanian and Bulgarian" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="EUupdate.EXE" \
    installed_file1="$W_FONTSDIR_WIN/trebucbd.ttf"

load_eufonts()
{
    # https://www.microsoft.com/downloads/details.aspx?FamilyID=0ec6f335-c3de-44c5-a13d-a1e7cea5ddea&displaylang=en
    w_download http://download.microsoft.com/download/a/1/8/a180e21e-9c2b-4b54-9c32-bf7fd7429970/EUupdate.EXE 9b076c40cb63aa0d8512aa8e610ba11d3466e441
    w_try_cabextract -q --directory="$W_TMP" "$W_CACHE"/eufonts/EUupdate.EXE
    w_try cp -f "$W_TMP"/*.ttf "$W_FONTSDIR_UNIX"

    w_register_font ArialBI.ttf "Arial Bold Italic"
    w_register_font ArialI.ttf "Arial Italic"
    w_register_font Arial.ttf "Arial"
    w_register_font TimesBd.ttf "Times New Roman Bold"
    w_register_font TimesBI.ttf "Times New Roman Bold Italic"
    w_register_font TimesI.ttf "Times New Roman Italic"
    w_register_font Times.ttf "Times New Roman"
    w_register_font trebucbd.ttf "Trebuchet Bold"
    w_register_font trebucbi.ttf "Trebuchet Bold Italic"
    w_register_font trebucit.ttf "Trebuchet Italic"
    w_register_font trebuc.ttf "Trebuchet"
    w_register_font Verdanab.ttf "Verdana Bold"
    w_register_font Verdanai.ttf "Verdana Italian"
    w_register_font Verdana.ttf "Verdana"
    w_register_font Verdanaz.ttf "Verdana Bold Italic"
}

#----------------------------------------------------------------

w_metadata fakechinese fonts \
    title="Creates aliases for Chinese fonts using WenQuanYi fonts" \
    publisher="wenq.org" \
    year="2009"

load_fakechinese()
{
    w_call wenquanyi
    # Loads Wenquanyi fonts and sets aliases for Microsoft Chinese fonts
    # Aliases to set:
    # Microsoft JhengHei --> WenQuanYi Micro Hei
    # Microsoft YaHei --> WenQuanYi Micro Hei
    # SimHei --> WenQuanYi Micro Hei

    w_register_font_substitution "Microsoft JhengHei" "WenQuanYi Micro Hei"
    w_register_font_substitution "Microsoft YaHei" "WenQuanYi Micro Hei"
    w_register_font_substitution "SimHei" "WenQuanYi Micro Hei"
}

#----------------------------------------------------------------

w_metadata fakejapanese fonts \
    title="Creates aliases for Japanese fonts using Takao fonts" \
    publisher="Jun Kobayashi" \
    year="2010"

load_fakejapanese()
{
    w_call takao
    # Loads Takao fonts and sets aliases for MS Gothic and MS PGothic, mainly for Japanese language support
    # Aliases to set:
    # MS Gothic --> TakaoGothic
    # MS PGothic --> TakaoPGothic
    # MS Mincho --> TakaoMincho
    # MS PMincho --> TakaoPMincho
    # These aliases were taken from what was listed in Ubuntu's fontconfig definitions.

    w_register_font_substitution "MS Gothic" "TakaoGothic"
    w_register_font_substitution "MS PGothic" "TakaoPGothic"
    w_register_font_substitution "MS Mincho" "TakaoMincho"
    w_register_font_substitution "MS PMincho" "TakaoPMincho"
}

#----------------------------------------------------------------

w_metadata fakekorean fonts \
    title="Creates aliases for Korean fonts using Baekmuk fonts" \
    publisher="Wooderart Inc. / kldp.net" \
    year="1999"

load_fakekorean()
{
    w_call baekmuk
    # Loads Baekmuk fonts and sets as an alias for Gulim, Dotum, and Batang for Korean language support
    # Aliases to set:
    # Gulim --> Baekmuk Gulim
    # GulimChe --> Baekmuk Gulim
    # Batang --> Baekmuk Batang
    # BatangChe --> Baekmuk Batang
    # Dotum --> Baekmuk Dotum
    # DotumChe --> Baekmuk Dotum

    w_register_font_substitution "Gulim" "Baekmuk Gulim"
    w_register_font_substitution "GulimChe" "Baekmuk Gulim"
    w_register_font_substitution "Batang" "Baekmuk Batang"
    w_register_font_substitution "BatangChe" "Baekmuk Batang"
    w_register_font_substitution "Dotum" "Baekmuk Dotum"
    w_register_font_substitution "DotumChe" "Baekmuk Dotum"
}

#----------------------------------------------------------------

w_metadata fontfix fonts \
    title="Updated Arphic fonts" \
    publisher="Arphic" \
    year="2007" \
    media="download" \
    file1="ttf-arphic-ukai_0.1.20060108.orig.tar.gz"

load_fontfix()
{
    # some versions of ukai.ttf and uming.ttf crash .net and picasa
    # See http://bugs.winehq.org/show_bug.cgi?id=7098#c9
    # Could fix globally, but that needs root, so just fix for wine
    if test -f /usr/share/fonts/truetype/arphic/ukai.ttf
    then
        gotsum=`$SHA1SUM < /usr/share/fonts/truetype/arphic/ukai.ttf | sed 's/ .*//'`
        # FIXME: do all affected versions of the font have same sha1sum as Gutsy?  Seems unlikely.
        if [ "$gotsum"x = "96e1121f89953e5169d3e2e7811569148f573985"x ]
        then
            w_download https://launchpadlibrarian.net/1499628/ttf-arphic-ukai_0.1.20060108.orig.tar.gz 92e577602d71454a108968e79ab667451f3602a2
            gunzip -dc "$W_CACHE/fontfix/ttf-arphic-ukai_0.1.20060108.orig.tar.gz" | (cd "$W_TMP"; tar -xf -)
            w_try mv "$W_TMP"/ttf-arphic-ukai-0.1.20060108/*.ttf "$W_FONTSDIR_UNIX"
        fi
    fi

    if test -f /usr/share/fonts/truetype/arphic/uming.ttf
    then
        gotsum=`$SHA1SUM < /usr/share/fonts/truetype/arphic/uming.ttf | sed 's/ .*//'`
        if [ "$gotsum"x = "2a4f4a69e343c21c24d044b2cb19fd4f0decc82c"x ]
        then
            w_download https://launchpadlibrarian.net/1564410/ttf-arphic-uming_0.1.20060108.orig.tar.gz 1439cdd731906e9e5311f320c2cb33262b24ef91
            gunzip -dc "$W_CACHE/fontfix/ttf-arphic-uming_0.1.20060108.orig.tar.gz" | (cd "$W_TMP"; tar -xf -)
            w_try mv "$W_TMP"/ttf-arphic-uming-0.1.20060108/*.ttf "$W_FONTSDIR_UNIX"
        fi
    fi

    # Focht says Samyak is bad news, and font substitution isn't a good workaround.
    # I've seen psdkwin7 setup crash because of this; the symptom was a messagebox saying
    # SDKSetup encountered an error: The type initializer for 'Microsoft.WizardFramework.WizardSettings' threw an exception
    # and WINEDEBUG=+relay,+seh shows an exception very quickly after
    # Call KERNEL32.CreateFileW(0c83b36c L"Z:\\USR\\SHARE\\FONTS\\TRUETYPE\\TTF-ORIYA-FONTS\\SAMYAK-ORIYA.TTF",80000000,00000001,00000000,00000003,00000080,00000000) ret=70d44091
    if xlsfonts 2>/dev/null | egrep -i "samyak|oriya"
    then
        w_die "Please uninstall the Samyak/Oriya font, e.g. 'sudo dpkg -r ttf-oriya-fonts', then log out and log in again.  That font causes strange crashes in .net programs."
    fi
}

#----------------------------------------------------------------

w_metadata liberation fonts \
    title="Red Hat Liberation fonts (Sans, Serif, Mono)" \
    publisher="Red Hat" \
    year="2008" \
    media="download" \
    file1="liberation-fonts-1.04.tar.gz" \
    installed_file1="$W_FONTSDIR_WIN/LiberationMono-BoldItalic.ttf"

load_liberation()
{
    # http://www.redhat.com/promo/fonts/
    case `uname -s` in
    SunOS|Solaris)
      echo "If you get 'ERROR: Certificate verification error for fedorahosted.org: unable to get local issuer certificate':"
      echo "Then you need to add Verisign root certificates to your local keystore."
      echo "OpenSolaris users, see: http://www.linuxtopia.org/online_books/opensolaris_2008/SYSADV1/html/swmgrpatchtasks-14.html"
      echo "Or edit winetricks's download function, and add '--no-check-certificate' to the command."
      ;;
    esac

    w_download https://fedorahosted.org/releases/l/i/liberation-fonts/liberation-fonts-1.04.tar.gz 097882c92e3260742a3dc3bf033792120d8635a3
    cd "$W_TMP"
    gunzip -dc "$W_CACHE"/liberation/liberation-fonts-1.04.tar.gz | tar -xf -
    mv liberation-fonts-1.04/*.ttf "$W_FONTSDIR_UNIX"

    w_register_font LiberationMono-BoldItalic.ttf "LiberationMono-BoldItalic"
    w_register_font LiberationMono-Bold.ttf "LiberationMono-Bold"
    w_register_font LiberationMono-Italic.ttf "LiberationMono-Italic"
    w_register_font LiberationMono-Regular.ttf "LiberationMono-Regular"
    w_register_font LiberationSans-BoldItalic.ttf "LiberationSans-BoldItalic"
    w_register_font LiberationSans-Bold.ttf "LiberationSans-Bold"
    w_register_font LiberationSans-Italic.ttf "LiberationSans-Italic"
    w_register_font LiberationSans-Regular.ttf "LiberationSans-Regular"
    w_register_font LiberationSerif-BoldItalic.ttf "LiberationSerif-BoldItalic"
    w_register_font LiberationSerif-Bold.ttf "LiberationSerif-Bold"
    w_register_font LiberationSerif-Italic.ttf "LiberationSerif-Italic"
    w_register_font LiberationSerif-Regular.ttf "LiberationSerif-Regular"
}

#----------------------------------------------------------------

w_metadata lucida fonts \
    title="MS Lucida Console font" \
    publisher="Microsoft" \
    year="1998" \
    media="download" \
    file1="eurofixi.exe" \
    installed_file1="$W_FONTSDIR_WIN/lucon.ttf"

load_lucida()
{
    w_download ftp://ftp.microsoft.com/bussys/winnt/winnt-public/fixes/usa/NT40TSE/hotfixes-postSP3/Euro-fix/eurofixi.exe 64c47ad92265f6f10b0fd909a703d4fd1b05b2d5
    w_try_cabextract -d "$W_FONTSDIR_UNIX" -L -F 'lucon.ttf' "$W_CACHE"/lucida/eurofixi.exe
    w_register_font lucon.ttf "Lucida Console"
}

#----------------------------------------------------------------

w_metadata opensymbol fonts \
    title="OpenSymbol fonts (replacement for Wingdings)" \
    publisher="OpenOffice.org" \
    year="2010" \
    media="download" \
    file1="ttf-opensymbol_3.2.1-11+squeeze2_all.deb" \
    installed_file1="$W_FONTSDIR_WIN/opens___.ttf"

load_opensymbol()
{
    # The OpenSymbol fonts are a replacement for the Windows Wingdings font from OpenOffice.org.
    # Need to w_download Debian since I can't find a standalone download from OpenOffice
    # Note: The source download package on debian is for _all_ of OpenOffice, which is 266 MB.
    w_download http://ftp.us.debian.org/debian/pool/main/o/openoffice.org/ttf-opensymbol_3.2.1-11+squeeze2_all.deb dfcfc10a3e9b0be43520c7fd26cef6df0e713697

    cd "$W_TMP"
    w_try ar x "$W_CACHE/opensymbol/ttf-opensymbol_3.2.1-11+squeeze2_all.deb" data.tar.bz2
    w_try tar jvxf data.tar.bz2 ./usr/share/fonts/truetype/openoffice/opens___.ttf
    w_try mv "$W_TMP/usr/share/fonts/truetype/openoffice/opens___.ttf" "$W_FONTSDIR_UNIX"
    w_register_font opens___.ttf "OpenSymbol"
}

#----------------------------------------------------------------

w_metadata tahoma fonts \
    title="MS Tahoma font (not part of corefonts)" \
    publisher="Microsoft" \
    year="2007" \
    media="download" \
    file1="tahoma32.exe" \
    installed_file1="$W_FONTSDIR_WIN/tahoma.ttf"

load_tahoma()
{
    # The tahoma and tahomabd fonts are needed by e.g. Steam

    w_download http://download.microsoft.com/download/office97pro/fonts/1/w95/en-us/tahoma32.exe 888ce7b7ab5fd41f9802f3a65fd0622eb651a068
    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/tahoma/tahoma32.exe
    w_try cp -f "$W_TMP"/Tahoma.TTF "$W_FONTSDIR_UNIX"/tahoma.ttf
    w_try cp -f "$W_TMP"/Tahomabd.TTF "$W_FONTSDIR_UNIX"/tahomabd.ttf

    # FIXME:  Wine seems to nuke the registry entries for Tahoma.  Why?  Font Xplorer always lists it as 'not installed'.
    w_register_font tahoma.ttf "Tahoma"
    w_register_font tahomabd.ttf "Tahoma Bold"

    # ? does some app assume it can overwrite these, or is this a leftover from before we had install checks?
    chmod +w "$W_FONTSDIR_UNIX"/tahoma*.ttf
}

#----------------------------------------------------------------

w_metadata takao fonts \
    title="Takao Japanese fonts" \
    publisher="Jun Kobayashi" \
    year="2010" \
    media="download" \
    file1="takao-fonts-ttf-003.02.01.zip" \
    installed_file1="$W_FONTSDIR_WIN/TakaoGothic.ttf"

load_takao()
{
    # The Takao font provides Japanese glyphs.  May also be needed with fakejapanese function above.
    # See http://launchpad.net/takao-fonts for project page
    w_download http://launchpad.net/takao-fonts/003.02/003.02.01/+download/takao-fonts-ttf-003.02.01.zip 4f636d5c7c1bc16b96ea723adb16838cfb6df059
    cp -f "$W_CACHE"/takao/takao-fonts-ttf-003.02.01.zip "$W_TMP"
    w_try_unzip -d "$W_TMP" "$W_TMP"/takao-fonts-ttf-003.02.01.zip
    w_try cp -f "$W_TMP"/takao-fonts-ttf-003.02.01/*.ttf "$W_FONTSDIR_UNIX"

    w_register_font TakaoGothic.ttf "TakaoGothic"
    w_register_font TakaoPGothic.ttf "TakaoPGothic"
    w_register_font TakaoMincho.ttf "TakaoMincho"
    w_register_font TakaoPMincho.ttf "TakaoPMincho"
    w_register_font TakaoExGothic.ttf "TakaoExGothic"
    w_register_font TakaoExMincho.ttf "TakaoExMincho"
}

#----------------------------------------------------------------

w_metadata uff fonts \
    title="Ubuntu Font Family" \
    publisher="Ubuntu" \
    year="2010" \
    media="download" \
    file1="ubuntu-font-family-0.70.1.zip" \
    installed_file1="$W_FONTSDIR_WIN/Ubuntu-R.ttf" \
    homepage="https://launchpad.net/ubuntu-font-family"

load_uff()
{
    w_download http://font.ubuntu.com/download/ubuntu-font-family-0.70.1.zip efbab0d5d8cb5cff091307d2360dcb1bfe1ae6e1
    cd "$W_TMP"
    w_try_unzip "$W_CACHE"/uff/ubuntu-font-family-0.70.1.zip
    mv ubuntu-font-family-0.70.1/*.ttf "$W_FONTSDIR_UNIX"

    w_register_font Ubuntu-R.ttf "Ubuntu"
    w_register_font Ubuntu-I.ttf "Ubuntu Italic"
    w_register_font Ubuntu-B.ttf "Ubuntu Bold"
    w_register_font Ubuntu-BI.ttf "Ubuntu Bold Italic"
}

#----------------------------------------------------------------

w_metadata wenquanyi fonts \
    title="WenQuanYi CJK font" \
    publisher="wenq.org" \
    year="2009" \
    media="download" \
    file1="wqy-microhei-0.2.0-beta.tar.gz" \
    installed_file1="$W_FONTSDIR_WIN/wqy-microhei.ttc"

load_wenquanyi()
{
    # See http://wenq.org/enindex.cgi
    # Donate at http://wenq.org/enindex.cgi?Download(en)#MicroHei_Beta if you want to help support free CJK font development
    w_download $WINETRICKS_SOURCEFORGE/wqy/wqy-microhei-0.2.0-beta.tar.gz 28023041b22b6368bcfae076de68109b81e77976
    cd "$W_TMP/"
    gunzip -dc "$W_CACHE/wenquanyi/wqy-microhei-0.2.0-beta.tar.gz" | tar -xf -
    w_try mv wqy-microhei/wqy-microhei.ttc "$W_FONTSDIR_UNIX"
    w_register_font wqy-microhei.ttc "WenQuanYi Micro Hei"
}

#----------------------------------------------------------------

w_metadata unifont fonts \
    title="Unifont alternative to Arial Unicode MS" \
    publisher="Roman Czyborra / GNU" \
    year="2008" \
    media="download" \
    file1="unifont-5.1.20080907.zip" \
    installed_file1="$W_FONTSDIR_WIN/unifont.ttf"

load_unifont()
{
    # The GNU Unifont provides glyphs for just about everything in common language.  It is intended for multilingual usage.
    # See http://unifoundry.com/unifont.html for project page
    w_download http://unifoundry.com/unifont-5.1.20080907.zip bb8a3960dc0a96aa305de28312ea8a0ab64123d2
    cp -f "$W_CACHE"/unifont/unifont-5.1.20080907.zip "$W_TMP"
    w_try_unzip -d "$W_TMP" "$W_TMP"/unifont-5.1.20080907.zip
    w_try cp -f "$W_TMP"/unifont-5.1.20080907.ttf "$W_FONTSDIR_UNIX/unifont.ttf"

    w_register_font unifont.ttf "Unifont"
    w_register_font_substitution "Arial Unicode MS" "Unifont"
}

#----------------------------------------------------------------

w_metadata allfonts fonts \
    title="All fonts" \
    publisher="various" \
    year="1998-2010" \
    media="download" 

load_allfonts()
{
    # This verb uses reflection, should probably do it portably instead, but that would require keeping it up to date
    for file in "$WINETRICKS_METADATA"/fonts/*.vars
    do
        cmd=`basename $file .vars`
        case $cmd in
        allfonts|cjkfonts) ;;
        *) w_call $cmd;;
        esac
    done
}

#----------------------------------------------------------------
# Apps
#----------------------------------------------------------------

w_metadata 7zip apps \
    title="7-Zip" \
    publisher="Igor Pavlov" \
    year="1999" \
    media="download" \
    file1="7z465.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/7-Zip/7z.exe"

load_7zip()
{
    # FIXME: use more up to date version
    w_download http://downloads.sourceforge.net/project/sevenzip/7-Zip/4.65/7z465.exe c36012e960fa3932cd23f30ac5b0fe722740243a
    cd "$W_CACHE"/7zip
    w_try $WINE 7z465.exe $W_UNATTENDED_SLASH_S
    w_declare_exe "$W_PROGRAMS_X86_WIN\\7-Zip" "7z.exe"
}

#----------------------------------------------------------------

w_metadata abiword apps \
    title="AbiWord 2.8.6" \
    publisher="AbiSource" \
    year="2010" \
    media="download" \
    file1="abiword-setup-2.8.6.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/AbiWord/bin/AbiWord.exe"

load_abiword()
{
    w_download http://www.abisource.com/downloads/abiword/2.8.6/Windows/abiword-setup-2.8.6.exe a91acd3f60e842d23556032d34f1600602768318
    cd "$W_CACHE"/abiword
    w_try $WINE abiword-setup-2.8.6.exe $W_UNATTENDED_SLASH_S
    w_declare_exe "$W_PROGRAMS_X86_WIN\\AbiWord\\bin" AbiWord.exe
}

#----------------------------------------------------------------

w_metadata adobe_diged apps \
    title="Adobe Digital Editions" \
    publisher="Adobe" \
    year="2011" \
    media="download" \
    file1="setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Adobe/Adobe Digital Editions/digitaleditions.exe" \
    homepage="http://www.adobe.com/products/digitaleditions/"

load_adobe_diged()
{
    w_download http://kb2.adobe.com/cps/403/kb403051/attachments/setup.exe 4c79685408fa6ca12ef8bb0e0eaa4a846e21f915
    # NSIS installer
    w_try $WINE "$W_CACHE"/$W_PACKAGE/setup.exe ${W_OPT_UNATTENDED:+ /S}
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Adobe\\Adobe Digital Editions" \
        digitaleditions.exe
}

#----------------------------------------------------------------

w_metadata audible apps \
    title="Audible.com Manager / Player" \
    publisher="Audible" \
    year="2011" \
    media="download" \
    file1="ActiveSetupN.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Audible/Bin/Manager.exe" \
    homepage="http://www.audible.com"

load_audible()
{
    w_download http://download.audible.com/AM50/ActiveSetupN.exe 49f501471912ccca442bcc1c8f2c69160579f712
    cd "$W_CACHE/$W_PACKAGE"
    # Use exact title match!
    w_ahk_do "
        SetWinDelay 500
        SetTitleMatchMode, 3
        Run, $file1
        WinWait, AudibleManager Setup
        ControlClick, Button3  ; accept
        WinWait, AudibleManager Setup, Start by
        ControlClick, Button6 ; OK
        WinWaitClose
        ; many windows come and go, quite a few of them starting with AudibleManager, so use exact match to get the real mccoy
        WinWait, AudibleManager  ; the dang thing starts up
        WinKill
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Audible\\Bin" Manager.exe
}

#----------------------------------------------------------------

w_metadata audibledm apps \
    title="Audible.com Download Manager" \
    publisher="Audible" \
    year="2011" \
    media="download" \
    file1="AudibleDM_iTunesSetup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Audible/Bin/AudibleDownloadHelper.exe" \
    homepage="http://www.audible.com"

load_audibledm()
{
    w_download http://download.audible.com/AM50/AudibleDM_iTunesSetup.exe 03261d77a59ebbceedf6683b5301c162bc0c7788
    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 500
        SetTitleMatchMode, 2
        Run, AudibleDM_iTunesSetup.exe
        WinWait, Audible Download Manager Setup
        ControlClick, Button2  ; accept
        WinWait, Audible Download Manager Setup, Choose where
        ControlClick, Button1 ; OK
        WinWait, Audible Download Manager Setup, Manage
        ControlClick, Button1 ; OK
        WinWait, Audible Download Manager Setup, success
        ControlClick, Button1 ; OK
        WinWaitClose
        WinWait, Audible Download Manager  ; the dang thing starts up
        WinKill
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Audible\\Bin" AudibleDownloadHelper.exe
}

#----------------------------------------------------------------

w_metadata autohotkey apps \
    title="Autohotkey" \
    publisher="autohotkey.org" \
    year="2010" \
    media="download" \
    file1="AutoHotkey104805_Install.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/AutoHotkey/AutoHotkey.exe"

load_autohotkey()
{
    W_BROWSERAGENT=1 \
    w_download http://www.autohotkey.net/programs/AutoHotkey104805_Install.exe 13e5a9ca6d5b7705f1cd02560c3af4d38b1904fc
    cd "$W_CACHE"/autohotkey
    w_try $WINE AutoHotkey104805_Install.exe $W_UNATTENDED_SLASH_S
}

#----------------------------------------------------------------

w_metadata kobo apps \
    title="Kobo e-book reader" \
    publisher="Kobo" \
    year="2011" \
    media="download" \
    file1="KoboSetup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Kobo/Kobo.exe" \
    homepage="http://www.borders.com/online/store/MediaView_ereaderapps"

load_kobo()
{
    w_download http://download.kobobooks.com/desktop/1/KoboSetup.exe 31a5f5583edf4b716b9feacb857d2170104cabd9
    cd "$W_CACHE"/kobo
    w_try $WINE $file1 ${W_OPT_UNATTENDED:+ /S}
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Kobo" "Kobo.exe"
}

#----------------------------------------------------------------

w_metadata cmake apps \
    title="CMake 2.8" \
    publisher="Kitware" \
    year="2010" \
    media="download" \
    file1="cmake-2.8.2-win32-x86.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/CMake 2.8/bin/cmake-gui.exe"

load_cmake()
{
    w_download http://www.cmake.org/files/v2.8/cmake-2.8.2-win32-x86.exe 2c46f4e804787b231c2f45e1b43f1838462e8dfe
    cd "$W_CACHE"/cmake
    w_try $WINE cmake-2.8.2-win32-x86.exe $W_UNATTENDED_SLASH_S

    w_declare_exe "$W_PROGRAMS_X86_WIN\\CMake 2.8\\bin" "cmake-gui.exe"
}

#----------------------------------------------------------------

w_metadata colorprofile apps \
    title="Standard RGB color profile" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="ColorProfile.exe" \
    installed_exe1="c:/windows/system32/spool/drivers/color/sRGB Color Space Profile.icm"

load_colorprofile()
{
    w_download http://download.microsoft.com/download/whistler/hwdev1/1.0/wxp/en-us/ColorProfile.exe 6b72836b32b343c82d0760dff5cb51c2f47170eb
    w_try_unzip -d "$W_TMP" "$W_CACHE"/colorprofile/ColorProfile.exe

    # It's in system32 for both win32/win64
    mkdir -p "$W_WINDIR_UNIX"/system32/spool/drivers/color
    w_try cp -f "$W_TMP/sRGB Color Space Profile.icm" "$W_WINDIR_UNIX"/system32/spool/drivers/color
}

#----------------------------------------------------------------

w_metadata controlpad apps \
    title="MS ActiveX Control Pad" \
    publisher="Microsoft" \
    year="1997" \
    media="download" \
    file1="setuppad.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/ActiveX Control Pad/PED.EXE"

load_controlpad()
{
    # http://msdn.microsoft.com/en-us/library/ms968493.aspx
    w_call wsh57
    w_download http://download.microsoft.com/download/activexcontrolpad/install/4.0.0.950/win98mexp/en-us/setuppad.exe 8921e0f52507ca6a373c94d222777c750fb48af7
    w_try_cabextract --directory="$W_TMP" "$W_CACHE"/controlpad/setuppad.exe

    echo "If setup says 'Unable to start DDE ...', press Ignore"

    cd "$W_TMP"
    case "$W_UNATTENDED_SLASH_Q" in
    "") quiet="" ;;
    *)  quiet="/qt"
    esac
    w_try $WINE setup $quiet

    if ! test -f "$W_SYSTEM32_DLLS"/FM20.DLL
    then
        w_die "Install failed.  Please report,  If you just wanted fm20.dll, try installing art2min instead."
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\ActiveX Control Pad" "PED.EXE"
}

#----------------------------------------------------------------

w_metadata cygwin apps \
    title="cygwin" \
    publisher="Red Hat" \
    year="2009" \
    media="download" \
    file1="setup.exe" \
    installed_exe1="C:/cygwin/bin/sh.exe"

load_cygwin()
{
    if w_workaround_wine_bug 21206
    then
        # Wine can't handle current cygwin, so use some random verison of cygwin's setup from mid-2009
        w_download http://kegel.com/cygwin/1.5/setup.exe 5cfb8ebe4f385b0fcffa04d22d607ec75ea05180
        w_warn "Paste in ftp://www.fruitbat.org/pub/cygwin/circa/2009/09/08/111037 as the repo url for now, until bug 21206 is fixed"
        # -X option is insecure, but we have to use it because fruitbat.org didn't archive .sig files :-(
        _W_cygopts="-X"
    else
        w_download http://cygwin.com/setup.exe aaa2552de78e14891937c1fde86032e811cf3c3a
        _W_cygopts=
    fi

    mkdir -p "$W_DRIVE_C"/cygpkgs
    # If you happen to have saved your cygpkgs directory, unpack it now
    test -f "$W_CACHE/cygwin/cygpkgs.tgz" && (cd "$W_DRIVE_C"; gunzip -dc "$W_CACHE/cygwin/cygpkgs.tgz" | tar -xf -)
    # FIXME: automate the base installation
    cp "$W_CACHE/cygwin/setup.exe" "$W_DRIVE_C"/cygpkgs
    cd "$W_DRIVE_C"/cygpkgs
    w_try $WINE setup.exe $_W_cygopts
    unset _W_cygopts
}

#----------------------------------------------------------------

# dxdiag is a system component that one usually adds to an existing wineprefix,
# so it belongs in 'dlls', not apps.
w_metadata dxdiag dlls \
    title="DirectX Diagnostic Tool" \
    publisher="Microsoft" \
    year="2010" \
    media="download" \
    file1="../directx9/directx_feb2010_redist.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/dxdiag.exe"

load_dxdiag()
{
    helper_directx_dl

    w_try_cabextract -d "$W_TMP" -L -F dxnt.cab "$W_CACHE"/directx9/$DIRECTX_NAME
    w_try_cabextract -d "$W_SYSTEM32_DLLS" -L -F "dxdiag.exe" "$W_TMP/dxnt.cab"
    mkdir -p "$W_WINDIR_UNIX/help"
    w_try_cabextract -d "$W_WINDIR_UNIX/help" -L -F "dxdiag.chm" "$W_TMP/dxnt.cab"
    w_override_dlls native dxdiag.exe

    if w_workaround_wine_bug 1429
    then
        w_call dxdiagn
    fi
    if w_workaround_wine_bug 25715
    then
        w_call quartz
    fi
    if w_workaround_wine_bug 25716
    then
        w_call devenum
    fi
}

#----------------------------------------------------------------

w_metadata firefox35 apps \
    title="Firefox 3.5" \
    publisher="Mozilla" \
    year="2011" \
    media="download" \
    file1="Firefox Setup 3.5.19.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Mozilla Firefox/firefox.exe"

load_firefox35()
{
    w_download "ftp://archive.mozilla.org/pub/mozilla.org/firefox/releases/3.5.19/win32/en-US/Firefox%20Setup%203.5.19.exe" 14c3852e9693b5f17982fa01a0d29f9d1422be79 "$file1"
    cd "$W_CACHE"/firefox35
    w_try $WINE "$file1" ${W_OPT_UNATTENDED:+ -ms}

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Mozilla Firefox" firefox.exe

    myexec="Exec=env WINEPREFIX=\"$HOME/.local/share/wineprefixes/firefox\" wine cmd /c 'C:\\\\\\Run-firefox.bat'"
    mymenu="$HOME/.local/share/applications/wine/Programs/Mozilla Firefox/Mozilla Firefox.desktop"
    if test -f "$mymenu" && w_workaround_wine_bug 26304 "Fixing system menu"
    then
        # this is a hack, hopefully the wine bug will be fixed soon
        sed -i "s,Exec=.*,$myexec," "$mymenu"
    fi
}

#----------------------------------------------------------------

w_metadata firefox36 apps \
    title="Firefox 3.6" \
    publisher="Mozilla" \
    year="2011" \
    media="download" \
    file1="Firefox Setup 3.6.24.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Mozilla Firefox/firefox.exe"

load_firefox36()
{
    w_download "http://download.mozilla.org/?product=firefox-3.6.24&os=win&lang=en-US" 7d149a9a45fd7cdd9b31b1a966650466b7111f1f "$file1"
    cd "$W_CACHE"/firefox36
    w_try $WINE "$file1" ${W_OPT_UNATTENDED:+ -ms}

    if w_workaround_wine_bug 29077
    then
        w_warn "Visit about:config, search for dom.ipc, and set those booleans false if you want to use flash."
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Mozilla Firefox" firefox.exe

    myexec="Exec=env WINEPREFIX=\"$HOME/.local/share/wineprefixes/firefox\" wine cmd /c 'C:\\\\\\Run-firefox.bat'"
    mymenu="$HOME/.local/share/applications/wine/Programs/Mozilla Firefox/Mozilla Firefox.desktop"
    if test -f "$mymenu" && w_workaround_wine_bug 26304 "Fixing system menu"
    then
        # this is a hack, hopefully the wine bug will be fixed soon
        sed -i "s,Exec=.*,$myexec," "$mymenu"
    fi
}

#----------------------------------------------------------------

w_metadata firefox5 apps \
    title="Firefox 5" \
    publisher="Mozilla" \
    year="2011" \
    media="download" \
    file1="Firefox Setup 5.0.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Mozilla Firefox/firefox.exe"

load_firefox5()
{
    if w_workaround_wine_bug 22972 "" 1.3.0,
    then
        w_die  "Requires wine-1.3.0 or later to install"
    fi

    if w_workaround_wine_bug 29077
    then
        w_warn "Visit about:config, search for dom.ipc, and set those booleans false if you want to use flash."
    fi

    w_download "http://download.mozilla.org/?product=firefox-5.0&os=win&lang=en-US" 288895db0a58b91801c5c1dfc0017131300dba00 "$file1"
    cd "$W_CACHE"/firefox5
    w_try $WINE "$file1" ${W_OPT_UNATTENDED:+ -ms}

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Mozilla Firefox" firefox.exe
}

#----------------------------------------------------------------

w_metadata firefox apps \
    title="Firefox 8" \
    publisher="Mozilla" \
    year="2011" \
    media="download" \
    file1="Firefox Setup 8.0.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Mozilla Firefox/firefox.exe"

load_firefox()
{
    if w_workaround_wine_bug 22972 "" 1.3.0,
    then
        w_die  "Requires wine-1.3.0 or later to install"
    fi

    if w_workaround_wine_bug 29077
    then
        w_warn "Visit about:config, search for dom.ipc, and set those booleans false if you want to use flash."
    fi

    w_download "http://download.mozilla.org/?product=firefox-8.0&os=win&lang=en-US" dbbc497e639cae401dd9e6db6b61018ea0d2b689 "$file1"
    cd "$W_CACHE"/firefox
    w_try $WINE "$file1" ${W_OPT_UNATTENDED:+ -ms}

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Mozilla Firefox" firefox.exe
}

#----------------------------------------------------------------

w_metadata fontxplorer apps \
    title="Font Xplorer 1.2.2" \
    publisher="Moon Software" \
    year="2001" \
    media="download" \
    file1="Font_Xplorer_122_Free.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Font Xplorer/FXplorer.exe" \
    homepage="http://www.moonsoftware.com/fxplorer.asp"

load_fontxplorer()
{
    w_download http://www.moonsoftware.com/files/Font_Xplorer_122_Free.exe 22feb63be28730cbfad5458b139464490a25a68d

    cd "$W_CACHE/fontxplorer"
    w_try $WINE Font_Xplorer_122_Free.exe $W_UNATTENDED_SLASH_S
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Font Xplorer" "FXplorer.exe"
}

#----------------------------------------------------------------

w_metadata irfanview apps \
    title="Irfanview" \
    publisher="Irfan Skiljan" \
    year="2011" \
    media="download" \
    file1="iview428_setup.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/IrfanView/i_view32.exe" \
    homepage="http://www.irfanview.com/"

load_irfanview()
{
    w_download http://www.software.com/files/iview428_setup.exe \
               a51c3f5fbb651c4c00f13c59d3de9d0f0552ea46

    if w_workaround_wine_bug 657 "Installing mfc42"
    then
        w_call mfc42
    fi

    cd "$W_CACHE/$W_PACKAGE"
    if test "$W_OPT_UNATTENDED"
    then
        w_ahk_do "
            SetWinDelay 200
            SetTitleMatchMode, 2
            run $file1
            winwait, Setup, This program will install
            winactivate, Setup, This program will install
            winwaitactive, Setup, This program will install
            send !a ; set up for all users
            send n  ; next
            winwait, Setup, new in this version
            winactivate, Setup, new in this version
            winwaitactive, Setup, new in this version
            send n  ; skip release notes
            winwait, Setup, Do you want to associate extensions
            winactivate, Setup, Do you want to associate extensions
            winwaitactive, Setup, Do you want to associate extensions
            send n  ; don't associate any extensions (default)
            Loop
            {
                ifWinExist, Setup, Ready to install
                {
                    break
                }
                ifWinExist, Setup, Google Chrome
                {
                    winactivate, Setup, Google Chrome
                    winwaitactive, Setup, Google Chrome
                    send !c ; decline Chrome
                    send !n
                    continue
                }
                sleep 500
            }
            winwait, Setup, Ready to install
            send n  ; default .ini folder
            WinWait, IrfanView Setup, successfull ; sic
            send !s ; do not launch
            send d  ; done
            winwaitclose
        "
    else
        w_try "$WINE" $file1
    fi
    w_declare_exe "$W_PROGRAMS_X86_WIN\\IrfanView" "i_view32.exe"
}

#----------------------------------------------------------------

w_metadata ie3 dlls \
    title="Internet Explorer 3" \
    publisher="Microsoft" \
    year="1996" \
    media="download" \
    file1="msie302m95.exe" \
    installed_file1="c:/Program Files/Internet Explorer/INST32.DLL"
    
load_ie3()
{
    w_warn "This is for debugging purposes only, DO NOT INSTALL."

    w_set_winver win95

    # FIXME: /q is quiet, but still has some promps..
    w_download http://www.mirrorservice.org/sites/browsers.evolt.org/browsers/ie/win32/3.02/win95full/msie302m95.exe a55c3834860347342c0b91e0f572124b440eb195
    
    cat > "$W_TMP"/override-dll.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\AppDefaults\infinst2.exe\DllOverrides]
"shell32"="native"
   
_EOF_
    w_try_regedit "$W_TMP_WIN"\\override-dll.reg

    cd "$W_CACHE/$W_PACKAGE"
    $WINE msie302m95.exe
    # IE3 exits with 194 to signal a reboot
    status=$?
    case $status in
        0|194) ;;
        *) w_die ie6 installation failed
    esac

    # FIXME: installer reboots and has a failure, not sure how to detect that cleanly.
}

#----------------------------------------------------------------

# FIXME: ie6 always installs to C:/Program Files even if LANG is de_DE.utf-8,
# so we have to hard code that, but that breaks on 64 bit windows.
w_metadata ie6 dlls \
    title="Internet Explorer 6" \
    publisher="Microsoft" \
    year="2002" \
    media="download" \
    file1="ie60.exe" \
    installed_file1="c:/Program Files/Internet Explorer/iedetect.dll"

load_ie6()
{
    # Installer doesn't support Win64, and I can't find a x64 version on microsoft.com
    if [ $W_ARCH = win64 ]
    then
        w_die "This package does not work on a 64-bit installation"
    fi

    w_download http://download.oldapps.com/Internet_Explorer/ie60.exe 8e483db28ff01a7cabd39147ab6c59753ea1f533

    cd "$W_TMP"
    $WINE "$W_CACHE"/ie6/ie60.exe

    w_call msls31

    # Unregister Wine IE
    if [ ! -f "$W_SYSTEM32_DLLS"/plugin.ocx ]
    then
        w_try $WINE iexplore -unregserver
    fi

    # Change the override to the native so we are sure we use and register them
    w_override_dlls native,builtin iexplore.exe inetcpl.cpl itircl itss jscript mlang mshtml msimtf shdoclc shdocvw shlwapi urlmon

    # Remove the fake dlls, if any
    mv "$W_PROGRAMS_UNIX"/"Internet Explorer"/iexplore.exe "$W_PROGRAMS_UNIX"/"Internet Explorer"/iexplore.exe.bak
    for dll in itircl itss jscript mlang mshtml msimtf shdoclc shdocvw shlwapi urlmon
    do
        test -f "$W_SYSTEM32_DLLS"/$dll.dll &&
        mv "$W_SYSTEM32_DLLS"/$dll.dll "$W_SYSTEM32_DLLS"/$dll.dll.bak
    done

    # The installer doesn't want to install iexplore.exe in XP mode.
    w_set_winver win2k

    # Workaround http://bugs.winehq.org/show_bug.cgi?id=21009
    # See also http://code.google.com/p/winezeug/issues/detail?id=78
    rm -f "$W_SYSTEM32_DLLS"/browseui.dll "$W_SYSTEM32_DLLS"/inseng.dll 
    
    # Otherwise regsvr32 crashes later
    rm -f "$W_SYSTEM32_DLLS"/inetcpl.cpl

    # Work around http://bugs.winehq.org/show_bug.cgi?id=25432
    w_try_cabextract -F inseng.dll "$W_TMP/IE 6.0 Full/ACTSETUP.CAB"
    mv inseng.dll "$W_SYSTEM32_DLLS"
    w_override_dlls native inseng

    cd "$W_TMP/IE 6.0 Full"
    if [ $W_UNATTENDED_SLASH_Q ]
    then
        $WINE IE6SETUP.EXE /q:a /r:n /c:"ie6wzd /S:""#e"" /q:a /r:n"
    else
        $WINE IE6SETUP.EXE
    fi

    # IE6 exits with 194 to signal a reboot
    status=$?
    case $status in
    0|194) ;;
    *) w_die ie6 installation failed
    esac

    # Work around DLL registration bug until ierunonce/RunOnce/wineboot is fixed
    # FIXME: whittle down this list
    cd "$W_SYSTEM32_DLLS"
    for i in actxprxy.dll browseui.dll browsewm.dll cdfview.dll ddraw.dll \
      dispex.dll dsound.dll iedkcs32.dll iepeers.dll iesetup.dll imgutil.dll \
      inetcomm.dll inetcpl.cpl inseng.dll isetup.dll jscript.dll laprxy.dll \
      mlang.dll mshtml.dll mshtmled.dll msi.dll msident.dll \
      msoeacct.dll msrating.dll mstime.dll msxml3.dll occache.dll \
      ole32.dll oleaut32.dll olepro32.dll pngfilt.dll quartz.dll \
      rpcrt4.dll rsabase.dll rsaenh.dll scrobj.dll scrrun.dll \
      shdocvw.dll shell32.dll urlmon.dll vbscript.dll webcheck.dll \
      wshcon.dll wshext.dll asctrls.ocx hhctrl.ocx mscomct2.ocx \
      plugin.ocx proctexe.ocx tdc.ocx webcheck.dll wshom.ocx
    do
        $WINE regsvr32 /i $i > /dev/null 2>&1
    done

    # Set windows version back to user's default. Leave at win2k for better rendering (is there a bug for that?)
    w_unset_winver

    # the ie6 we use these days lacks pngfilt, so grab that
    w_call pngfilt
}

#----------------------------------------------------------------

w_metadata ie7 dlls \
    title="Internet Explorer 7" \
    publisher="Microsoft" \
    year="2008" \
    media="download" \
    file1="IE7-WindowsXP-x86-enu.exe" \
    installed_file1="c:/windows/ie7.log"

load_ie7()
{
    # Unregister Wine IE
    if grep -q -i "wine placeholder" "$W_PROGRAMS_X86_UNIX/Internet Explorer/iexplore.exe"
    then 
        w_try $WINE iexplore -unregserver
    fi
    
    # Change the override to the native so we are sure we use and register them
    w_override_dlls native,builtin iexplore.exe itircl itss jscript mshtml msimtf shdoclc shdocvw shlwapi urlmon xmllite

    # Bundled updspapi cannot work on wine
    w_override_dlls builtin updspapi

    # Remove the fake dlls from the existing WINEPREFIX
    for dll in itircl itss jscript mshtml msimtf shdoclc shdocvw shlwapi urlmon
    do
        test -f "$W_SYSTEM32_DLLS"/$dll.dll &&
        mv "$W_SYSTEM32_DLLS"/$dll.dll "$W_SYSTEM32_DLLS"/$dll.dll.bak
    done

    # See http://bugs.winehq.org/show_bug.cgi?id=16013
    # Find instructions to create this file in dlls/wintrust/tests/crypt.c
    w_download http://winezeug.googlecode.com/svn/trunk/winetricks_files/winetest.cat ac8f50dd54d011f3bb1dd79240dae9378748449f

    # Put a dummy catalog file in place
    mkdir -p "$W_SYSTEM32_DLLS"/catroot/\{f750e6c3-38ee-11d1-85e5-00c04fc295ee\}
    w_try cp -f "$W_CACHE"/ie7/winetest.cat "$W_SYSTEM32_DLLS"/catroot/\{f750e6c3-38ee-11d1-85e5-00c04fc295ee\}/oem0.cat

    # Install
    w_download http://download.microsoft.com/download/3/8/8/38889DC1-848C-4BF2-8335-86C573AD86D9/IE7-WindowsXP-x86-enu.exe d39b89c360fbaa9706b5181ae4718100687a5326
    if test "$W_UNATTENDED_SLASH_Q" = ""
    then
        quiet=""
    else
        quiet="/quiet"
    fi
    cd "$W_CACHE"/ie7
    
    # KLUDGE: if / is writable, having a z: mapping to it causes ie7 to put temporary directories on Z:\
    # so hide it temporarily.  This is not very robust!
    rm -f "$WINEPREFIX/dosdevices/z:.bak_wt"
    mv "$WINEPREFIX/dosdevices/z:" "$WINEPREFIX/dosdevices/z:.bak_wt"

    # FIXME: can't check status, as it always reports failure on wine?
    if w_workaround_wine_bug 21947
    then
        WINEDEBUG=warn+heap $WINE IE7-WindowsXP-x86-enu.exe $quiet
    else
        $WINE IE7-WindowsXP-x86-enu.exe $quiet
    fi

    # END KLUDGE: restore z:, assuming user didn't kill us
    mv "$WINEPREFIX/dosdevices/z:.bak_wt" "$WINEPREFIX/dosdevices/z:"

    # Work around DLL registration bug until ierunonce/RunOnce/wineboot is fixed
    # FIXME: whittle down this list
    cd "$W_SYSTEM32_DLLS"
    for i in actxprxy.dll browseui.dll browsewm.dll cdfview.dll ddraw.dll \
      dispex.dll dsound.dll iedkcs32.dll iepeers.dll iesetup.dll \
      imgutil.dll inetcomm.dll inseng.dll isetup.dll jscript.dll laprxy.dll \
      mlang.dll mshtml.dll mshtmled.dll msi.dll msident.dll \
      msoeacct.dll msrating.dll mstime.dll msxml3.dll occache.dll \
      ole32.dll oleaut32.dll olepro32.dll pngfilt.dll quartz.dll \
      rpcrt4.dll rsabase.dll rsaenh.dll scrobj.dll scrrun.dll \
      shdocvw.dll shell32.dll urlmon.dll vbscript.dll webcheck.dll \
      wshcon.dll wshext.dll asctrls.ocx hhctrl.ocx mscomct2.ocx \
      plugin.ocx proctexe.ocx tdc.ocx webcheck.dll wshom.ocx
    do
        $WINE regsvr32 /i $i > /dev/null 2>&1
    done

    # Seeing is believing
    case $WINETRICKS_GUI in
    none)
        w_warn "To start ie7, use the command $WINE '${W_PROGRAMS_WIN}\\\\Internet Explorer\\\\iexplore'"
        ;;
    *)
        w_warn "Starting ie7.  To start it later, use the command $WINE '${W_PROGRAMS_WIN}\\\\Internet Explorer\\\\iexplore'"
        $WINE "${W_PROGRAMS_WIN}\\Internet Explorer\\iexplore" http://www.microsoft.com/windows/internet-explorer/ie7/ > /dev/null 2>&1 &
        ;;
    esac
}

#----------------------------------------------------------------

w_metadata ie8 dlls \
    title="Internet Explorer 8" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="IE8-WindowsXP-x86-ENU.exe" \
    installed_file1="c:/windows/ie8_main.log"

load_ie8()
{
    # Unregister Wine IE
    if grep -q -i "wine placeholder" "$W_PROGRAMS_X86_UNIX/Internet Explorer/iexplore.exe"
    #if [ ! -f "$W_SYSTEM32_DLLS"/plugin.ocx ]
    then 
        w_try $WINE iexplore -unregserver
    fi

    w_call msls31
    
    # Change the override to the native so we are sure we use and register them
    w_override_dlls native,builtin iexplore.exe itircl itss jscript msctf mshtml shdoclc shdocvw shlwapi urlmon xmllite

    # Bundled updspapi cannot work on wine
    w_override_dlls builtin updspapi
    
    # Remove the fake dlls from the existing WINEPREFIX
    for dll in browseui.dll inseng.dll itircl itss jscript msctf mshtml  shdoclc shdocvw shlwapi urlmon
    do
        test -f "$W_SYSTEM32_DLLS"/$dll.dll &&
        mv "$W_SYSTEM32_DLLS"/$dll.dll "$W_SYSTEM32_DLLS"/$dll.dll.bak
    done

    # See http://bugs.winehq.org/show_bug.cgi?id=16013
    # Find instructions to create this file in dlls/wintrust/tests/crypt.c
    w_download http://winezeug.googlecode.com/svn/trunk/winetricks_files/winetest.cat ac8f50dd54d011f3bb1dd79240dae9378748449f

    # Put a dummy catalog file in place
    mkdir -p "$W_SYSTEM32_DLLS"/catroot/\{f750e6c3-38ee-11d1-85e5-00c04fc295ee\}
    w_try cp -f "$W_CACHE"/ie8/winetest.cat "$W_SYSTEM32_DLLS"/catroot/\{f750e6c3-38ee-11d1-85e5-00c04fc295ee\}/oem0.cat

    w_download http://download.microsoft.com/download/C/C/0/CC0BD555-33DD-411E-936B-73AC6F95AE11/IE8-WindowsXP-x86-ENU.exe e489483e5001f95da04e1ebf3c664173baef3e26 
    if [ $W_UNATTENDED_SLASH_Q ]
    then
        quiet="/quiet /forcerestart"
    else
        quiet=""
    fi
    cd "$W_CACHE"/ie8

    # KLUDGE: if / is writable, having a z: mapping to it causes ie8 to put temporary directories on Z:\
    # so hide it temporarily.  This is not very robust!
    rm -f "$WINEPREFIX/dosdevices/z:.bak_wt"
    mv "$WINEPREFIX/dosdevices/z:" "$WINEPREFIX/dosdevices/z:.bak_wt"

    # FIXME: There's an option for /updates-noupdates to disable checking for updates, but that 
    # forces the install to fail on Wine. Not sure if it's an IE8 or Wine bug...
    # FIXME: can't check status, as it always reports failure on wine?
    $WINE IE8-WindowsXP-x86-ENU.exe $quiet
    # END KLUDGE: restore z:, assuming user didn't kill us
    mv "$WINEPREFIX/dosdevices/z:.bak_wt" "$WINEPREFIX/dosdevices/z:"

    # Work around DLL registration bug until ierunonce/RunOnce/wineboot is fixed
    # FIXME: whittle down this list
    cd "$W_SYSTEM32_DLLS"
    for i in actxprxy.dll browseui.dll browsewm.dll cdfview.dll ddraw.dll \
      dispex.dll dsound.dll iedkcs32.dll iepeers.dll iesetup.dll \
      imgutil.dll inetcomm.dll isetup.dll jscript.dll laprxy.dll \
      mlang.dll msctf.dll mshtml.dll mshtmled.dll msi.dll msimtf.dll msident.dll \
      msoeacct.dll msrating.dll mstime.dll msxml3.dll occache.dll \
      ole32.dll oleaut32.dll olepro32.dll pngfilt.dll quartz.dll \
      rpcrt4.dll rsabase.dll rsaenh.dll scrobj.dll scrrun.dll \
      shdocvw.dll shell32.dll urlmon.dll vbscript.dll webcheck.dll \
      wshcon.dll wshext.dll asctrls.ocx hhctrl.ocx mscomct2.ocx \
      plugin.ocx proctexe.ocx tdc.ocx uxtheme.dll webcheck.dll wshom.ocx
    do
        $WINE regsvr32 /i $i > /dev/null 2>&1
    done

    if w_workaround_wine_bug 25648 "Setting TabProcGrowth=0 to avoid hang"
    then
        cat > "$W_TMP"/set-tabprocgrowth.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Microsoft\Internet Explorer\Main]
"TabProcGrowth"=dword:00000000

_EOF_
        w_try_regedit "$W_TMP_WIN"\\set-tabprocgrowth.reg
    fi

    # Seeing is believing
    case $WINETRICKS_GUI in
    none)
        w_warn "To start ie8, use the command $WINE '${W_PROGRAMS_WIN}\\\\Internet Explorer\\\\iexplore'"
        ;;
    *)
        w_warn "Starting ie8.  To start it later, use the command $WINE '${W_PROGRAMS_WIN}\\\\Internet Explorer\\\\iexplore'"
        $WINE "${W_PROGRAMS_WIN}\\Internet Explorer\\iexplore" http://www.microsoft.com/windows/internet-explorer > /dev/null 2>&1 &
        ;;
    esac
}

#----------------------------------------------------------------

w_metadata mingw apps \
    title="Minimalist GNU for Windows, including GCC for Windows" \
    publisher="GNU" \
    year="2010-2011" \
    media="download" \
    file1="binutils-2.21-2-mingw32-bin.tar.lzma" \
    installed_exe1="c:/MinGW/bin/gcc.exe" \
    homepage="http://mingw.org/wiki/Getting_Started"

load_mingw()
{
    w_download $WINETRICKS_SOURCEFORGE/mingw/files/binutils-2.21-2-mingw32-bin.tar.lzma
    w_download $WINETRICKS_SOURCEFORGE/mingw/files/gcc-core-4.5.2-1-mingw32-bin.tar.lzma
    w_download $WINETRICKS_SOURCEFORGE/mingw/files/libgcc-4.5.2-1-mingw32-dll-1.tar.lzma
    w_download $WINETRICKS_SOURCEFORGE/mingw/files/libgmpxx-5.0.1-1-mingw32-dll-4.tar.lzma
    w_download $WINETRICKS_SOURCEFORGE/mingw/files/libgmp-5.0.1-1-mingw32-dll-10.tar.lzma
    w_download $WINETRICKS_SOURCEFORGE/mingw/files/libmpc-0.8.1-1-mingw32-dll-2.tar.lzma
    w_download $WINETRICKS_SOURCEFORGE/mingw/files/libiconv-1.13.1-1-mingw32-dll-2.tar.lzma
    w_download $WINETRICKS_SOURCEFORGE/mingw/files/mingwrt-3.18-mingw32-dev.tar.gz
    w_download $WINETRICKS_SOURCEFORGE/mingw/files/mingwrt-3.18-mingw32-dll.tar.gz
    w_download $WINETRICKS_SOURCEFORGE/mingw/files/libmpfr-2.4.1-1-mingw32-dll-1.tar.lzma
    w_download $WINETRICKS_SOURCEFORGE/mingw/files/libpthread-2.8.0-3-mingw32-dll-2.tar.lzma
    w_download $WINETRICKS_SOURCEFORGE/mingw/files/w32api-3.15-1-mingw32-dev.tar.lzma

    mkdir "$W_DRIVE_C"/MinGW
    cd "$W_DRIVE_C"/MinGW
    lzma -d -c "$W_CACHE"/mingw/binutils-2.21-2-mingw32-bin.tar.lzma | tar xf -
    gzip -d -c "$W_CACHE"/mingw/mingwrt-3.18-mingw32-dev.tar.gz | tar xf -
    gzip -d -c "$W_CACHE"/mingw/mingwrt-3.18-mingw32-dll.tar.gz | tar xf -
    lzma -d -c "$W_CACHE"/mingw/w32api-3.15-1-mingw32-dev.tar.lzma | tar xf -
    lzma -d -c "$W_CACHE"/mingw/libgmp-5.0.1-1-mingw32-dll-10.tar.lzma | tar xf -
    lzma -d -c "$W_CACHE"/mingw/libmpc-0.8.1-1-mingw32-dll-2.tar.lzma | tar xf -
    lzma -d -c "$W_CACHE"/mingw/libgmpxx-5.0.1-1-mingw32-dll-4.tar.lzma | tar xf -
    lzma -d -c "$W_CACHE"/mingw/libiconv-1.13.1-1-mingw32-dll-2.tar.lzma | tar xf -
    lzma -d -c "$W_CACHE"/mingw/libmpfr-2.4.1-1-mingw32-dll-1.tar.lzma | tar xf -
    lzma -d -c "$W_CACHE"/mingw/libpthread-2.8.0-3-mingw32-dll-2.tar.lzma | tar xf -
    lzma -d -c "$W_CACHE"/mingw/libgcc-4.5.2-1-mingw32-dll-1.tar.lzma | tar xf -
    lzma -d -c "$W_CACHE"/mingw/gcc-core-4.5.2-1-mingw32-bin.tar.lzma | tar xf -

    w_append_path 'C:\MinGW\bin'
}

#----------------------------------------------------------------

w_metadata mpc apps \
    title="Media Player Classic - Home Cinema" \
    publisher="doom9 folks" \
    year="2010" \
    media="download" \
    file1="MPC-HomeCinema.1.4.2499.0.x86.zip" \
    installed_file1="$W_PROGRAMS_X86_WIN/Media Player Classic/mpc-hc.exe" \
    homepage="http://mpc-hc.sourceforge.net"

load_mpc()
{
    w_download $WINETRICKS_SOURCEFORGE/project/mpc-hc/MPC%20HomeCinema%20-%20Win32/MPC-HC%20v1.4.2499.0_32%20bits/MPC-HomeCinema.1.4.2499.0.x86.zip 9f8c4a8e70fa36ffa68f878d13adc8b09b915ece

    mkdir -p "$W_PROGRAMS_X86_UNIX/Media Player Classic"
    cd "$W_PROGRAMS_X86_UNIX/Media Player Classic"
    w_try_unzip -j "$W_CACHE/mpc/MPC-HomeCinema.1.4.2499.0.x86.zip"

    w_declare_exe "$W_PROGRAMS_X86_WIN\Media Player Classic" mpc-hc.exe
}

#----------------------------------------------------------------

w_metadata mspaint apps \
    title="MS Paint" \
    publisher="Microsoft" \
    year="2001" \
    media="download" \
    file1="paintnt.exe" \
    installed_exe1="c:/windows/MSPAINT.EXE"

load_mspaint()
{
    # http://helpforlinux.blogspot.com/2008/12/run-ms-paint-in-linux.html
    w_download http://download.microsoft.com/download/winntwks40/paint/1/nt4/en-us/paintnt.exe a22c4e367ef9d2cd23f0a8ae8d9ebff5bc1e8a0b
    w_try_unzip "$W_CACHE"/mspaint/paintnt.exe -d "$W_WINDIR_UNIX"

    w_declare_exe "$W_WINDIR_UNIX" "mspaint.exe"
}

#----------------------------------------------------------------

w_metadata nook apps \
    title="Nook for PC (e-book reader)" \
    publisher="Barnes & Noble" \
    year="2011" \
    media="download" \
    file1="bndr2_setup_latest.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Barnes & Noble/BNDesktopReader/BNDReader.exe" \
    homepage="http://www.barnesandnoble.com/u/free-nook-apps/379002321/"

load_nook()
{
    # dates from curl --head
    # 10 Feb 2011 sha1sum 4a06a529b93ed33c3518326d874b40d8d7b70e7a
    # 7 Oct 2011 sha1sum 3b0301bd55471cc47cced44501547411fac9fcea
    w_download http://images.barnesandnoble.com/PResources/download/eReader2/bndr2_setup_latest.exe 3b0301bd55471cc47cced44501547411fac9fcea
    cd "$W_CACHE"/nook
    $WINE $file1 ${W_OPT_UNATTENDED:+ /S}
    # normally has exit status 199?
    w_declare_exe "$W_PROGRAMS_WIN\\Barnes & Noble\\BNDesktopReader" "BNDReader.exe"
}

#----------------------------------------------------------------

w_metadata office2003pro apps \
    title="Microsoft Office 2003 Professional" \
    publisher="Microsoft" \
    year="2002" \
    media="cd" \
    file1="setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Office/Office11/WINWORD.EXE"

load_office2003pro()
{
    w_mount OFFICE11
    w_read_key

    w_ahk_do "
        if ( w_opt_unattended > 0 ) {
            run ${W_ISO_MOUNT_LETTER}:setup.exe /EULA_ACCEPT=YES /PIDKEY=$W_KEY
        } else {
            run ${W_ISO_MOUNT_LETTER}:setup.exe
        }
        SetTitleMatchMode, 2
        WinWait,Microsoft Office 2003 Setup, Welcome
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            WinWait,Microsoft Office 2003 Setup,Key
            Sleep 500
            ControlClick Button1 ; Next
            WinWait,Microsoft Office 2003 Setup,Initials
            Sleep 500
            ControlClick Button1 ; Next
            WinWait,Microsoft Office 2003 Setup,End-User
            Sleep 500
            ControlClick Button1 ; I accept
            ControlClick Button2 ; Next
            WinWait,Microsoft Office 2003 Setup,Recommended
            Sleep 500
            ControlClick Button7 ; Next
            WinWait,Microsoft Office 2003 Setup,Summary
            Sleep 500
            ControlClick Button1 ; Install
        }
        WinWait,Microsoft Office 2003 Setup,Completed
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button2 ; Finish
        }
        WinWaitClose
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Office\\Office11" WINWORD.EXE  word2003
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Office\\Office11" EXCEL.EXE    excel2003
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Office\\Office11" POWERPNT.EXE powerpoint2003
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Office\\Office11" MSACCESS.EXE access2003
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Office\\Office11" OUTLOOK.EXE  outlook2003
}

#----------------------------------------------------------------

w_metadata office2007pro apps \
    title="Microsoft Office 2007 Professional" \
    publisher="Microsoft" \
    year="2006" \
    media="cd" \
    file1="setup.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Microsoft Office/Office12/WINWORD.EXE"

load_office2007pro()
{
    if w_workaround_wine_bug 14980 "Using native riched20"
    then
        w_override_app_dlls winword.exe n riched20
        w_override_app_dlls excel.exe n riched20
        w_override_app_dlls powerpnt.exe n riched20
        w_override_app_dlls msaccess.exe n riched20
        w_override_app_dlls outlook.exe n riched20
        w_override_app_dlls mspub.exe n riched20
        w_override_app_dlls infopath.exe n riched20
    fi

    w_mount OFFICE12
    w_read_key

    if test $W_OPT_UNATTENDED
    then
        # See
        # http://blogs.technet.com/b/office_resource_kit/archive/2009/01/29/configure-a-silent-install-of-the-2007-office-system-with-config-xml.aspx
        # http://www.symantec.com/connect/articles/office-2007-silent-installation-lessons-learned
        cat > "$W_TMP"/config.xml <<__EOF__
<Configuration Product="ProPlus">
<Display Level="none" CompletionNotice="no" SuppressModal="yes" AcceptEula="yes" />
<PIDKEY Value="$W_KEY" />
</Configuration>
__EOF__
        $WINE ${W_ISO_MOUNT_LETTER}:setup.exe /config "$W_TMP_WIN"\\config.xml

        status=$?
        case $status in
        0|43) ;;
        78)
            w_die "Installing $W_PACKAGE failed, product key $W_KEY \
might be wrong. Try again without -q, or put correct key in \
$W_CACHE/$W_PACKAGE/key.txt and rerun."
            ;;
        *) 
            w_die "Installing $W_PACKAGE failed."
            ;;
        esac

    else
        w_try $WINE ${W_ISO_MOUNT_LETTER}:setup.exe
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Office\\Office12" WINWORD.EXE  word2007
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Office\\Office12" EXCEL.EXE    excel2007
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Office\\Office12" POWERPNT.EXE powerpoint2007
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Office\\Office12" MSACCESS.EXE access2007
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Office\\Office12" OUTLOOK.EXE  outlook2007
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Office\\Office12" MSPUB.EXE  publisher2007
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Office\\Office12" INFOPATH.EXE  infopath2007
}

#----------------------------------------------------------------

w_metadata opera apps \
    title="Opera 11" \
    publisher="Opera Software" \
    year="2011" \
    media="download" \
    file1="Opera_1150_en_Setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Opera/opera.exe"

load_opera()
{
    w_download ftp://ftp.opera.com/pub/opera/win/1150/en/Opera_1150_en_Setup.exe df50c7aed50e92af858e8834f833dd0543014b46
    cd "$W_CACHE"/$W_PACKAGE
    w_try $WINE $file1 ${W_OPT_UNATTENDED:+ /silent /launchopera 0 /allusers}
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Opera" opera.exe
}

#----------------------------------------------------------------

w_metadata psdk2003 apps \
    title="MS Platform SDK 2003" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="PSDK-x86.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Microsoft Platform SDK for Windows Server 2003 R2/SetEnv.Cmd"

load_psdk2003()
{
    w_call mfc42

    # Note: aborts on 64 bit windows with dialog saying "don't run on WoW"
    # http://www.microsoft.com/downloads/details.aspx?familyid=0baf2b35-c656-4969-ace8-e4c0c0716adb
    w_download http://download.microsoft.com/download/f/a/d/fad9efde-8627-4e7a-8812-c351ba099151/PSDK-x86.exe 5c7dc2e1eb902b376d7797cc383fefdfc64ff9c9
    w_warn "This can take up to an hour."

    cd "$W_CACHE"/psdk2003
    # FIXME: says it accepts /q, but that doesn't work, so script this
    # with autohotkey in -q mode.
    w_try $WINE PSDK-x86.exe
}

#----------------------------------------------------------------

w_metadata psdkwin7 apps \
    title="MS Windows 7 SDK" \
    publisher="Microsoft" \
    year="2009" \
    media="download" \
    file1="winsdk_web.exe" \
    installed_exe1="C:/Program Files/Microsoft SDKs/Windows/v7.0/Bin/SetEnv.Cmd"

load_psdkwin7()
{
    # http://www.microsoft.com/downloads/details.aspx?FamilyID=c17ba869-9671-4330-a63e-1fd44e0e2505&displaylang=en
    w_call dotnet20
    if w_workaround_wine_bug 21509 "" 1.2,
    then
        w_call gdiplus     # work around http://bugs.winehq.org/show_bug.cgi?id=21509
    fi
    w_call mfc42   # need mfc42u, or setup will abort
    # don't have a working unattended recipe.  Maybe we'll have to
    # do an autohotkey script until msft gets its act together:
    # http://social.msdn.microsoft.com/Forums/en-US/windowssdk/thread/c053b616-7d5b-405d-9841-ec465a8e21d5
    w_download http://download.microsoft.com/download/7/A/B/7ABD2203-C472-4036-8BA0-E505528CCCB7/winsdk_web.exe a01dcc67a38f461e80ea649edf1353f306582507
    cd "$W_CACHE"/psdkwin7
    if w_workaround_wine_bug 21596
    then
        w_warn "When given a choice, select only C++ compilers and headers, the other options don't work yet.  See http://bugs.winehq.org/show_bug.cgi?id=21596"
    fi
    w_try $WINE winsdk_web.exe

    if w_workaround_wine_bug 21362
    then
        # Assume user installed in default location
        cat > "$W_TMP"/set-psdk7.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SDKs]

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SDKs\Windows]
"CurrentVersion"="v7.0"
"CurrentInstallFolder"="C:\\\Program Files\\\Microsoft SDKs\\\Windows\\\v7.0\\\"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v7.0]
"InstallationFolder"="C:\\\Program Files\\\Microsoft SDKs\\\Windows\\\v7.0\\\"
"ProductVersion"="7.0.7600.16385.40715"
"ProductName"="Microsoft Windows SDK for Windows 7 (7.0.7600.16385.40715)"
_EOF_
        w_try_regedit "$W_TMP_WIN"\\set-psdk7.reg
    fi
}

#----------------------------------------------------------------

w_metadata python26 apps \
    title="Python Interpreter, version 2.6.2" \
    publisher="Python Software Foundaton" \
    year="2009" \
    media="download" \
    file1="python-2.6.2.msi" \
    installed_exe1="c:/Python26/python.exe"

load_python26()
{
    w_download http://www.python.org/ftp/python/2.6.2/python-2.6.2.msi 2d1503b0e8b7e4c72a276d4d9027cf4856b208b8
    w_download $WINETRICKS_SOURCEFORGE/project/pywin32/pywin32/Build%20214/pywin32-214.win32-py2.6.exe eca58f29b810d8e3e7951277ebb3e35ac35794a3
    cd "$W_CACHE"/python26
    w_try $WINE msiexec /i python-2.6.2.msi ALLUSERS=1 $W_UNATTENDED_SLASH_Q

    w_ahk_do "
        SetTitleMatchMode, 2
        run pywin32-214.win32-py2.6.exe
        WinWait, Setup, Wizard will install pywin32
        if ( w_opt_unattended > 0 ) {
             ControlClick Button2   ; next
             WinWait, Setup, Python 2.6 is required
             ControlClick Button3   ; next
             WinWait, Setup, Click Next to begin
             ControlClick Button3   ; next
             WinWait, Setup, finished
             ControlClick Button4   ; Finish
        }
        WinWaitClose
        "
}

#----------------------------------------------------------------

w_metadata python26_comtypes apps \
    title="Comtypes 0.6.2 for Python 2.6" \
    publisher="theller" \
    year="2010" \
    media="download" \
    file1="comtypes-0.6.2.zip" \
    installed_file1="c:/Python26/Lib/site-packages/comtypes-0.6.2-py2.6.egg-info" \
    homepage="http://sourceforge.net/projects/comtypes"

load_python26_comtypes()
{
    w_call python26

    w_download $WINETRICKS_SOURCEFORGE/comtypes/0.6.2/comtypes-0.6.2.zip b84f4e3050652d494e8c8d9d6d6f221c124ffba9

    cd "$W_TMP"
    w_try_unzip "$W_CACHE/$W_PACKAGE"/comtypes-0.6.2.zip
    cd comtypes-0.6.2
    w_try $WINE "C:\Python26\python.exe" setup.py install
}

#----------------------------------------------------------------

w_metadata spotify apps \
    title="Spotify - All the music, all the time" \
    publisher="Spotify" \
    year="2011" \
    media="download" \
    file1="SpotifyInstaller.exe" \
    installed_exe1="c:/users/$LOGNAME/Application Data/Spotify/spotify.exe"

load_spotify()
{
    #             0.4.9  f26712b576baa1c78112a05474293deef39f7f62 
    # 29 Apr 2011 0.4.10 4becb04f8ad08a3ff59d6830bf1d998fcca1815b
    # 7 may 2011         a3c7daecf1051c4aaab544e6b66753617c0706b1
    # updates too frequently to check checksum :-(
    w_download http://www.spotify.com/download/Spotify%20Installer.exe

    cd "$W_CACHE"/spotify
    # w_download doesn't handle renaming for us without a checksum, tsk.
    # And autohotkey thinks % is a variable reference.
    if test ! -f SpotifyInstaller.exe
    then
        cp Spotify%20Installer.exe SpotifyInstaller.exe
    fi

    # Install is silent by default, and always starts app
    # So all we have to do here is close app if we want unattended install
    w_ahk_do "
        SetTitleMatchMode, 2
        run SpotifyInstaller.exe
        WinWait, ahk_class SpotifyMainWindow
        if ( w_opt_unattended > 0 ) {
            WinClose
        }
        WinWaitClose
        "

    if w_workaround_wine_bug 27476 "Installing winhttp to work around a facebook integration crash on login"
    then
        w_call winhttp
    fi

    w_declare_exe "c:\\users\\$LOGNAME\\Application Data\\Spotify" spotify.exe
}

#----------------------------------------------------------------

w_metadata safari apps \
    title="Safari" \
    publisher="Apple" \
    year="2010" \
    media="download" \
    file1="SafariSetup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Safari/Safari.exe"

load_safari()
{
    w_download http://appldnld.apple.com.edgesuite.net/content.info.apple.com/Safari5/061-7138.20100607.Y7U87/SafariSetup.exe e56d5d79d9cfbb85ac46ac78aa497d7f3d8dbc3d

    cd "$W_CACHE"/$W_PACKAGE

    if w_workaround_wine_bug 21146
    then
        w_try mkdir -p "$W_APPDATA_UNIX/Apple Computer/Preferences"
        cat > "$W_APPDATA_UNIX/Apple Computer/Preferences/com.apple.Safari.plist" <<_EOF_
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>LastDisplayedWelcomePageVersionString</key>
        <string>4.0</string>
</dict>
</plist>
_EOF_
    fi

    if test $W_OPT_UNATTENDED
    then
        w_warn "Safari's silent install is broken under wine. See http://bugs.winehq.org/show_bug.cgi?id=23493. You should do a regular install if you want to use Safari."
        w_try $WINE SafariSetup.exe /qn
    else
        w_try $WINE SafariSetup.exe
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Safari" "Safari.exe"
}

#----------------------------------------------------------------

w_metadata sketchup apps \
    title="Sketchup 8" \
    publisher="Google" \
    year="2010" \
    media="download" \
    file1="GoogleSketchUpWEN.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Google/Google SketchUp 8/SketchUp.exe"

load_sketchup()
{
    w_download http://dl.google.com/sketchup/GoogleSketchUpWEN.exe 84a72bbe9fd131c34bad855c6781c98a8196b7bf

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run GoogleSketchUpWEN.exe
        WinWait, SketchUp, Welcome
        if ( w_opt_unattended > 0 ) {
            Sleep 2000
            Send {Enter}
            WinWait, SketchUp, License
            Sleep 500
            ControlClick Button1 ; accept
            Sleep 500
            ControlClick Button3 ; Next
            WinWait, SketchUp, Destination
            Sleep 500
            ControlClick Button1 ; Next
            WinWait, SketchUp, Ready
            Sleep 500
            ControlClick Button1 ; Install
        }
        WinWait, SketchUp, Completed
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button1 ; Finish
        }
        WinWaitClose
    "

    if w_workaround_wine_bug 14045
    then
        echo "Setting GLConfig Display HW_OK to 1"
        cat > "$W_TMP"/glconfigdisplay.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Google\SketchUp8\GLConfig\Display]
"HW_OK"="1"

_EOF_
        w_try_regedit "$W_TMP_WIN"\\glconfigdisplay.reg
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Google\\Google SketchUp 8" "SketchUp.exe"
}

#----------------------------------------------------------------

w_metadata songbird apps \
    title="Songbird" \
    publisher="POTI" \
    year="2010" \
    media="manual_download" \
    file1="Songbird_1.10.1-2160_windows-i686-msvc8.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Songbird/songbird.exe" \
    homepage="http://getsongbird.com"

load_songbird()
{
    w_download_manual \
        http://getsongbird.com/system-requirements.php Songbird_1.10.1-2160_windows-i686-msvc8.exe \
        3939988180e1bfba3f28ff5720942cbbc20b7fbf
    cd "$W_CACHE/songbird"
    w_try $WINE $file1 ${W_OPT_UNATTENDED:+ /S}
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Songbird" songbird.exe
}

#----------------------------------------------------------------

w_metadata steam apps \
    title="Steam" \
    publisher="Valve" \
    year="2010" \
    media="download" \
    file1="SteamInstall.msi" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/Steam.exe"

load_steam()
{
    # 18 Mar 2011 7f2fee9ffeaba8424a6c76d6c95b794735ac9959
    w_download http://storefront.steampowered.com/download/SteamInstall.msi 7f2fee9ffeaba8424a6c76d6c95b794735ac9959
    cd "$W_CACHE"/steam
    
    # Install corefonts first, so if the user doesn't have cabextract/Wine with cab support, we abort before installing Steam.
    # FIXME: support using Wine's cab support
    if ! test -f "$W_FONTSDIR_UNIX/Times.TTF" && \
        w_workaround_wine_bug 22751 "Installing corefonts to prevent a Steam crash"
    then
        w_call corefonts
    fi

    w_try $WINE msiexec /i SteamInstall.msi $W_UNATTENDED_SLASH_Q

    # Not all users need this disabled, but let's play it safe for now
    if w_workaround_wine_bug 22053 "Disabling gameoverlayrenderer to prevent game crashes on some machines."
    then
        w_override_dlls disabled gameoverlayrenderer
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Steam" "Steam.exe"
}

#----------------------------------------------------------------

w_metadata utorrent apps \
    title="µTorrent 2.2.1" \
    publisher="BitTorrent" \
    year="2011" \
    media="download" \
    file1="utorrent.exe" \
    installed_exe1="c:/windows/utorrent.exe"

load_utorrent()
{
    # Torrent client supported on Windows,Mac OSX, Linux through WINE
    # Oct 2010 2.0.4 sha1sum 8382b8a7bc625d68b6efe18a7b9e5488dc0119ee
    # Nov 6 2010 2.0.4 sha1sum 263a91693d0976473cd321cd6f1b0103a814f3ad
    # Dev 17 2010 2.2 sha1sum 0c95bdfba07421fe706b30ee2ec6779217c5dce4, hangs, see wine bug 24946
    # Feb 11 2011 2.2.1beta sha1sum 82e81e1484b4e8654b83908509f3777532c6fcb3
    # Mar 28 2011 2.2.1 sha1sum 7049109e4d3f72338d54b42ae37ecf38fafed46f
    # Apr 14 2011 2.2.1 sha1sum b1378d7cbe5d1e1b168ce44def8f59facdc046d5
    # 7 May 2011        sha1sum 2932c9ed1c1225e485f7e3dd2ed267aa7d568c80
    # 14 May 2011 removed checksum, updates too quickly to track :-(
    w_download http://download.utorrent.com/2.2.1/utorrent.exe

    w_try cp -f "$W_CACHE/utorrent/utorrent.exe" "$W_WINDIR_UNIX"/utorrent.exe

    w_declare_exe "c:\\windows" "utorrent.exe"
}

#----------------------------------------------------------------

w_metadata utorrent3 apps \
    title="µTorrent 3.0" \
    publisher="BitTorrent" \
    year="2011" \
    media="download" \
    file1="utorrent-3.0-latest.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/uTorrent/uTorrent.exe"

load_utorrent3()
{
    # 15 Apr 2011: sha1sum a5f198207919e8f2091a9b4459d7d6fc8a63e874
    # 27 Apr 2011: sha1sum d969f0c61cf2b2afaea4121f097ef690dffbf771
    # 7 May 2011: sha1sum 1793a7b15d905a9fa82f9a969a96fa53abaac04c
    # 14 May: removed checksum, changes too often to track
    w_download http://download.utorrent.com/beta/utorrent-3.0-latest.exe

    case "$W_OPT_UNATTENDED" in
    0) _W_opt="" ;;
    *) _W_opt="/PERFORMINSTALL /NORUN" ;;
    esac
    cd "$W_CACHE/$W_PACKAGE"
    $WINE utorrent-3.0-latest.exe $_W_opt

    # dang installer exits with status 1 on success
    status=$?
    case $status in
    0|1) ;;
    *) w_die "Note: utorrent installer returned status '$status'.  Aborting." ;;
    esac

    # for backwards compatibility
    rm -f "$W_WINDIR_UNIX"/utorrent.exe
    w_try cp -f "$W_PROGRAMS_X86_UNIX/uTorrent/uTorrent.exe" "$W_WINDIR_UNIX"/uTorrent.exe

    w_declare_exe "$W_PROGRAMS_X86_WIN\\uTorrent" "uTorrent.exe"
}

#----------------------------------------------------------------

w_metadata vc2005express apps \
    title="MS Visual C++ 2005 Express" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="VC.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Visual Studio 8/Common7/IDE/VCExpress.exe"

load_vc2005express()
{
    # Thanks to http://blogs.msdn.com/astebner/articles/551674.aspx for the recipe
    w_call dotnet20
    if w_workaround_wine_bug 20029 ""  1.3.9,
    then
        w_call msxml6
    fi

    # http://blogs.msdn.com/b/astebner/archive/2006/03/14/551674.aspx
    # http://go.microsoft.com/fwlink/?linkid=57034
    w_download http://download.microsoft.com/download/A/9/1/A91D6B2B-A798-47DF-9C7E-A97854B7DD18/VC.iso 1ae44e4eaf8c61c3a39e573fd6efd9889e940529

    # Unpack ISO (how handy that 7z can do this!)
    cd "$W_TMP"
    w_try 7z x "$W_CACHE"/vc2005express/VC.iso

    if [ $W_UNATTENDED_SLASH_Q ]
    then
        chmod +x Ixpvc.exe
        # Add /qn after ReallySuppress for a really silent install (but then you won't see any errors)

        w_try $WINE Ixpvc.exe /t:"$W_TMP_WIN" /q:a /c:"msiexec /i vcsetup.msi VSEXTUI=1 ADDLOCAL=ALL REBOOT=ReallySuppress"

    else
        if w_workaround_wine_bug 25331
        then
            w_warn "Install fails with wine older than 1.1.35.  With wine-1.3.5 or higher, interactive install fails, but quiet mode (-q option) may work."
        fi
        w_try $WINE setup.exe
        w_ahk_do "
            SetTitleMatchMode, 2
            WinWait, Visual C++ 2005 Express Edition Setup
            WinWaitClose, Visual C++ 2005 Express Edition Setup
        "
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Visual Studio 8\\Common7\\IDE" "VCExpress.exe"
}

#----------------------------------------------------------------

w_metadata vc2005trial apps \
    title="MS Visual C++ 2005 Trial" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="En_vs_2005_vsts_180_Trial.img" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Visual Studio 8/Common7/IDE/devenv.exe"

load_vc2005trial()
{
    if w_workaround_wine_bug 26162 "Install fails with spurious error about custom action" ,1.3.4 1.3.15,
    then
        w_die "Please upgrade to wine-1.3.15 or later to install this app"
    fi
    if w_workaround_wine_bug 25331 "Install fails with error about custom rollback actions" 1.1.35,1.3.4 1.3.13,
    then
        w_die "Please upgrade to wine-1.3.15 or later to install this app"
    fi
    w_call dotnet20
    if w_workaround_wine_bug 20029 "Installing native msxml6"  1.3.9,
    then
        w_call msxml6
    fi
    # Without mfc42.dll, pidgen.dll won't load, and the app claims "A trial edition is alread installed..."
    w_call mfc42

    w_download http://download.microsoft.com/download/6/f/5/6f5f7a01-50bb-422d-8742-c099c8896969/En_vs_2005_vsts_180_Trial.img f66ae07618d67e693ca0524d3582208c20e07823

    # Unpack ISO (how handy that 7z can do this!)
    # Only the windows version of 7z can handle .img files?
    WINETRICKS_OPT_SHAREDPREFIX=1 w_call 7zip
    cd "$W_PROGRAMS_X86_UNIX"/7-Zip
    w_try $WINE 7z.exe x -y -o"$W_TMP_WIN" "$W_CACHE_WIN\\vc2005trial\\En_vs_2005_vsts_180_Trial.img"

    cd "$W_TMP"

    # Sanity check...
    w_verify_sha1sum 15433993ab7573c5154dbea2dcb65450f2adbf5c vs/wcu/runmsi.exe

    cd vs/Setup
    w_ahk_do "
        SetTitleMatchMode 2
        run setup.exe
        winwait, Visual Studio, Setup is loading
        if ( w_opt_unattended > 0 ) {
            winwait, Visual Studio, Loading completed
            controlclick, button2
            winwait, Visual Studio, Select features
            controlclick, button38
            controlclick, button40
            winwait, Visual Studio, You have chosen
            controlclick, button1
            winwait, Visual Studio, Select features
            controlclick, button11
        }
        ;this can take a while
        winwait, Finish Page
        if ( w_opt_unattended > 0 )
            controlclick, button2
        winwaitclose, Finish Page
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Visual Studio 8\\Common7\\IDE" "devenv.exe"
}

#----------------------------------------------------------------

w_metadata vlc apps \
    title="VLC media player" \
    publisher="videolan.org" \
    year="2010" \
    media="download" \
    file1="vlc-1.1.9-win32.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/VideoLAN/VLC/vlc.exe" \
    homepage="http://www.videolan.org/vlc/"

load_vlc()
{
    w_download $WINETRICKS_SOURCEFORGE/vlc/vlc-1.1.9-win32.exe 7128f6e43d6550fcc2574b9c82c5153ff47efcf6
    cd "$W_CACHE"/vlc
    w_try $WINE $file1 ${W_OPT_UNATTENDED:+ /S}
    w_declare_exe "$W_PROGRAMS_X86_WIN\\VideoLAN\\VLC" vlc.exe
}

#----------------------------------------------------------------

w_metadata winamp apps \
    title="Winamp" \
    publisher="AOL (Nullsoft)" \
    year="2011" \
    media="download" \
    file1="winamp5621_full_emusic-7plus_en-us.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Winamp/winamp.exe" \
    homepage="http://www.winamp.com"

load_winamp()
{
    w_info "may send information while installing, see http://www.microsoft.com/security/portal/Threat/Encyclopedia/Entry.aspx?threatid=159633"
    w_download \
        http://download.nullsoft.com/winamp/client/winamp5621_full_emusic-7plus_en-us.exe afc172039db52fdc202114bec7bcf8b5bf2468bb
    cd "$W_CACHE/$W_PACKAGE"
    if test $W_OPT_UNATTENDED
    then
        w_ahk_do "
            SetWinDelay 500
            SetTitleMatchMode, 2
            Run $file1
            WinWait, Winamp Installer, Welcome to the Winamp installer
            ControlClick, Button2
            WinWait, Winamp Installer, License Agreement
            ControlClick, Button2
            WinWait, Winamp Installer, Choose Install Location
            ControlClick, Button2
            WinWait, Winamp Installer, Choose Components
            ControlClick, Button2
            WinWait, Winamp Installer, Choose Start Options
            ControlClick, Button2
            WinWait, Winamp Installer, Get the Most Out of Winamp
            ControlClick, Button4 ; decline Winamp toolbar
            Sleep 200
            ControlClick, Button5 ; decline AOL Search
            Sleep 200
            ControlClick, Button6 ; decline eMusic
            Sleep 200
            ControlClick, Button2
            Loop
            {
                ifWinExist, Winamp Installer, Installation Complete
                {
                    break
                }
                ifWinExist, Winamp Installer, Recommended
                {
                    WinActivate, Winamp Installer, Recommended
                    WinWaitActive, Winamp Installer, Recommended
                    MouseClick, left, 32, 279 ; decline OpenCandy offers
                    Sleep 200
                    ControlClick, Button2
                    WinWaitClose, Winamp Installer, Recommended
                    continue
                }
                Sleep 200
            }
            WinWait, Winamp Installer, Installation Complete
            WinActivate, Winamp Installer, Installation Complete
            WinWaitActive, Winamp Installer, Installation Complete
            send {Tab}{Tab}{Tab}{Space}   ; don't launch
            Sleep 500
            send {Enter}                  ; Finish
            WinWaitClose
        "
    else
        w_try "$WINE" "$file1"
    fi
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Winamp" "winamp.exe"
}

#----------------------------------------------------------------

w_metadata wme9 apps \
    title="MS Windows Media Encoder 9 (broken in wine)" \
    publisher="Microsoft" \
    year="2002" \
    media="download" \
    file1="WMEncoder.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Windows Media Components/Encoder/wmenc.exe"

load_wme9()
{
    if [ $W_ARCH = win64 ]
    then
        w_die "Installer doesn't support 64-bit architecture."
    fi
    # See also http://www.microsoft.com/downloads/details.aspx?FamilyID=5691ba02-e496-465a-bba9-b2f1182cdf24
    w_download http://download.microsoft.com/download/8/1/f/81f9402f-efdd-439d-b2a4-089563199d47/WMEncoder.exe 7a3f8781f3e5705651992ef0150ee30bc1295116

    cd "$W_CACHE"/wme9
    w_try $WINE WMEncoder.exe $W_UNATTENDED_SLASH_Q

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Windows Media Components\\Encoder" "wmenc.exe"
}

#----------------------------------------------------------------

# helper - not useful by itself
load_wm9codecs()
{
    # Note: must install WMP9 or 10 first, or installer will complain and abort.

    # See http://www.microsoft.com/downloads/details.aspx?FamilyID=06fcaab7-dcc9-466b-b0c4-04db144bb601
    # Used by direct calls from load_wmp9, so have to specify cache directory.
    w_download_to wm9codecs http://download.microsoft.com/download/5/c/2/5c29d825-61eb-4b16-8eb8-58367d0464d5/WM9Codecs9x.exe 8b76bdcbea0057eb12b7966edab4b942ddacc253
    cd "$W_CACHE/wm9codecs"
    w_set_winver win2k
    w_try $WINE WM9Codecs9x.exe $W_UNATTENDED_SLASH_Q
}

w_metadata wmp9 dlls \
    title="Windows Media Player 9" \
    publisher="Microsoft" \
    year="2003" \
    media="download" \
    file1="MPSetup.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN"/l3codeca.acm

load_wmp9()
{
    w_skip_windows wmp9 && return

    # Not really expected to work well yet; see
    # http://appdb.winehq.org/appview.php?versionId=1449

    if [ $W_ARCH = win64 ]
    then
        w_die "Installer doesn't support 64-bit architecture."
    fi

    if w_workaround_wine_bug 28994 "virtualprotect problem" -1.3.31
    then
        w_die "Sorry, wine-1.3.32 has a bug that keeps wmp9 from installing."
    fi

    w_call wsh57

    w_set_winver win2k

    # See also http://www.microsoft.com/windows/windowsmedia/player/9series/default.aspx
    w_download http://download.microsoft.com/download/1/b/c/1bc0b1a3-c839-4b36-8f3c-19847ba09299/MPSetup.exe 580536d10657fa3868de2869a3902d31a0de791b

    # Have to run twice; see http://bugs.winehq.org/show_bug.cgi?id=1886
    cd "$W_CACHE"/wmp9
    w_try $WINE MPSetup.exe $W_UNATTENDED_SLASH_Q
    w_try $WINE MPSetup.exe $W_UNATTENDED_SLASH_Q

    # Disable WMP's services, since they depend on unimplemented stuff, they trigger the GUI debugger several times
    w_try_regedit /D "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Cdr4_2K"
    w_try_regedit /D "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Cdralw2k"

    load_wm9codecs

    w_unset_winver

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Windows Media Player" "wmplayer.exe"
}

#----------------------------------------------------------------

w_metadata wmp10 dlls \
    title="Windows Media Player 10" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="MP10Setup.exe" \
    installed_file1="$W_SYSTEM32_DLLS_WIN/l3codecp.acm"

load_wmp10()
{
    # FIXME: what versions of windows are really bundled with wmp10?
    w_skip_windows wmp10 && return

    # See http://appdb.winehq.org/appview.php?iVersionId=3212
    w_call wsh57

    # http://www.microsoft.com/downloads/en/details.aspx?FamilyID=b446ae53-3759-40cf-80d5-cde4bbe07999
    w_download http://download.microsoft.com/download/1/2/A/12A31F29-2FA9-4F50-B95D-E45EF7013F87/MP10Setup.exe 69862273a5d9d97b4a2e5a3bd93898d259e86657

    # Crashes on exit, but otherwise ok; see http://bugs.winehq.org/show_bug.cgi?id=12633
    cd "$W_CACHE"/wmp10
    w_try $WINE MP10Setup.exe $W_UNATTENDED_SLASH_Q

    # Disable WMP's services, since they depend on unimplemented stuff, they trigger the GUI debugger several times
    w_try_regedit /D "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Cdr4_2K"
    w_try_regedit /D "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Cdralw2k"

    load_wm9codecs

    w_unset_winver

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Windows Media Player" "wmplayer.exe"
}

#----------------------------------------------------------------
# Benchmarks
#----------------------------------------------------------------

w_metadata 3dmark2000 benchmarks \
    title="3DMark2000" \
    publisher="MadOnion.com" \
    year="2000" \
    media="download" \
    file1="3dmark2000_v11_100308.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/MadOnion.com/3DMark2000/3DMark2000.exe"

load_3dmark2000()
{
    # http://www.futuremark.com/download/3dmark2000/
    if ! test -f "$W_CACHE/$W_PACKAGE/3dmark2000_v11_100308.exe"
    then
        w_download http://www.ocinside.de/download/3dmark2000_v11_100308.exe b0400d59cfd45d8c8893d3d4edc58b6285ee1502
    fi

    cd "$W_TMP"
    mkdir $W_PACKAGE
    cd $W_PACKAGE
    w_try_unzip "$W_CACHE/$W_PACKAGE"/3dmark2000_v11_100308.exe
    w_ahk_do "
        SetTitleMatchMode, 2
        run Setup.exe
        WinWait Welcome
        ;ControlClick Button1  ; Next
        Sleep 1000
        Send {Enter}           ; Next
        WinWait License
        ;ControlClick Button2  ; Yes
        Sleep 1000
        Send {Enter}           ; Yes
        ;WinWaitClose ahk_class #32770 ; License
        WinWait ahk_class #32770, Destination
        ;ControlClick Button1  ; Next
        Sleep 1000
        Send {Enter}           ; Next
        ;WinWaitClose ahk_class #32770 ; Destination
        WinWait, Start
        ;ControlClick Button1  ; Next
        Sleep 1000
        Send {Enter}           ; Next
        WinWait Registration
        ControlClick Button1  ; Next
        WinWait Complete
        Sleep 1000
        ControlClick Button1  ; Unclick View Readme
        ;ControlClick Button4  ; Finish
        Send {Enter}           ; Finish
        WinWaitClose
    "

    cat > "$W_DRIVE_C/run-$W_PACKAGE.bat" <<__EOF__
c:
cd "$W_PROGRAMS_X86_WIN\MadOnion.com\3DMark2000"
REM possible wine cmd bug: "3dmark2000" aborts, but ".\3dmark2000" works
.\3DMark2000 %*
__EOF__

}

#----------------------------------------------------------------

w_metadata 3dmark2001 benchmarks \
    title="3DMark2001" \
    publisher="MadOnion.com" \
    year="2001" \
    media="download" \
    file1="3dmark2001se_330_100308.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/MadOnion.com/3DMark2001 SE/3DMark2001SE.exe"

load_3dmark2001()
{
    # http://www.futuremark.com/download/3dmark2001/
    if ! test -f "$W_CACHE/$W_PACKAGE"/3dmark2001se_330_100308.exe
    then
        w_download http://www.ocinside.de/download/3dmark2001se_330_100308.exe 643bacbcc1615bb4f46d3b045b1b8d78371a6b54
    fi

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run 3dmark2001se_330_100308.exe
        WinWait ahk_class #32770 ; welcome
        if ( w_opt_unattended > 0 ) {
            ControlClick Button2  ; Next
            sleep 5000
            WinWait ahk_class #32770 ; License
            ControlClick Button2  ; Next
            WinWait ahk_class #32770, Destination
            ControlClick Button1  ; Next
            WinWait ahk_class #32770, Start
            ControlClick Button1  ; Next
            WinWait,, Registration
            ControlClick Button2  ; Next
        }
        WinWait,, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1  ; Unclick View Readme
            ControlClick Button4  ; Finish
        }
        WinWaitClose
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\MadOnion.com\\3DMark2001 SE" "3DMark2001SE.exe"
}

#----------------------------------------------------------------

w_metadata 3dmark03 benchmarks \
    title="3D Mark 03" \
    publisher="Futuremark" \
    year="2003" \
    media="manual_download" \
    file1="3DMark03_v360_1901.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Futuremark/3DMark03/3DMark03.exe"

load_3dmark03()
{
    # http://www.futuremark.com/benchmarks/3dmark03/download/
    if ! test -f "$W_CACHE/$W_PACKAGE/3DMark03_v360_1901.exe"
    then
        w_download_manual http://www.futuremark.com/download/3dmark03/ 3DMark03_v360_1901.exe 46a439101ddbbe3c9563b5e9651cb61b46ce0619
    fi

    cd "$W_CACHE/$W_PACKAGE"
    w_warn "Don't use mouse while this installer is running.  Sorry..."
    # This old installer doesn't seem to be scriptable the usual way, so spray and pray.
    w_ahk_do "
        SetTitleMatchMode, 2
        run 3DMark03_v360_1901.exe
        WinWait 3DMark03 - InstallShield Wizard, Welcome
        if ( w_opt_unattended > 0 ) {
            WinActivate
            Send {Enter}
            Sleep 2000
            WinWait 3DMark03 - InstallShield Wizard, License
            WinActivate
            ; Accept license
            Send a
            Send {Enter}
            Sleep 2000
            ; Choose Destination
            Send {Enter}
            Sleep 2000
            ; Begin install
            Send {Enter}
            ; Wait for install to finish
            WinWait 3DMark03, Registration
            ; Purchase later
            Send {Tab}
            Send {Tab}
            Send {Enter}
        }
        WinWait, 3DMark03 - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            ; Uncheck readme
            Send {Space}
            Send {Tab}
            Send {Tab}
            Send {Enter}
        }
        WinWaitClose, 3DMark03 - InstallShield Wizard, Complete
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Futuremark\\3DMark03" "3DMark03.exe"
}

#----------------------------------------------------------------

w_metadata 3dmark05 benchmarks \
    title="3D Mark 05" \
    publisher="Futuremark" \
    year="2005" \
    media="download" \
    file1="3dmark05_v130_1901.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Futuremark/3DMark05/3DMark05.exe"

load_3dmark05()
{
    # http://www.futuremark.com/download/3dmark05/
    if ! test -f "$W_CACHE/$W_PACKAGE/3DMark05_v130_1901.exe"
    then
        w_download http://www.ocinside.de/download/3dmark05_v130_1901.exe 8ad6bc2917e22edf5fc95d1fa96cc82515093fb2
    fi

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        run 3DMark05_v130_1901.exe
        WinWait ahk_class #32770, Welcome
        if ( w_opt_unattended > 0 ) {
            Send {Enter}
            WinWait, ahk_class #32770, License
            ControlClick Button1 ; Accept
            ControlClick Button4 ; Next
            WinWait, ahk_class #32770, Destination
            ControlClick Button1 ; Next
            WinWait, ahk_class #32770, Install
            ControlClick Button1 ; Install
            WinWait, ahk_class #32770, Purchase
            ControlClick Button4 ; Later
        }
        WinWait, ahk_class #32770, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1 ; Uncheck view readme
            ControlClick Button3 ; Finish
        }
        WinWaitClose, ahk_class #32770, Complete
    "
    ARGS=""
    if w_workaround_wine_bug 22392
    then
        w_warn "You must run the app with the -nosysteminfo option to avoid a crash on startup"
        ARGS="-nosysteminfo"
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Futuremark\\3DMark05" "3DMark05 $ARGS"
}

#----------------------------------------------------------------

w_metadata 3dmark06 benchmarks \
    title="3D Mark 06" \
    publisher="Futuremark" \
    year="2006" \
    media="download" \
    file1="3dmark06_v120_1901.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Futuremark/3DMark06/3DMark06.exe" \
    wine_showstoppers="9210"

load_3dmark06()
{
    # http://www.futuremark.com/benchmarks/3dmark06/download/
    if ! test -f "$W_CACHE/$W_PACKAGE/3DMark06_v120_1901.exe"
    then
        w_download http://www.ocinside.de/download/3dmark06_v120_1901.exe 2e4a52d5b0f7caebd7b4407dfa9e258ac623b5dd
    fi

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        run 3DMark06_v120_1901.exe
        WinWait ahk_class #32770, Welcome
        if ( w_opt_unattended > 0 ) {
            Send {Enter}
            WinWait, ahk_class #32770, License
            ControlClick Button1 ; Accept
            ControlClick Button4 ; Next
            WinWait, ahk_class #32770, Destination
            ControlClick Button1 ; Next
            WinWait, ahk_class #32770, Install
            ControlClick Button1 ; Install
            WinWait ahk_class OpenAL Installer
            ControlClick Button2 ; OK
            WinWait ahk_class #32770
            ControlClick Button1 ; OK
            WinWait, ahk_class #32770, Purchase
            ControlClick Button4 ; Later
        }
        WinWait, ahk_class #32770, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1 ; Uncheck view readme
            ControlClick Button3 ; Finish
        }
        WinWaitClose, ahk_class #32770, Complete
    "

    if w_workaround_wine_bug 9210
    then
        w_warn "You may need to apply the patch in http://bugs.winehq.org/show_bug.cgi?id=9210 to fix pCaps->MaxPointSize, or the benchmark will w_warn that shader model 2.0 is not present, and refuse to run."
    fi

    if w_workaround_wine_bug 22393
    then
        # "Demo" button doesn't work without this
        w_call d3dx9_28
        w_call d3dx9_36
    fi

    ARGS=""
    if w_workaround_wine_bug 22392
    then
        w_warn "You must run the app with the -nosysteminfo option to avoid a crash on startup"
        ARGS="-nosysteminfo"
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Futuremark\\3DMark06" "3DMark06 $ARGS"
}

#----------------------------------------------------------------

w_metadata unigine_heaven benchmarks \
    title="Unigen Heaven 2.1 Benchmark" \
    publisher="Unigen" \
    year="2010" \
    media="manual_download" \
    file1="Unigine_Heaven-2.1.msi" 

load_unigine_heaven()
{
    # FIXME: use w_download_torrent()
    w_download_manual http://unigine.com/download/torrents/Unigine_Heaven-2.1.msi.torrent Unigine_Heaven-2.1.msi 3d7b94a3734cdae85f98032b61668e743979c444

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run msiexec /i $file1
        if ( w_opt_unattended > 0 ) {
	    WinWait ahk_class MsiDialogCloseClass
	    Send {Enter}
	    WinWait ahk_class MsiDialogCloseClass, License
	    ControlClick Button1 ; Accept
	    ControlClick Button3 ; Accept
	    WinWait ahk_class MsiDialogCloseClass, Choose
	    ControlClick Button1 ; Typical
	    WinWait ahk_class MsiDialogCloseClass, Ready
	    ControlClick Button2 ; Install
	    ; FIXME: on systems with OpenAL already (Win7?), the next four lines
	    ; are not needed.  We should somehow wait for either OpenAL window
	    ; *or* Completed window.
	    WinWait ahk_class OpenAL Installer
	    ControlClick Button2 ; OK
	    WinWait ahk_class #32770
	    ControlClick Button1 ; OK
        }
        WinWait ahk_class MsiDialogCloseClass, Completed
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1 ; Finish
            Send {Enter}
        }
        winwaitclose
    "

    if w_workaround_wine_bug 22614 "setting video memory to 1024M" 1.3.23,
    then
        # hope your card actually has 1GB of RAM
        w_call videomemorysize=1024
    fi

    # Should start Heaven.exe, but that doesn't run in Wine
    # Should give option to run Heaven_gl.bat (even works in Wine)
    # or the dx10 or dx11 versions (doesn't).
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Unigine\\Heaven" "cmd /c Heaven_d3d9.bat"
}

#----------------------------------------------------------------
# Games
#----------------------------------------------------------------

w_metadata algodoo_demo games \
    title="Algodoo Demo" \
    publisher="Algoryx" \
    year="2009" \
    media="download" \
    file1="Algodoo_1_7_1-Win32.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Algodoo/Algodoo.exe"

load_algodoo_demo()
{
    w_download  http://www.algodoo.com/download/Algodoo_1_7_1-Win32.exe caa73e73669a8787652a6bed123bbe2682152f12

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        ; This one's funny... on Wine, keyboard works once you click manually, but until then, only ControlClick seems to work.
        run, Algodoo_1_7_1-Win32.exe
        SetTitleMatchMode, 2
        winwait, Algodoo, Welcome
        if ( w_opt_unattended > 0 ) {
            ControlClick, TNewButton1
            winwait, Algodoo, License
            ;send {Tab}a{Space}{Enter}
            ControlClick, TNewRadioButton1  ; Accept
            ControlClick, TNewButton2  ; Next
            winwait, Algodoo, Destination
            ;send {Enter}
            ControlClick, TNewButton3  ; Next
            winwait, Algodoo, Folder
            ;send {Enter}
            ControlClick, TNewButton4  ; Next
            winwait, Algodoo, Select Additional Tasks
            ;send {Enter}
            ControlClick, TNewButton4  ; Next
            winwait, Algodoo, Ready to Install
            ;send {Enter}
            ControlClick, TNewButton4  ; Next
        }
        winwait, Algodoo, Completing
        if ( w_opt_unattended > 0 ) {
            sleep 500
            send {Space}{Tab}{Space}{Tab}{Space}{Enter}   ; decline to run app or view tutorials
        }
        WinWaitClose, Algodoo, Completing
    "

    # Since we declined the msvc runtime installer (right?), we have to do it here
    if w_workaround_wine_bug 23815
    then
        w_call vcrun2008
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Algodoo" "Algodoo.exe"
}

#----------------------------------------------------------------

w_metadata amnesia_tdd_demo games \
    title="Amnesia: The Dark Descent Demo" \
    publisher="Frictional Games" \
    year="2010" \
    media="manual_download" \
    file1="amnesia_tdd_demo_1.0.1.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Amnesia - The Dark Descent Demo/redist/Amnesia.exe"

load_amnesia_tdd_demo()
{
    w_download_manual "http://www.amnesiagame.com/#demo" amnesia_tdd_demo_1.0.1.exe 0bf0bc6e9c8ea76f1c44582d9302a9b22d31d1b6

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run amnesia_tdd_demo_1.0.1.exe
        WinWait,Select Setup Language,language
        if ( w_opt_unattended > 0 ) {
            WinActivate
            ;ControlClick, TNewButton1; OK
            send {Enter}              ; OK
            WinWait,Setup - Amnesia - The Dark Descent Demo,Welcome
            ;ControlClick TNewButton1 ; Next
            send {Enter}              ; Next
            WinWait,Setup - Amnesia - The Dark Descent Demo,License
            ControlClick TNewRadioButton1 ; agree
            Sleep 1000
            send !n                   ; Next
            ;send {Enter}             ; Next
            ;ControlClick TNewButton2 ; Next
            WinWait,Setup - Amnesia - The Dark Descent Demo,Destination
            ;ControlClick TNewButton3 ; Next
            send {Enter}              ; Next
            WinWait,Folder Does Not Exist,created
            ;ControlClick Button1     ; OK
            send {Enter}              ; OK
            WinWait,Setup - Amnesia - The Dark Descent Demo,shortcuts
            ;ControlClick TNewButton4 ; Next
            send {Enter}              ; Next
            WinWait,Setup - Amnesia - The Dark Descent Demo,additional tasks
            ;ControlClick TNewButton4 ; Next
            send {Enter}              ; Next
            WinWait,Setup - Amnesia - The Dark Descent Demo,installing
            ;ControlClick TNewButton4 ; Install
            send {Enter}              ; Install
        }
        WinWait,Setup - Amnesia - The Dark Descent Demo,finished
        if ( w_opt_unattended > 0 ) {
            ;ControlClick TNewButton4 ; Finish
            send {Enter}              ; Finish
        }
        WinWaitClose,Setup - Amnesia - The Dark Descent Demo,finished
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Amnesia - The Dark Descent Demo\\redist" "Amnesia.exe"
}

#----------------------------------------------------------------

w_metadata aoe3_demo games \
    title="Age of Empires III Trial" \
    publisher="Microsoft" \
    year="2005" \
    media="download" \
    file1="aoe3trial.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Games/Age of Empires III Trial/age3.exe"

load_aoe3_demo()
{

    w_download "http://download.microsoft.com/download/a/5/2/a525997e-8423-435b-b694-08118d235064/aoe3trial.exe" \
        2b0a123243092d79f910db5691d99d469f7c17c3

    if w_workaround_wine_bug 24897 "Installing msxml4 to avoid font problem" 1.3.9,
    then
        w_call msxml4
    fi

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        run aoe3trial.exe
        WinWait,Empires,Welcome
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            winactivate          ; else next button click ignored on vista?
            Sleep 500
            ControlClick Button1 ; Next
            WinWait,Empires,Please
            Sleep 500
            ControlClick Button4 ; Next
            WinWait,Empires,Complete
            Sleep 500
            ControlClick Button4 ; Finish
        }
        WinWaitClose
    "

    if w_workaround_wine_bug 24911 "Installing devnum, dmsynth, and quartz to get sound working" 1.3.9,
    then
        # On some systems, only quartz is needed?
        # appdb says that l3codecx is also needed?
        w_call devenum
        w_call dmsynth
        w_call quartz
    fi

    if w_workaround_wine_bug 24912
    then
        # kill off lingering installer
        w_ahk_do "
            SetTitleMatchMode, 2
            WinKill,Empires
        "
        # or should we just do wineserver -k, like fable_tlc does?
        PID=`ps augxw | grep IDriver | grep -v grep | awk '{print $2}'`
        kill $PID
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Games\\Age of Empires III Trial" "age3.exe"
}

#----------------------------------------------------------------

w_metadata aoe_demo games \
    title="Age of Empires Demo" \
    publisher="Microsoft" \
    year="1997" \
    media="download" \
    file1="MSAoE.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Games/Age of Empires Trial/empires.exe"

load_aoe_demo()
{
    w_download http://download.microsoft.com/download/aoe/Trial/1.0/WIN98/EN-US/MSAoE.exe 23630a65ce4133038107f3175f8fc54a914bc2f3

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        run, MSAoE.exe
        SetTitleMatchMode, 2
        winwait, Microsoft Age of Empires Trial Version
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick, Button1
            winwait, End User License Agreement
            sleep 1000
            ControlClick, Button1
            winwait, Microsoft Age of Empires Trial Version, Setup will install
            sleep 1000
            ControlClick Button2
            winwait, Microsoft Age of Empires Trial Version, Setup has successfully
            sleep 1000
            ControlClick Button1
        }
        WinWaitClose, Microsoft Age of Empires Trial Version
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Games\\Age of Empires Trial" "empires"
}

#----------------------------------------------------------------

w_metadata acreedbro games \
    title="Assassin's Creed Brotherhood" \
    publisher="Ubisoft" \
    year="2011" \
    media="dvd" \
    file1="ACB.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Ubisoft/Assassin's Creed Brotherhood/AssassinsCreedBrotherhood.exe"

load_acreedbro()
{
    w_mount ACB
    w_read_key
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, Brotherhood, Choose
        if ( w_opt_unattended > 0 ) {
            WinActivate
            send {Enter}
            ;ControlClick, Button3   ; Accept default (english)
            winwait, Brotherhood, Welcome
            WinActivate
            send {Enter}   ; Next
            winwait, Brotherhood, License
            WinActivate
            send a         ; Agree
            sleep 500
            send {Enter}   ; Next
            winwait, Brotherhood, begin
            send {Enter}   ; Install
        }
        winwait, Brotherhood, Finish
        if ( w_opt_unattended > 0 ) {
            ControlClick Button4
            send {Enter}   ; Finish
        }
        WinWaitClose
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Ubisoft\\Assassin's Creed Brotherhood" AssassinsCreedBrotherhood.exe

    w_download http://static3.cdn.ubi.com/ac_brotherhood/ac_brotherhood_1.01_ww.exe a2b76f16616709cc16537b0e98faa4181ca904ce

    if w_workaround_wine_bug 26562 "Disabling glsl for smoother rendering"
    then
        w_call glsl=disabled

        # And turn off after-effects to fix depth of field problem caused
        # by disabling glsl...
        cd "$W_DRIVE_C/users/$USERNAME/My Documents"
        dir="Ubisoft/Assassin's Creed Brotherhood"
        file="$dir/ACBrotherhood.ini"
        if test -f "$file"
        then
            mv "$file" "$file.old"
            sed 's,PostFX=[0-9]*,PostFX=0,' < "$file.old" > "$file"
        else
            mkdir -p "$dir"
            echo "[Graphics]" > "$file"
            echo "PostFX=0" >> "$file"
        fi
    fi

    if w_workaround_wine_bug 26583 "Installing native d3dx9_36"
    then
        w_call d3dx9_36
    fi

    # FIXME: figure out why these executables don't exit, and do a proper workaround or fix
    sleep 10
    if ps augxw | grep -i exe | egrep 'winemenubuilder.exe|setup.exe|PnkBstrA.exe | egrep -v egrep'
    then
        w_warn "Killing processes so patcher does not complain about game still running"
        wineserver -k
        sleep 10
    fi

    w_info "Applying patch $W_CACHE/$W_PACKAGE/ac_brotherhood_1.01_ww.exe..."

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run ac_brotherhood_1.01_ww.exe
        WinWait, Choose Setup Language, Select
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, Brotherhood 1.01, License
            WinActivate
            send a         ; Agree
            sleep 500
            send {Enter}   ; Next
            winwait, Brotherhood 1.01, Details
            ControlClick Button1  ; Next
        }
        winwait, Brotherhood 1.01, Complete
        if ( w_opt_unattended > 0 ) {
            send {Enter}
        }
        WinWaitClose
    "

    if test `which wine-hotfix-6971` 2> /dev/null
    then
        if w_workaround_wine_bug 6971 "Pointing menu and icon at wine-hotfix-6971 to fix mouse problems"
        then
            myexec="Exec=env WINEPREFIX=\"$HOME/.local/share/wineprefixes/$W_PACKAGE\" wine-hotfix-6971 cmd /c 'C:\\\\\\Run-$W_PACKAGE.bat'"

            mymenu="$HOME/Desktop/Assassin's Creed Brotherhood.desktop"
            if test -f "$mymenu"
            then
                sed -i "s,Exec=.*,$myexec," "$mymenu"
            fi
            mymenu="$HOME/.local/share/applications/wine/Programs/Ubisoft/Assassin's Creed Brotherhood/Assassin's Creed Brotherhood.desktop"
            if test -f "$mymenu"
            then
                sed -i "s,Exec=.*,$myexec," "$mymenu"
            fi
        fi
    else
        w_workaround_wine_bug 6971 "Please upgrade to wine-1.3.23 or later; see http://wiki.winehq.org/Bug6971" 1.3.23,
    fi
}

#----------------------------------------------------------------

w_metadata atmosphir games \
    title="Atmosphir" \
    publisher="Minor Studios" \
    year="2011" \
    media="manual_download" \
    file1="Atmosphir Installer v1.0.0 fixed.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Minor Studios/Atmosphir/Atmosphir.exe" \
    homepage="http://www.atmosphir.com"

load_atmosphir()
{
    w_download_manual http://download.cnet.com/Atmosphir/3000-7492_4-75335647.html "Atmosphir Installer v1.0.0 fixed.exe" 3ee46b45ea9a8e4a8888148556efb7e61882f7d0
    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        run Atmosphir Installer v1.0.0 fixed.exe
        winwait, Atmosphir Setup, Welcome
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick Button2
            winwait, Atmosphir Setup, License Agreement
            sleep 1000
            ControlClick Button2
            winwait, Atmosphir Setup, Choose Install Location
            sleep 1000
            ControlClick Button2
            winwait, Atmosphir Setup, Choose Start Menu Folder
            sleep 1000
            ControlClick Button2
        }
        winwait, Atmosphir Setup, Installation complete
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            send {Space}  ; ControlClick Button4    # start
            sleep 1000
            ControlClick Button2
            ; Let the launcher do the initial full download
            winwait, Atmosphir Launcher
            winwaitclose
            ; then kill the game when it starts
            winwait, Atmosphir
            ;winkill          ; doesn't work, game traps it
            winclose
        }
        winwaitclose
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN/Minor Studios/Atmosphir" Atmosphir.exe
}

#----------------------------------------------------------------

w_metadata avatar_demo games \
    title="James Camerons Avatar: The Game Demo" \
    publisher="Ubisoft" \
    year="2009" \
    media="manual_download" \
    file1="Avatar_The_Game_Demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Ubisoft/Demo/James Cameron's AVATAR - THE GAME (Demo)/bin/AvatarDemo.exe"

load_avatar_demo()
{
    w_download_manual http://www.fileplanet.com/207386/200000/fileinfo/Avatar:-The-Game-Demo Avatar_The_Game_Demo.exe 8d8e4c82312962706bd2620406d592db4f0fa9c1

    if w_workaround_wine_bug 23094 "Installing Visual C++ 2005 runtime to avoid installer crash"
    then
        w_call vcrun2005
    fi

    cd "$W_TMP"
    w_try unrar x "$W_CACHE/$W_PACKAGE/Avatar_The_Game_Demo.exe"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run, setup.exe
        winwait, Language
        u = $W_OPT_UNATTENDED
        if ( u > 0 ) {
            WinActivate
            controlclick, Button1
            winwait, AVATAR, Welcome
            controlclick, Button1
            winwait, AVATAR, License
            controlclick, Button5
            controlclick, Button2
            winwait, AVATAR, setup type
            controlclick, Button2
        }
        winwait AVATAR
        if ( u > 0 ) {
            ; Strange CRC error workaround. Will check this out. Stay tuned.
            loop
            {
                ifwinexist, CRC Error
                {
                    winactivate, CRC Error
                    controlclick, Button3, CRC Error ; ignore
                }
                ifwinexist, AVATAR, Complete
                {
                    controlclick, Button4
                    break
                }
                sleep 1000
            }
        }
        winwaitclose AVATAR
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Ubisoft\\Demo\\James Cameron's AVATAR - THE GAME (Demo)\\bin" "AvatarDemo.exe"

    w_workaround_wine_bug 24639 "If game is silent, try winetricks dsoundhw=Emulation"
    w_workaround_wine_bug 26590 "If game seems slow, try winetricks glsl=disabled"
}


w_metadata bttf101 games \
    title="Back to the Future Episode 1" \
    publisher="Telltale" \
    year="2011" \
    media="manual_download" \
    file1="bttf_101_setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Telltale Games/Back to the Future The Game/Episode 1/BackToTheFuture101.exe"

load_bttf101()
{
    w_download_manual http://www.telltalegames.com/bttf bttf_101_setup.exe 9b15e26d9b4d454f714d6559efe509562df9c10b

    if w_workaround_wine_bug 26371 "Installing d3dx9_36 to work around crash"
    then
        w_call d3dx9_36
    fi

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run, bttf_101_setup.exe
        winwait, Back to the Future, Welcome
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button2   ; Next
            winwait, Back to the Future, Checking DirectX
            ControlClick, Button5   ; Don't check
            ControlClick, Button2   ; Next
            winwait, Back to the Future, License
            ControlClick, Button2   ; Agree
            winwait, Back to the Future, Location
            ControlClick, Button2   ; Install
        }
        winwait, Back to the Future, has been installed
        if ( w_opt_unattended > 0 ) {
            ControlClick Button4    ; Don't start now
            ControlClick Button2    ; Finish
        }
        WinWaitClose
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Telltale Games\\Back to the Future The Game\\Episode 1" BackToTheFuture101.exe
}

#----------------------------------------------------------------

w_metadata bioshock_demo games \
    title="Bioshock Demo" \
    publisher="2K Games" \
    year="2007" \
    media="download" \
    file1="nzd_BioShockPC.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/2K Games/BioShock Demo/Builds/Release/Bioshock.exe"

load_bioshock_demo()
{
    if w_workaround_wine_bug 6971 "Setting mwo=force... please upgrade to wine-1.3.23" 1.3.23,
    then
        w_call mwo=force
    fi

    w_download http://us.download.nvidia.com/downloads/nZone/demos/nzd_BioShockPC.zip 7a19186602cec5210e4505b58965e8c04945b3cf

    w_info "Unzipping demo, installer will start in about 30 seconds."
    w_try unzip "$W_CACHE/$W_PACKAGE/nzd_BioShockPC.zip" -d "$W_TMP/$W_PACKAGE"
    cd "$W_TMP/$W_PACKAGE/BioShock PC Demo"

    w_ahk_do "
        SetTitleMatchMode, 2
        run setup.exe
        winwait, BioShock Demo - InstallShield Wizard, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            sleep 2000
            ControlClick, Button3
            ControlClick, Button3
            winwait, BioShock Demo - InstallShield Wizard, Welcome
            sleep 1000
            ControlClick, Button1
            winwait, BioShock Demo - InstallShield Wizard, Please read
            sleep 1000
            ControlClick, Button5
            sleep 1000
            ControlClick, Button2
            winwait, BioShock Demo - InstallShield Wizard, Select the setup type
            sleep 1000
            ControlClick, Button2
            winwait, BioShock Demo - InstallShield Wizard, Click Install to begin
            ControlClick, Button1
        }
        winwait, BioShock Demo - InstallShield Wizard, The InstallShield Wizard has successfully installed BioShock
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick, Button2     ; don't launch
            ControlClick, Button6     ; don't show readme
            send {Enter}              ; finish
        }
        winwaitclose
        sleep 3000 ; wait for splash screen to close
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\2K Games\\BioShock Demo\\Builds\\Release" "Bioshock.exe"
}

#----------------------------------------------------------------

w_metadata bioshock2 games \
    title="Bioshock 2" \
    publisher="2K Games" \
    year="2010" \
    media="dvd" \
    file1="BIOSHOCK_2.iso" \
    wine_showstoppers="7065" \
    installed_exe1="$W_PROGRAMS_X86_WIN/2K Games/BioShock 2/SP/Builds/Binaries/Bioshock2Launcher.exe" \
    installed_exe2="$W_PROGRAMS_X86_WIN/2K Games/BioShock 2/MP/Builds/Binaries/Bioshock2Launcher.exe"

load_bioshock2()
{
    w_workaround_wine_bug 7065 "This game won't work in Wine because its disc check fails."

    w_mount BIOSHOCK_2
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        if ( w_opt_unattended > 0 ) {
            winwait BioShock 2, Language
            controlclick Button3
            winwait BioShock 2, Welcome
            controlclick Button1 ; Accept
            winwait BioShock 2, License
            controlclick Button3 ; Accept
            sleep 500
            controlclick Button1 ; Next
            winwait BioShock 2, Setup Type
            controlclick Button4 ; Next
            winwait BioShock 2, Ready to Install
            controlclick Button1 ; Install
        }
        winwait BioShock 2, Complete
        if ( w_opt_unattended > 0 ) {
            controlclick Button4 ; Finish
        }
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\2K Games\\BioShock 2\\SP\\Builds\\Binaries" Bioshock2Launcher.exe
    w_declare_exe "$W_PROGRAMS_X86_WIN\\2K Games\\BioShock 2\\MP\\Builds\\Binaries" Bioshock2Launcher.exe bioshock2_mp
}

#----------------------------------------------------------------

w_metadata bfbc2 games \
    title="Battlefield Bad Company 2" \
    publisher="EA" \
    year="2010" \
    media="dvd" \
    file1="BFBC2.iso"

load_bfbc2()
{
    # Title of installer window gets the TM symbol wrong, even in utf8 locales.
    # Is it like that in Windows, too?
    w_mount BFBC2
    w_read_key
    w_ahk_do "
        SetTitleMatchMode, 2
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, Bad Company, English
        sleep 500
        ControlClick, Next, Bad Company
        winwait, Bad Company, Registration Code
        sleep 500
        send {RAW}$W_KEY
        ControlClick, Next, Bad Company, Registration Code
        winwait, Bad Company, Setup Wizard will install
        sleep 500
        ControlClick, Button1, Bad Company, Setup Wizard
        winwait, Bad Company, License Agreement
        sleep 500
        ControlClick, Button1, Bad Company, License Agreement
        ControlClick, Button3, Bad Company, License Agreement
        winwait, Bad Company, End-User License Agreement
        sleep 500
        ControlClick, Button1, Bad Company, License Agreement
        ControlClick, Button3, Bad Company, License Agreement
        winwait, Bad Company, Destination Folder
        sleep 500
        ControlClick, Button1, Bad Company, Destination Folder
        winwait, Bad Company, Ready to install
        sleep 500
        ControlClick, Install, Bad Company, Ready to install
        winwait, Authenticate Battlefield
        sleep 500
        ControlClick, Disc authentication, Authenticate Battlefield
        ControlClick, Button4, Authenticate Battlefield
        winwait, Bad Company, PunkBuster
        sleep 500
        ControlClick, Button4, Bad Company, PunkBuster
        ControlClick, Finish, Bad Company
        winwaitclose
    "

    w_warn "Patching to latest version..."

    cd "$W_PROGRAMS_X86_UNIX/Electronic Arts/Battlefield Bad Company 2"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, BFBC2Updater.exe
        winwait, Updater, have to update to
        sleep 500
        ControlClick, Yes, Updater, have to update
        winwait, Updater, successfully updated
        sleep 500
        ControlClick,No, Updater, successfully updated  ; Button2
    "

    if w_workaround_wine_bug 22762
    then
        # FIXME: does this directory name change in win7?
        cd "$W_DRIVE_C/users/$USERNAME/My Documents"
        if test -f BFBC2/settings.ini
        then
            mv BFBC2/settings.ini BFBC2/oldsettings.ini
            sed 's,DxVersion=auto,DxVersion=9,;
                 s,Fullscreen=true,Fullscreen=false,' BFBC2/oldsettings.ini > BFBC2/settings.ini
        else
            mkdir -p BFBC2
            echo "[Graphics]" > BFBC2/settings.ini
            echo "DxVersion=9" >> BFBC2/settings.ini
        fi
    fi

    if w_workaround_wine_bug 22961
    then
        w_warn 'If the game says "No CD/DVD error", try "sudo mount -o remount,unhide,uid=`uid -u`".  See http://bugs.winehq.org/show_bug.cgi?id=22961 for more info.'
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\Battlefield Bad Company 2" "BFBC2Game.exe"
}

#----------------------------------------------------------------

w_metadata bladekitten_demo games \
    title="Blade Kitten Demo" \
    publisher="Krome Studios" \
    year="2010" \
    media="manual_download" \
    file1="BladeKittenDemoInstall.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Krome Studios/Blade Kitten Demo/BladeKitten_Demo.exe"

load_bladekitten_demo()
{
    w_download_manual http://news.bigdownload.com/2010/09/23/download-blade-kitten-demo BladeKittenDemoInstall.exe d3568f94c1ce284b7381e457e9497065bd45001d

    cp "$W_CACHE/$W_PACKAGE"/BladeKittenDemoInstall.exe "$W_TMP"
    cd "$W_TMP"
    w_ahk_do "
        ; This script always gives full window title, so no need to set a different title match mode
        run BladeKittenDemoInstall.exe
        WinWait Blade Kitten Demo Install Package
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button2 ;  Install
            WinWait Blade Kitten Demo, Next
            Sleep 500
            ControlClick Button1
            WinWait Blade Kitten Demo, Cost
            Sleep 500
            ControlClick Button1  ; Next
            WinWait Blade Kitten Demo, ready
            Sleep 500
            ControlClick Button1 ;  Next
            ; Note - in older versions of wine, the directx installer may take 6-10 minutes at this point
        }
        WinWaitClose
        WinWait Blade Kitten Demo, Complete
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button1 ;  Close
        }
        WinWaitClose
    "

    if w_workaround_wine_bug 24681
    then
        w_set_app_winver BladeKitten_Demo.exe win2k
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Krome Studios\\Blade Kitten Demo" "BladeKitten_Demo.exe"
}

#----------------------------------------------------------------

w_metadata braid_demo games \
    title="Braid Demo" \
    publisher="Number None" \
    year="2009" \
    media="download" \
    file1="braid_windows_r3.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Braid/braid.exe"

load_braid_demo()
{
    if ! test -f "$W_CACHE/$W_PACKAGE/braid_windows_r3.exe"
    then
        w_download http://download.instantaction.com/games/pgh_legacy/braid_windows_r3.exe 7ea08ddbf5f2fb2f38057d930389b5af7d737e2c
    fi

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, braid_windows_r3.exe
        if ( w_opt_unattended > 0 ) {
            winwait, Braid, install
            controlclick, TButton1
            winwait, Braid, Destination
            controlclick, TButton3
            winwait, Braid, Ready to Install
            controlclick, TButton3
            winwait, Setup, Finishing installation
            sleep 5000
            ; Workaround_winebug 21761
            ifwinactive, Setup, ShellExecuteEx failed
            {
                controlclick, Button1
            }
        }
        winwait, Braid, finished
        if ( w_opt_unattended > 0 )
            controlclick, TButton3
        winwaitclose, Braid, finished
    "

    if w_workaround_wine_bug 22161
    then
        w_call d3dx9_36
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Braid" "braid.exe"
}

#----------------------------------------------------------------

w_metadata braid games \
    title="Braid" \
    publisher="Number None" \
    year="2009" \
    media="download" \
    file1="braid_windows_r3.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Braid/braid.exe"

load_braid()
{
    if ! test -f "$W_CACHE/$W_PACKAGE/braid_windows_r3.exe"
    then
        w_download http://download.instantaction.com/games/pgh_legacy/braid_windows_r3.exe 7ea08ddbf5f2fb2f38057d930389b5af7d737e2c
    fi

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, braid_windows_r3.exe
        if ( w_opt_unattended > 0 ) {
            winwait, Braid, install
            controlclick, TButton1
            winwait, Braid, Destination
            controlclick, TButton3
            winwait, Braid, Ready to Install
            controlclick, TButton3
            winwait, Setup, Finishing installation
            sleep 5000
            ; Workaround_winebug 21761
            ifwinactive, Setup, ShellExecuteEx failed
            {
                controlclick, Button1
            }
        }
        winwait, Braid, finished
        if ( w_opt_unattended > 0 )
            controlclick, TButton3
        winwaitclose, Braid, finished
    "

    if w_workaround_wine_bug 22161
    then
        w_call d3dx9_36
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Braid" "braid.exe"

    w_read_key 
    cd "$W_DRIVE_C"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, run-$W_PACKAGE.bat
        winwait, Braid, Enter Registration
        controlclick, Button4
        winwait, Enter Registration
        send {Raw}$W_RAW_KEY
        controlclick, Button1
        sleep 5000
        process, close, braid.exe
    "

    # Fix resolution for user:
    if [ -x "`which xrandr`" ]
    then
        xrandr -s 0
    else
        w_warn "Xrandr is not available, not sure how to fix resolution, sorry!"
    fi

}

#----------------------------------------------------------------

w_metadata cnc_tiberian_sun games \
    title="Command and Conquer: Tiberian Sun (2010 edition)" \
    publisher="EA" \
    year="1999" \
    media="download" \
    file1="OfficialCnCTiberianSun.rar" \
    installed_exe1="$W_PROGRAMS_X86_WIN\\EA Games\\Command & Conquer The First Decade\\Command & Conquer(tm) Tiberian Sun(tm)\\SUN\\Game.exe"

load_cnc_tiberian_sun()
{
    w_download \
        http://na.llnet.cnc3tv.ea.com/u/f/eagames/cnc3/cnc3tv/Classic/$file1 \
        591aabd639fb9f2d2476a2150f3c00b1162674f5

    cd "$W_PROGRAMS_X86_UNIX"
    # FIXME: we need a progress indicator when unpacking large archives
    w_info "Unpacking rar file.  This will take a minute."
    w_try unrar x "$W_CACHE/$W_PACKAGE/$file1"

    if w_workaround_wine_bug 26911 \
        "Setting dsoundhw=Emulation so sound works in skirmish mode"
    then
        w_call dsoundhw=Emulation
    fi

    w_declare_exe \
        "$W_PROGRAMS_X86_WIN\\EA Games\\Command & Conquer The First Decade\\Command & Conquer(tm) Tiberian Sun(tm)\\SUN" \
        Game.exe
}

#----------------------------------------------------------------

w_metadata cnc3_demo games \
    title="Command and Conquer 3 Demo" \
    publisher="EA" \
    year="2007" \
    media="download" \
    file1="CnC3Demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/Command & Conquer 3 Tiberium Wars Demo/CNC3Demo.exe"

load_cnc3_demo()
{
    w_download "http://largedownloads.ea.com/pub/demos/CommandandConquer3/CnC3Demo.exe" f6af21eba2d17eb6d8bb6a131b501b41c3a7eaf7

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, CnC3Demo.exe
        winwait, Conquer 3, free space to install
        if ( w_opt_unattended > 0 ) {
            controlclick, button1
            winwait, WinZip, After installation
            controlclick, button1
            winwait, Conquer 3, InstallShield
            controlclick, button1
            winwait, Conquer 3, license
            controlclick, button3
            controlclick, button5
            winwait, Conquer 3, setup type
            controlclick, button5
            winwait, Conquer 3, EA Link
            controlclick, button1
            winwait, Conquer 3, GameSpy
            controlclick, button1
        }
        winwait, Conquer 3, Launch the program
        if ( w_opt_unattended > 0 )
            controlclick, button1

        winwaitclose, Conquer 3, Launch the program
    "

    if w_workaround_wine_bug 19159
    then
        w_call vd=800x600
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\Command & Conquer 3 Tiberium Wars Demo" "CNC3Demo.exe"
}

#----------------------------------------------------------------

w_metadata cnc_redalert3_demo games \
    title="Command & Conquer Red Alert 3 Demo" \
    publisher="EA" \
    year="2008" \
    media="manual_download" \
    file1="RedAlert3Demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/Red Alert 3 Demo/RA3Demo.exe"

load_cnc_redalert3_demo()
{
    w_download_manual 'http://www.fileplanet.com/194888/190000/fileinfo/Command-&-Conquer:-Red-Alert-3-Demo' RedAlert3Demo.exe f909b87cc12e386a51be51ede708634348c8af48

    cd "$W_CACHE/$W_PACKAGE"
    if test ! "$W_OPT_UNATTENDED"
    then
        w_try "$WINE" $file1
    else
        w_ahk_do "
            SetWinDelay 1000
            SetTitleMatchMode, 2
            run $file1
            winwait, Demo, readme
            send {enter}                           ; Install button
            winwait, Demo, Agreement
            ControlFocus, TNewCheckListBox1, accept
            send {space}                           ; accept license
            sleep 1000
            send N                                 ; Next
            winwait, Demo, Agreement ; DirectX
            ControlFocus, TNewCheckListBox1, accept
            send {space}                           ; accept license
            sleep 1000
            send N                                 ; Next
            winwait, Demo, Next
            send N                                 ; Next
            winwait, Demo, Install
            send {enter}                           ; Really install
            winwait, Demo, Finish
            send F                                 ; finish
            WinWaitClose
        "
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\Red Alert 3 Demo" RA3Demo.exe
}

#----------------------------------------------------------------

# http://appdb.winehq.org/objectManager.php?sClass=version&iId=9320
w_metadata blobby_volley games \
    title="Blobby Volley" \
    publisher="Daniel Skoraszewsky" \
    year="2000" \
    media="manual_download" \
    file1="blobby.zip" \
    installed_exe1="c:/BlobbyVolley/volley.exe"

load_blobby_volley()
{
    w_download_manual http://www.chip.de/downloads/Blobby-Volley_12990993.html blobby.zip c7057c77a5009a88d9d877e17a63b5536ebeb177

    mkdir -p "$W_DRIVE_C/BlobbyVolley"
    cd "$W_CACHE/$W_PACKAGE"
    w_try_unzip blobby.zip -d "$W_DRIVE_C/BlobbyVolley"
    w_declare_exe "c:\\BlobbyVolley" "volley.exe"

    if w_workaround_wine_bug 4432
    then
        w_warn "You may need to apply a patch, see http://bugs.winehq.org/show_bug.cgi?id=4432#c15"
    fi
}

#----------------------------------------------------------------

w_metadata cim_demo games \
    title="Cities In Motion Demo" \
    publisher="Paradox Interactive" \
    year="2010" \
    media="manual_download" \
    file1="cim-demo-1-0-8.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Cities In Motion Demo/Cities In Motion.exe"

load_cim_demo()
{
    # 29 Mar 2011 d40408b59bc0e6e33b564e9bbb55dbab6c44c630, Inno Setup installer
    #w_download http://www.pcgamestore.com/games/cities-in-motion-nbsp/trial/cim-demo-1-0-8.exe d40408b59bc0e6e33b564e9bbb55dbab6c44c630
    w_download_manual http://www.fileplanet.com/218762/210000/fileinfo/Cities-in-Motion-Demo cim-demo-1-0-8.exe d40408b59bc0e6e33b564e9bbb55dbab6c44c630
    cd "$W_CACHE/$W_PACKAGE"
    w_try $WINE cim-demo-1-0-8.exe ${W_OPT_UNATTENDED:+ /sp- /silent /norestart}
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Cities In Motion Demo" "Cities In Motion.exe"
}

#----------------------------------------------------------------

w_metadata cod_demo games \
    title="Call of Duty demo" \
    publisher="Activision" \
    year="2003" \
    media="manual_download" \
    file1="call_of_duty_demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Call of Duty Single Player Demo/CoDSP.exe"

load_cod_demo()
{
    w_download_manual http://www.gamefront.com/files/968870/call_of_duty_demo_exe Call_Of_Duty_Demo.exe 1c480a1e64a80f7f97fd0acd9582fe190c64ad8e

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run Call_Of_Duty_Demo.exe
        WinWait,Call of Duty Single Player Demo,Welcome
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick Button1 ; next
            WinWait,Call of Duty Single Player Demo,License
            sleep 1000
            WinActivate
            send A               ; I Agree
            WinWait,Call of Duty Single Player Demo,System
            sleep 1000
            send n               ; Next
            WinWait,Call of Duty Single Player Demo,Location
            sleep 1000
            send {Enter}
            WinWait,Call of Duty Single Player Demo,Select
            sleep 1000
            send n
            WinWait,Call of Duty Single Player Demo,Start
            sleep 1000
            send i               ; Install
            WinWait,Create Shortcut
            sleep 1000
            send n               ; No
        }
        WinWait,Call of Duty Single Player Demo, Complete
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            send {Enter}         ; Finish
        }
        WinWaitClose
    "

    if w_workaround_wine_bug 21558
    then
        # Work around a buffer overflow - not really Wine's fault
        setvar="@if not defined %__GL_ExtensionStringVersion% then echo \"If you get a buffer overflow error, set __GL_ExtensionStringVersion=17700 before starting Wine.  See http://bugs.winehq.org/show_bug.cgi?id=21558.\""
    else
        setvar=
    fi
    cat > "$W_DRIVE_C/run-$W_PACKAGE.bat" <<__EOF__
$setvar
c:
cd "$W_PROGRAMS_X86_WIN\\Call of Duty Single Player Demo"
CoDSP.exe %*
__EOF__

}

#----------------------------------------------------------------

w_metadata cod1 games \
    title="Call of Duty" \
    publisher="Activision" \
    year="2003" \
    media="dvd" \
    file1="COD1.iso" \
    file2="CoD2.iso"

load_cod1()
{
    # FIXME: port load_harder from winetricks and use it when caching first disc
    w_mount COD1

    w_read_key

    __GL_ExtensionStringVersion=17700 w_ahk_do "
        SetTitleMatchMode, 2
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        WinWait, CD Key, enter
        if ( w_opt_unattended > 0 ) {
            send {Raw}$W_KEY
            ControlClick Button1
            WinWait, CD Key, valid
            ControlClick Button1
            WinWait, Call of Duty, Welcome
            ControlClick Button1
            WinWait, Call of Duty, License
            ControlClick Button3
            WinWait, Call of Duty, Minimum
            ControlClick Button4
            WinWait, Call of Duty, Location
            ControlClick Button1
            WinWait, Call of Duty, Folder
            ControlClick Button1
            WinWait, Call of Duty, Start
            ControlClick Button1
        }
        WinWait, Insert CD, Please insert the Call of Duty CD 2
        "

    $WINE eject ${W_ISO_MOUNT_LETTER}:
    w_mount CoD2

    w_ahk_do "
        SetTitleMatchMode, 2
        if ( w_opt_unattended > 0 ) {
            Send {Enter}    ;continue installation
        }
        WinWait, Insert CD, Please insert the Call of Duty CD 1
    "

    $WINE eject ${W_ISO_MOUNT_LETTER}:
    w_mount COD1

    w_ahk_do "
        SetTitleMatchMode, 2
        if ( w_opt_unattended > 0 ) {
            Send {Enter}    ;finalize install
            WinWait, Create Shortcut, Desktop
            ControlClick Button1
            WinWait, DirectX, Call    ;directx 9
            ControlClick Button6
            ControlClick Button1
            WinWait, Confirm DX settings, Are
            ControlClick Button2
        }
        ; handle crash here
        WinWait, Installation Complete, Congratulations!
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1
        }
        WinWaitClose
    "
    $WINE eject ${W_ISO_MOUNT_LETTER}:

    if w_workaround_wine_bug 21558
    then
        # Work around a buffer overflow - not really Wine's fault
        setvar="@if not defined %__GL_ExtensionStringVersion% then echo \"If you get a buffer overflow error, set __GL_ExtensionStringVersion=17700 before starting Wine.  See http://bugs.winehq.org/show_bug.cgi?id=21558.\""
    else
        setvar=
    fi
    cat > "$W_DRIVE_C/run-$W_PACKAGE.bat" <<__EOF__
$setvar
c:
cd "$W_PROGRAMS_X86_WIN\\Call of Duty"
CoDSP.exe %*
__EOF__

    w_warn "This game is copy-protected, and requires the real disc in a real drive to run."
}

#----------------------------------------------------------------

w_metadata cod4mw_demo games \
    title="Call of Duty 4 Modern Warfare" \
    publisher="Activision" \
    year="2007" \
    media="manual_download" \
    file1="CoD4MWDemoSetup_v2.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Activision/Call of Duty 4 - Modern Warfare Demo/iw3sp.exe"

load_cod4mw_demo()
{
    w_download http://download.cnet.com/Call-of-Duty-4-Modern-Warfare/3000-7441_4-11277584.html CoD4MWDemoSetup_v2.exe 690a5f789a44437ed10784acfdd6418ca4a21886

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, CoD4MWDemoSetup_v2.exe
        WinWait,Modern Warfare,Welcome
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button1 ; Next
            WinWait,Modern Warfare, License
            Sleep 500
            ControlClick Button5 ; accept
            Sleep 2000
            ControlClick Button2 ; Next
            WinWait,Modern Warfare, System Requirements
            Sleep 500
            ControlClick Button1 ; Next
            Sleep 500
            ControlClick Button4 ; Next
            WinWait,Modern Warfare, Typical
            Sleep 500
            ControlClick Button4 ; License
            Sleep 500
            ControlClick Button1 ; Next
            WinWait,Question, shortcut
            Sleep 500
            ControlClick Button1 ; Yes
            WinWait,Microsoft DirectX Setup, license
            Sleep 500
            ControlClick Button1 ; Yes
            WinWait,Modern Warfare, finished
            Sleep 500
            ControlClick Button1 ; Finished
        }
        WinWaitClose,WinZip Self-Extractor - CoD4MWDemoSetup_v2
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Activision\\Call of Duty 4 - Modern Warfare Demo" "iw3sp.exe"
}

#----------------------------------------------------------------

w_metadata cod5_waw games \
    title="Call of Duty 5: World at War" \
    publisher="Activision" \
    year="2008" \
    media="dvd" \
    file1="5330161c7960f0770e6b05f498ab9fd13be4cfad.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Activision/Call of Duty - World at War/CoDWaW.exe"

load_cod5_waw()
{
    w_mount CODWAW
    
    w_read_key

    w_ahk_do "
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, Call of Duty, Key Code
        sleep 1000
        Send $W_KEY
        sleep 1000
        ControlClick, Button1, Call of Duty, Key Code
        winwait, Key Code Check
        sleep 1000
        controlclick, Button1, Key Code Check
        winwait, Call of Duty, License Agreement
        sleep 1000
        controlclick, Button5, Call of Duty, License Agreement
        sleep 1000
        controlclick, Button2, Call of Duty, License Agreement
        ; It wants to install PunkBuster here...OH BOY! Luckily, we can say no (see below)
        winwait, PunkBuster, Anti-Cheat software system
        sleep 1000
        controlclick, Button1, PunkBuster, Anti-Cheat software system
        winwait, Call of Duty, install PunkBuster
        sleep 1000
        ; Punkbuster: both are scripted below, so you can toggle which one you want.
        ; No:
        ; controlclick, Button2, Call of Duty, install PunkBuster
        ; Yes:
        controlclick, Button1, Call of Duty, install PunkBuster
        winwait, PunkBuster, License
        sleep 1000
        controlclick, Button5, PunkBuster, License
        sleep 1000
        controlclick, Button2, PunkBuster, License
        ; /end punkbuster
        winwait, Call of Duty, Minimum System
        sleep 1000
        controlclick, Button1, Call of Duty, Minimum System
        winwait, Call of Duty, Setup Type
        sleep 1000
        controlclick, Button1, Call of Duty, Setup Type
        ; Exits silently after install
        ; Need to wait here else next verb will run before this one is done
        winwaitclose, Call of Duty
    "

    # FIXME: Install latest updates

    if w_workaround_wine_bug 16241 "Working around sound bug by setting Win7 mode" 1.3.12,
    then
        set_app_winver CodWaW.exe win7
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Activision\\Call of Duty - World at War" "CoDWaW.exe"

    if w_workaround_wine_bug 219
    then
        w_warn "This game's copy-protection scheme does not currently work in Wine."
    else
        w_warn "This game is copy-protected, and requires the real disc in a real drive to run."
    fi
}

#----------------------------------------------------------

w_metadata cojbib_demo games \
    title="Call of Juarez: Bound in Blood Demo" \
    publisher="Ubisoft" \
    year="2009" \
    media="manual_download" \
    file1="CoJ2PC_20090713_DEMO_16_buy_now_INSTALLER.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Ubisoft/Demo/Techland/Call of Juarez - Bound in Blood SP Demo/CoJBiBDemo_x86.exe"

load_cojbib_demo()
{
    w_download_manual http://www.gamefront.com/files/14274183/CoJ2PC-20090713-DEMO-16-buy-now-INSTALLER.exe/ CoJ2PC_20090713_DEMO_16_buy_now_INSTALLER.exe 6426101f6c77bacd57c8449b12a3c76db7f761f0

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode 2
        SetWinDelay 500
        run CoJ2PC_20090713_DEMO_16_buy_now_INSTALLER.exe
        winwait Setup, language
        if ( w_opt_unattended > 0 ) {
            controlclick button1 ; next
            winwait Call of Juarez, Welcome
            controlclick button1 ; next
            winwait Call of Juarez, License
            controlclick button2 ; yes
            winwait Call of Juarez, Location
            controlclick button1 ; next
            winwait Call of Juarez, Start
            controlclick button1 ; next
        }
        winwait Call of Juarez, Complete
        if ( w_opt_unattended > 0 )
            controlclick button2 ; next

        winwaitclose Call of Juarez
    "

    if w_workaround_wine_bug 9612 "setting maxshadowsize=0"
    then
        w_call dsoundbug9612
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Ubisoft\\Demo\\Techland\\Call of Juarez - Bound in Blood SP Demo" "CoJBiBDemo_x86.exe"
}

#----------------------------------------------------------------

w_metadata civ4_demo games \
    title="Civilization IV Demo" \
    publisher="Firaxis Games" \
    year="2005" \
    media="manual_download" \
    file1="Civilization4_Demo.zip" \
    installed_file1="$W_PROGRAMS_X86_WIN/Firaxis Games/Sid Meier's Civilization 4 Demo/Civilization4.exe"

load_civ4_demo()
{
    w_download_manual http://download.cnet.com/Civilization-IV-demo/3000-7489_4-10465206.html Civilization4_Demo.zip b54f1e5d0a1c2d1ef456d0c20098c23bbb6a0ea7

    cd "$W_CACHE/$W_PACKAGE"
    w_try_unzip Civilization4_Demo.zip -d "$W_TMP"
    cd "$W_TMP/$W_PACKAGE"
    chmod +x setup.exe
    w_ahk_do "
        SetTitleMatchMode, 2
        run, setup.exe
        winwait, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            Send {enter}
            winwait, Civilization 4, Welcome
            ControlClick &Next >, Civilization 4
            winwait, Civilization 4, I &accept the terms of the license agreement
            ControlClick I &accept, Civilization 4
            ControlClick &Next >, Civilization 4
            winwait, Civilization 4, Express Install
            ControlClick &Next >, Civilization 4
            winwait, Civilization 4, begin installation
            ControlClick &Install, Civilization 4
            winwait, Civilization 4, InstallShield Wizard Complete
            ControlClick Finish, Civilization 4
        }
        winwaitclose
    "

    if w_workaround_wine_bug 6856
    then
        w_call msxml3
    fi
    if w_workaround_wine_bug 6856 # part 2, still need to file a bug
    then
        w_call d3dx9_26
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Firaxis Games\\Sid Meier's Civilization 4 Demo" "Civilization4.exe"
}

#----------------------------------------------------------------

w_metadata crayonphysics_demo games \
    title="Crayon Physics Deluxe demo" \
    publisher="Kloonigames" \
    year="2011" \
    media="download" \
    file1="crayon_release52demo.exe" \
    installed_exe1="$W_PROGRAMS_WIN/Crayon Physics Deluxe Demo/crayon.exe" \
    homepage="http://crayonphysics.com"

load_crayonphysics_demo()
{
    w_download \
        http://crayonphysicsdeluxe.s3.amazonaws.com/$file1 \
        4ffd64c630f69e7cf024ef946c2c64c8c4ce4eac
    # Inno Setup installer
    w_try $WINE "$W_CACHE/$W_PACKAGE/$file1" ${W_OPT_UNATTENDED:+ /sp- /silent /norestart}
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Crayon Physics Deluxe Demo" crayon.exe
}

#----------------------------------------------------------------

w_metadata crysis2 games \
    title="Crysis 2" \
    publisher="EA" \
    year="2011" \
    media="dvd" \
    file1="Crysis2.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Electronic Arts/Crytek/Crysis 2/bin32/Crysis2.exe"

load_crysis2()
{
    w_mount "Crysis 2"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay, 1000
        run ${W_ISO_MOUNT_LETTER}:EASetup.exe
        if ( w_opt_unattended > 0 ) {
            Loop {
                ; On Windows, this window does not pop up
                ifWinExist, Microsoft Visual C++ 2008 Redistributable Setup
                {
                    winwait, Microsoft Visual C++ 2008 Redistributable Setup
                    controlclick, Button12 ; Next
                    winwait, Visual C++, License
                    controlclick, Button11 ; Agree
                    controlclick, Button8 ; Install
                    winwait, Setup, configuring
                    winwaitclose
                    winwait, Visual C++, Complete
                    controlclick, Button2 ; Finish
                    break
                }
                ifWinExist, Setup, Please read the End User
                {
                    break
                }
                sleep 1000
            }
            winwait, Setup, Please read the End User
            controlclick, Button1     ; accept
            sleep 500
            ;controlclick, Button3     ; next
            send {Enter}
            ; Again for DirectX
            winwait, Setup, Please read the following End
            ;controlclick, Button1     ; accept
            send a
            sleep 1000
            ;controlclick, Button3     ; next
            send {Enter}
            winwait,Setup, Ready to install
            controlclick, Button1
        }
        winwait, Setup, Click the Finish button
        if ( w_opt_unattended > 0 ) {
            controlclick, Button5     ; Don't install EA Download Manager
            controlclick, Button1     ; Finish
        }
        winwaitclose
    "
    
    if w_workaround_wine_bug 26283
    then
        w_warn "The game has some nasty flickering, see http://bugs.winehq.org/show_bug.cgi?id=26283"
    fi
}

#----------------------------------------------------------------

w_metadata csi6_demo games \
    title="CSI: Fatal Conspiracy Demo" \
    publisher="Ubisoft" \
    year="2010" \
    media="manual_download" \
    file1="CSI6_PC_Demo_05.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Ubisoft/Telltale Games/CSI - Fatal Conspiracy Demo/CSI6Demo.exe"

load_csi6_demo()
{
    w_download_manual http://www.fileplanet.com/217175/download/CSI:-Fatal-Conspiracy-Demo CSI6_PC_Demo_05.exe 28473b4dc9760b659f24a397192b74d170b593bb

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run, CSI6_PC_Demo_05.exe
        winwait, Installer Language, Please select
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button1   ; Accept default (english)
            ;send {Enter}   ; Accept default (english)
            winwait, CSI - Fatal Conspiracy Demo Setup
            send {Enter}   ; Next
            winwait, CSI - Fatal Conspiracy Demo Setup, License
            send {Enter}   ; Agree
            winwait, CSI - Fatal Conspiracy Demo Setup, Location
            send {Enter}   ; Install
        }
        winwait, CSI - Fatal Conspiracy Demo Setup, Finish
        if ( w_opt_unattended > 0 ) {
            ControlClick Button4
            send {Enter}   ; Finish
            WinWaitClose
        }
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Ubisoft\\Telltale Games\\CSI - Fatal Conspiracy Demo" "CSI6Demo.exe"
}

#----------------------------------------------------------------

w_metadata darknesswithin2_demo games \
    title="Darkness Within 2 Demo" \
    publisher="Zoetrope Interactive" \
    year="2010" \
    media="manual_download" \
    file1="DarknessWithin2Demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Iceberg Interactive/Darkness Within 2 Demo/DarkLineage.exe"

load_darknesswithin2_demo()
{
    w_download_manual http://www.bigdownload.com/games/darkness-within-2-the-dark-lineage/pc/darkness-within-2-the-dark-lineage-demo DarknessWithin2Demo.exe

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, DarknessWithin2Demo.exe
        winwait, Darkness Within, will install
        if ( w_opt_unattended > 0 ) {
            ControlClick, TNewButton1
            winwait, Darkness, License
            ControlClick, TNewRadioButton1
            ControlClick, TNewButton2
            winwait, Darkness, Location
            ControlClick, TNewButton3
            winwait, Darkness, shortcuts
            ControlClick, TNewButton4
            winwait, Darkness, additional
            ControlClick, TNewButton4
            winwait, Darkness, Ready to Install
            ControlClick, TNewButton4
            winwait, PhysX, License
            ControlClick, Button3
            ControlClick, Button4
            winwait, PhysX, successfully
            ControlClick, Button1
        }
        winwait, Darkness, Setup has finished
        if ( w_opt_unattended > 0 ) {
            ControlClick, TNewListBoxButton1
            ControlClick, TNewButton4
        }
        winwaitclose, Darkness, Setup has finished
    "

    if w_workaround_wine_bug 23041
    then
        w_call d3dx9_36
    fi

    # you have to cd to the directory containing DarkLineage.exe before running it
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Iceberg Interactive\\Darkness Within 2 Demo" "DarkLineage.exe"
}

#----------------------------------------------------------------

w_metadata darkspore games \
    title="Darkspore" \
    publisher="EA" \
    year="2011" \
    media="dvd" \
    file1="DARKSPORE.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/Darkspore/DarksporeBin/Darkspore.exe" \
    homepage="http://darkspore.com/"

load_darkspore()
{
    # Mount disc, verify that expected file is present
    w_mount DARKSPORE Darkspore.ico
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        if ( w_opt_unattended > 0 ) {
            winwait, Choose Setup Language
            controlclick, Button1    ; ok (accept default, English)
            winwait, InstallShield Wizard, Welcome
            controlclick, Button1    ; Next
            winwait, InstallShield Wizard, License Agreement
            controlclick, Button3    ; Accept
            sleep 1000
            controlclick, Button1    ; Next
            winwait, InstallShield Wizard, Select Features
            controlclick, Button5    ; Next
            winwait, InstallShield Wizard, Ready to Install the Program
            controlclick, Button1    ; Install
            winwait, DirectX
            controlclick, Button1    ; Accept       
            sleep 1000
            controlclick, Button4    ; Next
            winwait, DirectX, DirectX setup
            controlclick, Button4
            winwait, DirectX, components installed
            controlclick, Button5    ; Finish
        }
        winwait, InstallShield Wizard, You are now ready
        if ( w_opt_unattended > 0 ) {
            controlclick, Button1    ; Uncheck View Readme.txt
            controlclick, Button4    ; Finish
        }
        WinWaitClose, InstallShield Wizard    
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\Darkspore\\DarksporeBin" "Darkspore.exe"
}

#----------------------------------------------------------------

w_metadata dcuo games \
    title="DC Universe Online" \
    publisher="EA" \
    year="2011" \
    media="dvd" \
    file1="DCUO - Disc 1.iso" \
    file2="DCUO - Disc 2.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Sony Online Entertainment/Installed Games/DC Universe Online Live/LaunchPad.exe"

load_dcuo()
{
    # The installer would take care of this, but let's do it first
    w_call flash
    if w_workaround_wine_bug 26298 "Installing microsoft runtime libraries"
    then
        w_call vcrun2005
    fi
    if w_workaround_wine_bug 27279 "Installing microsoft XAct audio"
    then
        w_call xact
    fi
    if w_workaround_wine_bug 25906 "Installing ie8"
    then
        w_call ie8
    fi

    w_mount "DCUO - Disc 1"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:setup.exe
        if ( w_opt_unattended > 0 ) {
	    winwait, DC Universe, Anti-virus
	    ControlClick, Button1   ; next
	    winwait, DC Universe, License
	    ControlClick, Button5   ; accept
	    sleep 500
	    ControlClick, Button2   ; next
	    winwait, DC Universe, Shortcut
	    ControlClick, Button3   ; next
	    Loop
	    {
		IfWinExist, DC Universe, not enough space
		{
		    exit 1          ; dang, have to quit
		}
		IfWinExist, DC Universe, Ready
		{
		    break
		}
		Sleep 1000
	    }
	    winwait, DC Universe, Ready
	    ControlClick, Button1   ; next
        }
        winwait, Setup Needs The Next Disk, Please insert disk 2
    "

    w_mount "DCUO - Disc 2"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        winwait, Setup Needs The Next Disk, Please insert disk 2
        if ( w_opt_unattended > 0 ) {
	    ControlClick, Button2   ; next
	    winwaitclose
	    Loop
	    {
		IfWinExist, DirectX, Welcome
		{
		    ControlClick, Button1   ; accept
		    Sleep 1000
		    ControlClick, Button4   ; next
		    WinWait, DirectX, Runtime Install
		    ControlClick, Button4   ; next
		    WinWait, DirectX, Complete
		    ControlClick, Button4   ; next
                    sleep 1000
                    process, close, dxsetup.exe   ; work around strange 'next button does nothing' bug
		}
		IfWinExist, Flash   ; a newer version of flash is already installed
		{
		    ControlClick, Button3   ; quit
		}
		IfWinExist, DC Universe, Complete
		{
		    break
		}
		Sleep 1000
	    }
        }
	WinWait, DC Universe, Complete
        if ( w_opt_unattended > 0 ) {
	    ControlClick, Button4   ; finish
        }
        winwaitclose
    "
    w_warn "Now let the wookie install itself, and then quit."
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Sony Online Entertainment\\Installed Games\\DC Universe Online Live" LaunchPad.exe
}

#----------------------------------------------------------------

w_metadata deadspace games \
    title="Dead Space" \
    publisher="EA" \
    year="2008" \
    media="dvd" \
    file1="DEADSPACE.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/Dead Space/Dead Space.exe"

load_deadspace()
{
    w_mount DEADSPACE

    if w_workaround_wine_bug 23324
    then
        msvcrun_me_harder="
            winwait, Microsoft
            controlclick, Button1
            "
    else
        msvcrun_me_harder=""
    fi

    w_read_key

    w_ahk_do "
        SetTitleMatchMode, 2
        ; note: if this is the second run, the installer skips the registration code prompt
        run, ${W_ISO_MOUNT_LETTER}:EASetup.exe
        winwait, Dead
        send {Enter}
        winwait, Dead, Registration Code
        send {RAW}$W_KEY
        Sleep 1000
        controlclick, Button2
        $msvcrun_me_harder
        winwait, Setup, License
        Sleep 1000
        controlclick, Button1
        Sleep 1000
        send {Enter}
        winwait, Setup, License
        Sleep 1000
        controlclick, Button1
        Sleep 1000
        send {Enter}
        winwait, Setup, Destination
        Sleep 1000
        controlclick, Button1
        winwait, Setup, begin
        Sleep 1000
        controlclick, Button1
        winwait, Setup, Finish
        Sleep 1000
        controlclick, Button5
        controlclick, Button1
    "

    if w_workaround_wine_bug 26079
    then
        w_call d3dx9_36
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\Dead Space" "Dead Space.exe"
}

#----------------------------------------------------------------

w_metadata deadspace2 games \
    title="Dead Space 2 (drm broken on wine)" \
    publisher="EA" \
    year="2011" \
    media="dvd" \
    file1="Disc1.iso" \
    file2="Disc2.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/EA Games/Dead Space 2/deadspace2.exe" \
    wine_showstoppers="25853"

load_deadspace2()
{
    if w_workaround_wine_bug 25853
    then
        w_warn "Non-steam versions of this game do not run on Wine because Wine does not support the version of SecuROM they use.  Proceed only if you want to run into this problem."
    fi
    w_read_key

    w_mount Disc1

    # Work around bug 25963 (fails to switch discs)
    w_warn "Copying discs to hard drive.  This will take a few minutes."
    cd "$W_TMP"
    # Copy takes a LONG time, so offer a way to avoid copy while debugging verb
    # You'll need to comment out the five "rm -rf"'s, too.
    if test ! -f easetup.exe      
    then
        w_try cp -R "$W_ISO_MOUNT_ROOT"/* .
        # Make the directories writable, else 2nd disc copy will fail.
        w_try chmod -R +w .
        w_mount Disc2
        # On Linux, use symlinks for disc 2.  (On Cygwin, we'd have to copy.)
        w_try ln -s "$W_ISO_MOUNT_ROOT"/*.dat .
        mkdir -p movies/en movies/fr
        w_try ln -s "$W_ISO_MOUNT_ROOT"/movies/en/* movies/en/
        w_try ln -s "$W_ISO_MOUNT_ROOT"/movies/fr/* movies/fr/
        # Make the files writable, otherwise you'll get errors when trying to remove the temp directory.
        chmod -R +w .
    fi

    # Install takes a long time, so offer a way to skip installation
    # and go straight to activation while debugging that
    if ! test -f "$W_PROGRAMS_X86_UNIX/EA Games/Dead Space 2/deadspace2.exe"
    then
      w_ahk_do "
        run easetup.exe
        if ( w_opt_unattended > 0 ) {
            SetTitleMatchMode, 2
            ; Not all systems need the Visual C++ runtime
            loop
            {
                ifwinexist, Microsoft Visual C++ 2008 Redistributable Setup
                {
                    sleep 500
                    controlclick, Button12 ; Next
                    winwait, Visual C++, License
                    sleep 500
                    controlclick, Button11 ; Agree
                    sleep 500
                    controlclick, Button8 ; Install
                    winwait, Setup, configuring
                    winwaitclose
                    winwait, Visual C++, Complete
                    sleep 500
                    controlclick, Button2 ; Finish
                    break
                }
                ifwinexist, Setup, Dead Space
                {
                    break
                }
                sleep 1000
            }
            winwait, Setup, License        ; Dead Space license
            sleep 500
            controlclick Button1  ; accept
            controlclick Button3  ; next
            SetTitleMatchMode, slow        ; since word DirectX in next dialog can only be read 'slowly'
            winwait, Setup, DirectX        ; DirectX license
            sleep 500
            controlclick Button1  ; accept
            controlclick Button3  ; next
            winwait, Setup, Ready to install
            sleep 500
            controlclick Button1  ; Install
        }
        winwait, Setup, Completed
        if ( w_opt_unattended > 0 ) {
            controlclick Button5  ; (Don't) install EA Download Manager
            controlclick Button1  ; Finish
        }
        winwaitclose
        "
    fi

    # Activate the game
    cd "$W_PROGRAMS_X86/EA Games/Dead Space 2"
    w_ahk_do "
        run activation.exe
        if ( w_opt_unattended > 0 ) {
            SetTitleMatchMode, 2
            WinWait, Product activation
            sleep 500
            controlclick TBitBtn2  ; Next
            WinWait, Product activation, Serial
            sleep 500
            send $W_KEY
            controlclick TBitBtn3  ; Next
            WinWait, Information
            sleep 4000             ; let user see what happened
            send {Enter}
        }
        WinWaitClose, Product activation
    "

    if w_workaround_wine_bug 21230
    then
        w_call d3dx9_36
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\EA Games\\Dead Space 2" deadspace2.exe
}

#----------------------------------------------------------------

w_metadata deusex2_demo games \
    title="Deus Ex 2 / Deus Ex: Invisible War Demo" \
    publisher="Eidos" \
    year="2003" \
    media="manual_download" \
    file1="dxiw_demo.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Deus Ex - Invisible War Demo/System/DX2.exe"

load_deusex2_demo()
{
    w_download_manual "http://www.techpowerup.com/downloads/1730/Deus_Ex:_Invisible_War_Demo.html" dxiw_demo.zip ccae48fb046d912b3714ea1b4be4294e74bb3092

    w_workaround_wine_bug 6971 "Please upgrade to wine-1.3.23 or later; see http://wiki.winehq.org/Bug6971" 1.3.23,

    w_try unzip "$W_CACHE/$W_PACKAGE/dxiw_demo.zip" -d "$W_TMP"
    cd "$W_TMP"
    w_ahk_do "
        SetTitleMatchMode 2
        SetWinDelay 500
        run setup.exe
        winwait Deus Ex, Launch
        if ( w_opt_unattended > 0 ) {
            controlclick button2
            winwait Deus Ex, Welcome
            controlclick button1
            winwait Deus Ex, License
            controlclick button3 ;accept
            controlclick button1 ;next
            winwait Deus Ex, Setup Type
            controlclick button4
            winwait Deus Ex, Install
            controlclick button1
            winwait Question, Readme
            controlclick button2
            winwait Question, play
            controlclick button2
        }
        winwait Deus Ex, Complete
        if ( w_opt_unattended > 0 )
            controlclick button4
        winwaitclose Deus Ex, Complete
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Deus Ex - Invisible War Demo\\System" "DX2.exe"
}

#----------------------------------------------------------------

w_metadata diablo2 games \
    title="Diablo II" \
    publisher="Blizzard" \
    year="2000" \
    media="cd" \
    file1="INSTALL.iso" \
    file2="PLAYDISC.iso" \
    file3="CINEMATICS.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Diablo II/Diablo II.exe"

load_diablo2()
{
    w_download http://ftp.blizzard.com/pub/diablo2/patches/PC/D2Patch_113c.exe c78761bfb06999a9788f25a23a1ed30260ffb8ab

    w_read_key

    w_mount INSTALL
    w_ahk_do "
        SetWinDelay 500
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, Diablo II Setup
        send {i}
        winwait, Choose Installation Size
        send {u}
        send {Enter}
        send {Raw}$USERNAME
        send {Tab}{Raw}$W_KEY
        send {Enter}
        winwait, Diablo II - choose install directory
        send {Enter}
        winwait, Desktop Shortcut
        send {N}
        winwait, Insert Disc"
    w_mount PLAYDISC
    # Needed by patch 1.13c to avoid disc swapping
    cp "$W_ISO_MOUNT_ROOT"/d2music.mpq "$W_PROGRAMS_UNIX/Diablo II/"
    w_ahk_do "
        send, {Enter}
        Sleep 1000
        winwait, Insert Disc"
    w_mount CINEMATICS
    w_ahk_do "
        send, {Enter}
        Sleep 1000
        winwait, Insert Disc"
    w_mount INSTALL
    w_ahk_do "
        send, {Enter}
        Sleep 1000
        winwait, View ReadMe?
        ControlClick &No, View ReadMe?
        winwait, Register Diablo II Electronically?
        send {N}
        winwait, Diablo II Setup - Video Test
        ControlClick &Cancel, Diablo II Setup - Video Test
        winclose, Diablo II Setup"

    cd "$W_CACHE"/$W_PACKAGE
    w_try "$WINE" D2Patch_113c.exe
    w_ahk_do "
        winwait, Blizzard Updater v2.72, has completed
        Sleep 1000
        send {Enter}
        winwait Diablo II
        Sleep 1000
        ControlClick &Cancel, Diablo II"
    # Dagnabbit, the darn updater starts the game after it updates, no matter what I do?
    killall "Game.exe"

    # Runs better in window
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Diablo II" "Diablo II.exe -d3d9 -w"
}

w_metadata digitanks_demo games \
    title="Digitanks Demo" \
    publisher="Lunar Workshop" \
    year="2011" \
    media="download" \
    file1="digitanks.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Digitanks/digitanksdemo.exe" \
    homepage="http://www.digitanks.com"

load_digitanks_demo()
{
    # 8 june 2011: f204b13dc64c1a54fb1aaf27187c6083ebb16acf
    # 11 Nov 2011: e54ffb07232f434bcfaf7b3d43ddf9affa93ef15
    w_download "http://static.digitanks.com/files/digitanks.exe" e54ffb07232f434bcfaf7b3d43ddf9affa93ef15
    cd "$W_CACHE/$W_PACKAGE"
    w_try "$WINE" $file1 ${W_OPT_UNATTENDED:+ /S}
    if w_workaround_wine_bug 26915 "installing corefonts"
    then
        w_call corefonts
    fi
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Digitanks" digitanksdemo.exe
}

w_metadata dirt2_demo games \
    title="Dirt 2 Demo" \
    publisher="Codemasters" \
    year="2009" \
    media="manual_download" \
    file1="Dirt2Demo.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Codemasters/DiRT2 Demo/dirt2.exe"

load_dirt2_demo()
{
    w_download_manual http://www.joystiq.com/game/dirt-2/download/dirt-2-demo/ Dirt2Demo.zip 13af1beb8c4f6300e4655045b66aea1f8a29f2b3

    mkdir "$W_TMP/$W_PACKAGE"
    w_try_unzip -d "$W_TMP/$W_PACKAGE" "$W_CACHE/$W_PACKAGE/Dirt2Demo.zip"

    if w_workaround_wine_bug 23532
    then
        w_call gfw 
    fi

    if w_workaround_wine_bug 24868
    then
        w_call d3dx9_36
    fi

    cd "$W_TMP/$W_PACKAGE"

    w_ahk_do "
        Run, "Setup.exe"
        WinWait, Choose Setup Language, Select
        if ( w_opt_unattended > 0 ) {
            sleep 500
            ControlClick Button1    ;next
            WinWait, DiRT2 Demo - InstallShield Wizard, Welcome
            sleep 500
            ControlClick Button1    ;next
            WinWait, DiRT2 Demo - InstallShield Wizard, License
            sleep 500
            ControlClick Button3    ;i accept
            sleep 500
            ControlClick Button1    ;next
            WinWait, DiRT2 Demo - InstallShield Wizard, Setup
            sleep 500
            ControlClick Button4    ;next
            WinWait, InstallShield Wizard, In order
            sleep 500
            ControlClick Button1    ;next
            WinWait, DiRT2 Demo - InstallShield Wizard, Ready
            sleep 500
            ControlClick Button1    ;next
        }
        WinWait, DiRT2 Demo - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            sleep 500
            ControlClick Button4    ;finish
        }
        WinWaitClose, DiRT2 Demo - InstallShield Wizard, Complete
        "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Codemasters\\DiRT2 Demo" "dirt2.exe"
}

#----------------------------------------------------------------

w_metadata divinity2_demo games \
    title="Divinity II Demo" \
    publisher="DTP Entertainment" \
    year="2010" \
    media="download" \
    file1="Divinity2_DEMO_EN.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/Divinity II - Ego Draconis - Demo/Bin/Divinity2_Demo.exe"

load_divinity2_demo()
{
    w_download "http://demos.dtp-entertainment.ag/Divinity2_DEMO_EN.exe" \
        01161a1375f5ee3bb215753e40dd1dcdceffd3a7

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        Run, Divinity2_DEMO_EN.exe
        SetTitleMatchMode, 2
        WinWait,Setup - Divinity II - Ego Draconis - Demo
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick TNewButton1 ; Next
            WinWait,Setup - Divinity II - Ego Draconis - Demo, read
            Sleep 500
            ControlClick TNewRadioButton1 ;agreement
            Sleep 500
            ControlClick TNewButton2 ; Next
            WinWait,Setup - Divinity II - Ego Draconis - Demo, into
            Sleep 500
            ControlClick TNewButton3 ; Next
            WinWait,Setup - Divinity II - Ego Draconis - Demo, place
            Sleep 500
            ControlClick TNewButton4 ; Next
            WinWait,Setup - Divinity II - Ego Draconis - Demo, installation
            Sleep 500
            ControlClick TNewButton4 ; Install
            Loop
            {
                IfWinExist, NVIDIA PhysX Setup, must
                {
                    WinWait,NVIDIA PhysX Setup, must
                    Sleep 500
                    ControlClick Button3 ;accept
                    Sleep 500
                    ControlClick Button4 ; Next
                    WinWait,NVIDIA PhysX Setup, been
                    Sleep 500
                    ControlClick Button1 ; Finish
                }
                IfWinExist,Setup - Divinity II - Ego Draconis - Demo, launched
                {
                    break
                }
                Sleep 2000
            }
            WinWait,Setup - Divinity II - Ego Draconis - Demo, launched
            Sleep 500
            ControlFocus, TNewCheckListBox1, Desktop
            Sleep 500
            Send {Space}
            Sleep 500
            ControlClick TNewButton4 ; Finish
        }
        WinWaitClose
    "

    if w_workaround_wine_bug 24417
    then
        w_call d3dx9_36
    fi
    if w_workaround_wine_bug 25329
    then
        w_call wmp9
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Divinity II - Ego Draconis - Demo\\Bin" "Divinity2_Demo.exe"
}

#----------------------------------------------------------------

w_metadata demolition_company_demo games \
    title="Demolition Company demo" \
    publisher="Giants Software" \
    year="2010" \
    media="manual_download" \
    file1="DemolitionCompanyDemoENv2.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Demolition Company Demo/DemolitionCompany.exe"

load_demolition_company_demo()
{
    w_download_manual http://www.demolitioncompany-thegame.com/demo.php DemolitionCompanyDemoENv2.exe

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, DemolitionCompanyDemoENv2.exe
        winwait, Setup - Demolition, This will install
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, TNewButton1, Setup - Demolition, This will install
            winwait, Setup - Demolition, License Agreement
            sleep 1000
            controlclick, TNewRadioButton1, Setup - Demolition, License Agreement
            sleep 1000
            controlclick, TNewButton2, Setup - Demolition, License Agreement
            winwait, Setup - Demolition, Setup Type
            sleep 1000
            controlclick, TNewButton2, Setup - Demolition, Setup Type
            winwait, Setup - Demolition, Ready to Install
            sleep 1000
            controlclick, TNewButton2, Setup - Demolition, Ready to Install
            winwait, Setup - Demolition, Completing
            sleep 1000
            controlclick, TNewButton2, Setup - Demolition, Completing
        }
        winwaitclose, Setup - Demolition
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Demolition Company Demo\\" "DemolitionCompany.exe"
}

#----------------------------------------------------------------

w_metadata dragonage games \
    title="Dragon Age: Origins" \
    publisher="Bioware / EA" \
    year="2009" \
    media="dvd" \
    file1="DragonAge.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Dragon Age/bin_ship/daorigins.exe"

load_dragonage()
{
    w_read_key

    if w_workaround_wine_bug 22191 "Installer has a non-fatal crash on exit"
    then
        w_call nocrashdialog
    fi
    # game can do this, why do we need to?
    w_call physx
    if w_workaround_wine_bug 24837 "Installing C++ runtime library"
    then
        w_call vcrun2005
    fi

    if test "$WINETRICKS_OPT_KEEPISOS" != 1 &&  \
        test ! -f "$W_CACHE/dragonage/DragonAge.iso" &&  \
        w_workaround_wine_bug 26459 "Making and mounting an .iso to work around 'Failed to authenticate the disk' error.  After each reboot, you'll need to do [sudo mount -o ro,loop '$W_CACHE/dragonage/DragonAge.iso' /mnt/winetricks] to play Dragon Age.  Someday this will be automated."
    then
        WINETRICKS_OPT_KEEPISOS=1 w_mount DragonAge
    else
        w_mount DragonAge
    fi

    w_ahk_do "
        SetWinDelay 1000
        Run, ${W_ISO_MOUNT_LETTER}:Setup.exe
        SetTitleMatchMode, 2
        winwait, Installer Language
        if ( w_opt_unattended > 0 ) {
            WinActivate
            send {Enter}
            winwait, Dragon Age: Origins Setup
            ControlClick Next, Dragon Age: Origins Setup
            winwait, Dragon Age: Origins Setup, End User License
            ;ControlClick Button4, Dragon Age: Origins Setup  ; agree
            send {Tab}a  ; agree
            ;ControlClick I agree, Dragon Age: Origins Setup
            send {Enter} ; continue
            SetTitleMatchMode, 1
            winwait, Dragon Age: Origins, Registration
            send $W_KEY
            send {Enter}
        }
        winwait, Dragon Age: Origins Setup, Install Type
        if ( w_opt_unattended > 0 )
            send {Enter}
        winwaitclose
    "
    # Since the installer explodes on exit, just wait for the
    # last file it's known to create
    while ! test -f "$W_PROGRAMS_X86_UNIX/Dragon Age/bin_ship/DAOriginsLauncher-MCE.png"
    do
        w_info "Waiting for installer to finish..."
        sleep 1
    done

    # FIXME: does this directory name change in win7?
    ini="$W_DRIVE_C/users/$USERNAME/My Documents/BioWare/Dragon Age/Settings/DragonAge.ini"
    if ! test -f "$ini"
    then
        w_warn "$ini not found?"
    else
        cp -f "$ini" "$ini.old"
    fi
    if w_workaround_wine_bug 22308 "Setting EnableFrameBufferEffects=0 to work around blurry cut scenes"
    then
        sed 's,EnableFrameBufferEffects=1,EnableFrameBufferEffects=0,' < "$ini" > "$ini.new"
        mv -f "$ini.new" "$ini"
    fi
    if w_workaround_wine_bug 22383 "use strictdrawordering to avoid video problems"
    then
        w_call strictdrawordering=enabled
    fi
    if w_workaround_wine_bug 22557 "Setting UseVSync=0 to avoid black menu"
    then
        sed 's,UseVSync=1,UseVSync=0,' < "$ini" > "$ini.new"
        mv -f "$ini.new" "$ini"
    fi
    if w_workaround_wine_bug 26435 "Setting SoundDisabled=0 to fix sound"
    then
        sed 's,SoundDisabled=1,SoundDisabled=0,' < "$ini" > "$ini.new"
        mv -f "$ini.new" "$ini"
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Dragon Age" "bin_ship\\daorigins.exe"

    w_workaround_wine_bug 26211 "You may need to kill DAO or its launcher after each run.  The Process view of taskmgr makes this relatively easy."
}

#----------------------------------------------------------------

w_metadata dragonage_ue games \
    title="Dragon Age: Origins - Ultimate Edition" \
    publisher="Bioware / EA" \
    year="2010" \
    media="dvd" \
    file1="DRAGONAGE-1.iso" \
    file2="DRAGONAGE-2.iso" 

load_dragonage_ue()
{
    w_read_key

    w_mount DRAGONAGE Setup.exe 1

    # Annoyingly, it runs a webrowser so you can activate the extra stuff. Disable that, and w_warn the user after install:
    WINEDLLOVERRIDES="winebrowser.exe="
    export WINEDLLOVERRIDES

    w_ahk_do "
        SetTitleMatchMode, 2
        SetTitleMatchMode, slow
        SetWinDelay 1000
        Run, ${W_ISO_MOUNT_LETTER}:Setup.exe
        winwait, Installer, English
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1, Installer, English
            winwait, Dragon Age: Origins Setup
            ControlClick Button2, Dragon Age: Origins Setup
            winwait, Dragon Age: Origins Setup, License Agreement
            ControlClick Button4, Dragon Age: Origins Setup
            ControlClick Button2, Dragon Age: Origins Setup
            winwait, Dragon Age: Origins, Registration
            controlclick, Edit1
            sleep 1000
            send $W_KEY
            send {Enter}
            winwait, Dragon Age: Origins Setup, Install Type
            controlclick, Button2, Dragon Age: Origins Setup, Install Type
            winwait, Dragon Age: Origins Setup, expanded content
            controlclick, Button1
        }
        winwait, Insert Disc...
    "
    w_mount DRAGONAGE data/ultimate_en.rar 2

    w_ahk_do "
        sleep 5000
        SetTitleMatchMode, 2
        if ( w_opt_unattended > 0 ) {
            controlclick, Button2, Insert Disc...
            winwait, Dragon Age, Setup was completed successfully
            controlclick, Button2, Dragon Age, Setup was completed successfully
        }
        winwait, Dragon Age, Click Finish to close
        if ( w_opt_unattended > 0 ) {
            controlclick, Button5, Dragon Age, Click Finish to close
            controlclick, Button2, Dragon Age, Click Finish to close
        }
        winwaitclose
    "

    if w_workaround_wine_bug 22307
    then
        w_warn "Turn off frame buffer effects to avoid blurry cut scenes.  See http://bugs.winehq.org/show_bug.cgi?id=22307"
    fi

    if w_workaround_wine_bug 22383
    then
        w_try_winetricks strictdrawordering=enabled
    fi

    if w_workaround_wine_bug 23730
    then
        w_warn "Run with WINEDEBUG=-all to reduce flickering."
    fi

    if w_workaround_wine_bug 23081
    then
        w_warn "If you still see flickering, try applying the patch from http://bugs.winehq.org/show_bug.cgi?id=23081"
    fi

    w_warn "To activate the additional content, visit http://social.bioware.com/redeem_code.php?path=/dragonage/pc/dlcactivate/en"

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Dragon Age" "bin_ship\\daorigins.exe"
}

#----------------------------------------------------------------

w_metadata dragonage2_demo games \
    title="Dragon Age II demo" \
    publisher="EA/Bioware" \
    year="2011" \
    media="download" \
    file1="DragonAge2Demo_F93M2qCj_EnEsItPlRu.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Dragon Age 2 Demo/bin_ship/DragonAge2Demo.exe"

load_dragonage2_demo()
{
    w_download http://na.llnet.bioware.cdn.ea.com/u/f/eagames/bioware/dragonage2/demo/DragonAge2Demo_F93M2qCj_EnEsItPlRu.exe a94715cd7943533a3cf1d84d40e667b04e1abc2e

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 500
        SetTitleMatchMode, 2
        run, DragonAge2Demo_F93M2qCj_EnEsItPlRu.exe
        winwait, Installer Language
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, Dragon Age II Demo Setup
            send {Enter}
            winwait, Dragon Age II Demo Setup, License
            send !a
            send {Enter}
            winwait, Dragon Age II Demo Setup, Select
            send {Enter}
        }
        winwait, Dragon Age II Demo Setup, Complete, completed
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, Dragon Age II Demo Setup, Completing
            send {Enter}
        }
        winwaitclose
    "
    if w_workaround_wine_bug 26205 "installing DirectX runtime libraries"
    then
        w_call d3dx9_36
        w_call d3dx11_43
    fi
    if w_workaround_wine_bug 26211 "installing native devenum to get sound in logo movie"
    then
        w_call devenum
    fi
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Dragon Age 2 Demo" "DragonAge2Launcher.exe"
}

#----------------------------------------------------------------

w_metadata eve games \
    title="EVE Online Tyrannis" \
    publisher="CCP Games" \
    year="2011" \
    media="download" \
    file1="EVE_Premium_Setup_264377_m.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/CCP/EVE/eve.exe"

load_eve()
{
    # http://www.eveonline.com/download/?fallback=1&
    w_download http://content.eveonline.com/EVE_Premium_Setup_264377_m.exe 00d930853c68d2a75f29558b344f885f6c2ff6a7

    if w_workaround_wine_bug 18221
    then
        w_call corefonts
    fi

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        run, $file1
        WinWait, EVE Online Installer
        if ( w_opt_unattended > 0 ) {
            WinActivate
            send {Enter}         ; Next
            WinWait, EVE,License Agreement
            WinActivate
            send {Enter}         ; Next
            WinWait, EVE,Choose Install
            WinActivate
            send {Enter}         ; Install
            WinWait, EVE,has been installed
            WinActivate
            ;Send {Tab}{Tab}{Tab} ; select Launch
            ;Send {Space}         ; untick Launch
            ControlClick Button4  ; untick Launch
            Send {Enter}         ; Finish (Button2)
        }
        WinWaitClose, EVE Online Installer
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\CCP\\EVE" "eve.exe"
}

#----------------------------------------------------------------

w_metadata fable_tlc games \
    title="Fable: The Lost Chapters" \
    publisher="Microsoft" \
    year="2005" \
    media="cd" \
    file1="FABLE_DISC_1.iso" \
    file2="FABLE DISC 2.iso" \
    file3="FABLE DISC 3.iso" \
    file4="FABLE DISC 4.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Games/Fable - The Lost Chapters/Fable.exe"

load_fable_tlc()
{
    w_read_key

    if w_workaround_wine_bug 657
    then
        w_call mfc42
    fi

    if test ! -f "$W_CACHE/$W_PACKAGE/FABLE_DISC_1.iso" && w_workaround_wine_bug 24940
    then
        # FIXME: port load_harder from winetricks and use it when caching first disc?
        w_warn "If the installer can't read from the CD, try using ddrescue to make image of first disc, and place in $W_CACHE/$W_PACKAGE/FABLE_DISC_1.iso"
    fi

    w_mount FABLE_DISK_1
    w_ahk_do "
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:setup.exe
        WinWait,Fable,Welcome
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button1 ; Next
            WinWait,Fable,Please
            Sleep 500
            ControlClick Button4 ; Next
            WinWait,Fable,Product Key
            Sleep 500
            Send $W_KEY
            Send {Enter}
        }
        WinWait,Fable,Disk 2
        "
    w_mount "FABLE DISK 2"
    w_ahk_do "
        SetTitleMatchMode, 2
        WinWait,Fable,Disk 2
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button2 ; Retry
        }
        WinWait,Fable,Disk 3
        "

    w_mount "FABLE DISK 3"
    w_ahk_do "
        SetTitleMatchMode, 2
        WinWait,Fable,Disk 3
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button2 ; Retry
        }
        WinWait,Fable,Disk 4
        "

    w_mount "FABLE DISK 4"
    w_ahk_do "
        SetTitleMatchMode, 2
        WinWait,Fable,Disk 4
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button2 ; Retry
        }
        WinWait,Fable,Disk 1
        WinKill
        "

    # Now tell game what the real disc is so user can insert disc 1 and run the game!
    # FIXME: don't guess it's D:
    cat > "$W_TMP"/$W_PACKAGE.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\D3BE9C3CAF4226447B48E06CAACF2DDD\InstallProperties]
"InstallSource"="D:\\"

_EOF_
    try_regedit "$W_TMP_WIN"\\$W_PACKAGE.reg

    # Also accept EULA
    cat > "$W_TMP"/$W_PACKAGE.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Microsoft\Microsoft Games\Fable TLC]
"FIRSTRUN"=dword:00000001

_EOF_
    try_regedit "$W_TMP_WIN"\\$W_PACKAGE.reg

    if w_workaround_wine_bug 24912
    then
        # kill off lingering installer
        w_ahk_do "
            SetTitleMatchMode, 2
            WinKill,Fable
        "
        killall IDriverT.exe
        killall IDriver.exe
    fi

    if w_workaround_wine_bug 25352
    then
        w_call devenum
        w_call quartz
        w_call wmp9
    fi

    if w_workaround_wine_bug 20074
    then
        w_call d3dx9_36
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Games\\Fable - The Lost Chapters" "Fable.exe"
}

#----------------------------------------------------------------

w_metadata farmsim2011_demo games \
    title="Farming Simulator 2011 Demo" \
    publisher="Astragon" \
    year="2011" \
    media="manual_download" \
    file1="FarmingSimulator2011DemoEN.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Farming Simulator 2011 Demo/game.exe"

load_farmsim2011_demo()
{
    # From http://www.landwirtschafts-simulator.de/demo.php
    w_download_manual http://www.landwirtschafts-simulator.de/demo.php FarmingSimulator2011DemoEN.exe c1221110e55625a3e797a3060c4bf5e3219bf2f0

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 500
        SetTitleMatchMode, 2
        run, FarmingSimulator2011DemoEN.exe
        if ( w_opt_unattended > 0 ) {
            WinWait, Setup - Farming Simulator 2011 Demo
            ControlClick TNewButton1   ; Next
            WinWait, Setup - Farming Simulator 2011 Demo, License Agreement
            ControlClick TNewRadioButton1   ; Accept
            ControlClick TNewButton2   ; Next
            WinWait, Setup - Farming Simulator 2011 Demo, Setup Type
            ControlClick TNewButton2   ; Next
            WinWait, Setup - Farming Simulator 2011 Demo, Ready to Install
            ControlClick TNewButton2   ; Install
        }
        WinWait, Setup - Farming Simulator 2011 Demo, finished
        if ( w_opt_unattended > 0 )
            ControlClick TNewButton2   ; Finish
        WinWaitClose
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Farming Simulator 2011 Demo" game.exe
}

#----------------------------------------------------------------

w_metadata fifa11_demo games \
    title="FIFA 11 Demo" \
    publisher="EA Sports" \
    year="2010" \
    media="download" \
    file1="fifa11_pc_demo_NA.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/EA Sports/FIFA 11 Demo/Game/fifa.exe"

load_fifa11_demo()
{
    # From http://www.ea.com/uk/football/news/fifa11-download-2
    w_download "http://static.cdn.ea.com/fifa/u/f/fifa11_pc_demo_NA.zip" c3a66284bffb985f31b11e477dade50c0d4cac52

    w_try unzip -d "$W_TMP" "$W_CACHE/$W_PACKAGE/fifa11_pc_demo_NA.zip"
    cd "$W_TMP"

    w_ahk_do "
        SetTitleMatchMode, 2
        run, EASetup.exe
        winwait, Microsoft Visual C++ 2008, wizard
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button12, Microsoft Visual C++ 2008, wizard
            winwait, Microsoft Visual C++ 2008, License Terms
            sleep 1000
            controlclick, Button11, Microsoft Visual C++ 2008, License Terms
            sleep 1000
            controlclick, Button8, Microsoft Visual C++ 2008, License Terms
            winwait, Setup, is configuring
            winwaitclose
            winwait, Microsoft Visual C++ 2008, Setup Complete
            sleep 1000
            controlclick, Button2
            ; There are two license agreements...one is for Directx
            winwait, FIFA 11, I &accept the terms in the End User License Agreement
            sleep 1000
            controlclick, Button1
            sleep 1000
            controlclick, Button3
            winwaitclose
            winwait, FIFA 11, I &accept the terms in the End User License Agreement
            sleep 1000
            controlclick, Button1, FIFA 11, I &accept the terms in the End User License Agreement
            sleep 1000
            controlclick, Button3, FIFA 11, I &accept the terms in the End User License Agreement
            winwait, FIFA 11, Ready to install FIFA 11
            sleep 1000
            controlclick, Button1, FIFA 11, Ready to install FIFA 11
        }
        winwait, FIFA 11, Click the Finish button to exit the Setup Wizard.
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button5, FIFA 11, Click the Finish button to exit the Setup Wizard.
            sleep 1000
            controlclick, Button1, FIFA 11, Click the Finish button to exit the Setup Wizard.
        }
        WinWaitClose
    "

    if w_workaround_wine_bug 22161
    then
        w_call d3dx9_36
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\EA Sports\\FIFA 11 Demo\\Game" "fifa.exe"
}

#----------------------------------------------------------------

w_metadata hon games \
    title="Heroes of Newerth" \
    publisher="S2 Games" \
    year="2010" \
    media="download" \
    file1="HoNClient-2.2.8.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Heroes of Newerth/hon.exe"

load_hon()
{
    w_download http://dl.heroesofnewerth.com/HoNClient-2.2.8.exe 15eb6fc4b5da5b2316e52d955dbfb0797496789c

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, $file1
        winwait, Heroes of Newerth
        u = $W_OPT_UNATTENDED
        if ( u > 0 ) {
            controlclick, Button2, Heroes of Newerth
            winwait, Heroes of Newerth, License
            controlclick, Button2, Heroes of Newerth, License
            winwait, Heroes of Newerth, Components
            controlclick, Button2, Heroes of Newerth, Components
            winwait, Heroes of Newerth, Install Location
            controlclick, Button2, Heroes of Newerth, Install Location
            winwait, Heroes of Newerth, Start Menu
            controlclick, Button2, Heroes of Newerth, Start Menu
            winwait, Heroes of Newerth, Finish
            controlclick, Button2, Heroes of Newerth, Finish
        }
        winwaitclose, Heroes of Newerth, Finish
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Heroes of Newerth" "hon.exe"
}

#----------------------------------------------------------------

w_metadata hordesoforcs2_demo games \
    title="Hordes of Orcs 2 Demo" \
    publisher="Freeverse" \
    year="2010" \
    media="manual_download" \
    file1="HoO2Demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Hordes of Orcs 2 Demo/HoO2.exe"

load_hordesoforcs2_demo()
{
    w_download_manual http://www.fileplanet.com/216619/download/Hordes-of-Orcs-2-Demo HoO2Demo.exe 1ba26d35697e359f89a30915140e471fadc675da

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        SetTitleMatchMode, slow
        run HoO2Demo.exe
        WinWait,Orcs
        if ( w_opt_unattended > 0 ) {
            WinActivate
            ControlFocus, Button1, Hordes ; Next
            sleep 500
            Send n       ; next
            WinWait,Orcs,conditions
            ControlFocus, Button4, Hordes, agree
            Send {Space}
            Send {Enter}  ; next
            WinWait,Orcs,files
            Send {Enter}  ; next
            WinWait,Orcs,exist              ; Destination does not exist, create?
            Send {Enter}  ; yes
            WinWait,Orcs,Start
            Send {Enter}  ; Start
        }
        WinWait,Orcs,successfully
        if ( w_opt_unattended > 0 ) {
            Send {Space}  ; Finish
        }
        winwaitclose Orcs
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Hordes of Orcs 2 Demo" "HoO2.exe"
}

#----------------------------------------------------------------

w_metadata mfsxde games \
    title="Microsoft Flight Simulator X: Deluxe Edition" \
    publisher="Microsoft" \
    year="2006" \
    media="dvd" \
    file1="FSX DISK 1.iso" \
    file2="FSX DISK 2.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Games/Microsoft Flight Simulator X/fsx.exe" \
    wine_showstoppers="26411"

load_mfsxde()
{
    w_workaround_wine_bug 26411 "Game hangs on first screen for me"

    if w_workaround_wine_bug 25139 "Setting virtual desktop so license screen shows up on first run"
    then
        w_call vd=1024x768
    fi

    w_mount "FSX DISK 1"

    if w_workaround_wine_bug 25558 "Copying disc to hard drive.  This will take a few minutes."
    then
        cd "$W_CACHE/$W_PACKAGE"
        # Copy takes a LONG time, so offer a way to avoid copy while debugging verb
        if test ! -f bothdiscs/setup.exe
        then
            mkdir bothdiscs
            cd bothdiscs
            w_try cp -R "$W_ISO_MOUNT_ROOT"/* .

            # A few files are on both DVDs. Remove them manually so cp doesn't complain.
            rm -f DVDCheck.exe autorun.inf fsx.ico vcredist_x86.exe

            # Make the directories writable, else 2nd disc copy will fail.
            w_try chmod -R +w .

            w_mount "FSX DISK 2"

            # On Linux, use symlinks for disc 2.  (On Cygwin, we'd have to copy.)
            w_try ln -s "$W_ISO_MOUNT_ROOT"/* .

            # Make the files writable, otherwise you'll get errors when trying to remove bothdiscs.
            chmod -R +w .

            # If you leave it mounted, it doesn't ask for the second disk to be inserted.
            # If you mount it without extracting though, the install fails. 
            # Apparently it uses the files from the cache, but does a disk check.
        else
            cd bothdiscs
        fi
    else
        w_die "non-broken case not yet supported for this game"
    fi

    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run setup.exe,,,mfs_pid
        winwait, Microsoft Flight Simulator X, To continue, click Install
        ControlClick, Button1, Microsoft Flight Simulator X, To continue
        ; Accept license:
        winwait, Flight Simulator X - End User License Agreement
        controlclick, Button1, Flight Simulator X - End User License Agreement
        winwait, Microsoft Flight Simulator X Product Activation Wizard
        ; Activate later, currently broken on Wine, see http://bugs.winehq.org/show_bug.cgi?id=25579
        controlclick, Button2, Microsoft Flight Simulator X Product Activation Wizard
        sleep 1000
        controlclick, Button5, Microsoft Flight Simulator X Product Activation Wizard
        ; Close main window:
        winwait, Microsoft Flight Simulator, LEARNING CENTER
        ; A winclose/winkill isn't forceful enough:
        process, close, fsx.exe
        ; Setup doesn't close on its own, because this process doesn't exit cleanly
        process, close, IDriver.exe
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Games\\Microsoft Flight Simulator X" "fsx.exe"
}

#----------------------------------------------------------------

w_metadata mfsx_demo games \
    title="Microsoft Flight Simulator X Demo" \
    publisher="Microsoft" \
    year="2006" \
    media="download" \
    file1="FSXDemo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Games/Microsoft Flight Simulator X Demo/fsx.exe" \
    wine_showstoppers="26411"

load_mfsx_demo()
{
    w_workaround_wine_bug 26411 "Game hangs on first screen for me"

    if w_workaround_wine_bug 25139 "Setting virtual desktop so license screen shows up on first run"
    then
        w_call vd=1024x768
    fi

    w_download http://download.microsoft.com/download/4/7/7/477dcc35-0b98-42c5-b06f-7ded38a40491/FSXDemo.exe cbb13d2a7918f409f224eab7d3a2014330fc87bc
    cd "$W_TMP"
    unzip "$W_CACHE/$W_PACKAGE"/FSXDemo.exe
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run setup.exe,,,mfs_pid
        winwait, Microsoft Flight Simulator X, To continue, click Install
        ControlClick, Button1, Microsoft Flight Simulator X, To continue
        ; Accept license:
        winwait, Flight Simulator X - End User License Agreement
        controlclick, Button1, Flight Simulator X - End User License Agreement
        winwait, Microsoft Flight Simulator X Product Activation Wizard
        ; Activate later, currently broken on Wine, see http://bugs.winehq.org/show_bug.cgi?id=25579
        controlclick, Button2, Microsoft Flight Simulator X Product Activation Wizard
        sleep 1000
        controlclick, Button5, Microsoft Flight Simulator X Product Activation Wizard
        ; Close main window:
        winwait, Microsoft Flight Simulator, LEARNING CENTER
        ; A winclose/winkill isn't forceful enough:
        process, close, fsx.exe
        ; Setup doesn't close on its own, because this process doesn't exit cleanly
        process, close, IDriver.exe
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Games\\Microsoft Flight Simulator X" "fsx.exe"
}

#----------------------------------------------------------------

w_metadata gothic4_demo games \
    title="Gothic 4 demo (drm broken on wine)" \
    publisher="Jowood" \
    year="2010" \
    media="manual_download" \
    file1="ArcaniA_Gothic4_Demo_Setup.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/JoWooD Entertainment AG/ArcaniA - Gothic 4 Demo/Arcania.exe" \
    wine_showstoppers="7065"

# http://appdb.winehq.org/objectManager.php?sClass=version&iId=21507

load_gothic4_demo()
{
    if w_workaround_wine_bug 7065
    then
        w_warn "Non-steam versions of this game do not run on Wine because Wine does not support the version of SecuROM they use.  Proceed only if you want to run into this problem."
    fi

    w_download_manual http://www.gamershell.com/download_63874.shtml ArcaniA_Gothic4_Demo_Setup.zip d36024c0235878c4589234a56cc8b6e05da5c593

    cd "$W_TMP"
    w_try unzip "$W_CACHE/$W_PACKAGE"/ArcaniA_Gothic4_Demo_Setup.zip

    w_ahk_do "
        Settitlematchmode, 2
        run, ArcaniA_Gothic4_Demo_Setup.exe
        if ( w_opt_unattended > 0 ) {
            winwait, Select Setup Language
            sleep 1000
            controlclick, TNewButton1, Select Setup Language
            winwait, Setup - ArcaniA, Welcome to the
            sleep 1000
            controlclick, TNewButton1, Setup - ArcaniA, Welcome to the
            winwait, Setup - ArcaniA, License Agreement
            sleep 1000
            controlclick, TNewRadioButton1, Setup - ArcaniA, License Agreement
            sleep 1000
            controlclick, TNewButton2, Setup - ArcaniA, License Agreement
            winwait, Setup - ArcaniA, Select Destination Location
            sleep 1000
            controlclick, TNewButton3, Setup - ArcaniA, Select Destination Location
            winwait, Setup - ArcaniA, Select Components
            sleep 1000
            controlclick, TNewButton3, Setup - ArcaniA, Select Components
            winwait, Setup - ArcaniA, Select Start Menu
            sleep 1000
            controlclick, TNewButton4, Setup - ArcaniA, Select Start Menu
            winwait, Setup - ArcaniA, Select Additional
            sleep 1000
            controlclick, TNewButton4, Setup - ArcaniA, Select Additional
            winwait, Setup - ArcaniA, Ready to Install
            sleep 1000
            controlclick, TNewButton4, Setup - ArcaniA, Ready to Install
            winwait, Setup - ArcaniA, Information
            sleep 1000
            controlclick, TNewButton4, Setup - ArcaniA, Information
        }
        winwait, Setup - ArcaniA, Completing
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ; The two checkboxes share the same button id. App/Wine bug?
            mousemove, 190, 155
            click
            sleep 1000
            mousemove, 190, 180
            click
            sleep 1000
            controlclick, TNewButton4, Setup - ArcaniA, Completing
        }
        winwaitclose
    "

    if w_workaround_wine_bug 21939
    then
        w_call wmp9
    fi

    if w_workaround_wine_bug 24250
    then
        w_call vcrun2008
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\JoWooD Entertainment AG\\ArcaniA - Gothic 4 Demo" "Arcania.exe"
}

#----------------------------------------------------------------

w_metadata gta_vc games \
    title="Grand Theft Auto: Vice City" \
    publisher="Rockstar" \
    year="2003" \
    media="cd" \
    file1="GTA_VICE_CITY.iso" \
    file2="VICE_CITY_PLAY.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Rockstar Games/Grand Theft Auto Vice City/gta-vc.exe"

load_gta_vc()
{
    w_mount GTA_VICE_CITY
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        Run, ${W_ISO_MOUNT_LETTER}:Setup.exe
        winwait, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            Send {enter}
            winwait, Grand Theft Auto Vice City, Welcome to the InstallShield Wizard
            Send {enter}
            winwait, Grand Theft Auto Vice City, License Agreement
            Send !a
            send {enter}
            winwait, Grand Theft Auto Vice City, Customer Information
            controlclick, edit1
            send $USERNAME
            send {tab}
            send company ; installer won't proceed without something here
            send {enter}
            winwait, Grand Theft Auto Vice City, Choose Destination Location
            controlclick, Button1
            winwait, Grand Theft Auto Vice City, Select Components
            controlclick, Button2
            winwait, Grand Theft Auto Vice City, Ready to Install the Program
            send {enter}
        }
        winwait, Setup Needs The Next Disk, Please insert disk 2
    "
    w_mount VICE_CITY_PLAY
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        winwait, Setup Needs The Next Disk, Please insert disk 2
        if ( w_opt_unattended > 0 ) {
            controlclick, Button2
        }
        winwait, Grand Theft Auto Vice City, InstallShield Wizard Complete
        if ( w_opt_unattended > 0 ) {
            send {enter}
        }
        winwaitclose
    "

    if w_workaround_wine_bug 26322 "Setting virtual desktop"
    then
        w_call vd=800x600
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Rockstar Games\\Grand Theft Auto Vice City" gta-vc.exe

    myexec="Exec=env WINEPREFIX=\"$HOME/.local/share/wineprefixes/gta_vc\" wine cmd /c 'C:\\\\\\Run-gta_vc.bat'"
    mymenu="$HOME/.local/share/applications/wine/Programs/Rockstar Games/Grand Theft Auto Vice City/Play GTA Vice City.desktop"
    if test -f "$mymenu" && w_workaround_wine_bug 26304 "Fixing system menu"
    then
        # this is a hack, hopefully the wine bug will be fixed soon
        sed -i "s,Exec=.*,$myexec," "$mymenu"
    fi
}

#----------------------------------------------------------------

w_metadata guildwars games \
    title="Guild Wars" \
    publisher="NCsoft" \
    year="2005" \
    media="download" \
    file1="GwSetup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Guild Wars/Gw.exe" \
    homepage="http://www.guildwars.com"

load_guildwars()
{
    w_download "http://guildwars.com/download/" a7c4c8cb3b8cbee20707dcf8176d3da6a1686c05 GwSetup.exe

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        Run, GwSetup.exe
        WinWait, ahk_class ArenaNet_Dialog_Class
        if ( w_opt_unattended > 0 ) {
            ; Wait for network connection to finish.  This might need to be longer.  Can we detect this better?
            Sleep 6000
            ; For some reason, the OK doesn't take for me unless I activate the window first
            WinActivate
            Send {Enter}
            ; Installation takes a long time... and then starts the game, which we don't want.
        }
        WinWait, ahk_class ArenaNet_Dx_Window_Class
        Sleep 4000
        WinClose, ahk_class ArenaNet_Dx_Window_Class
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Guild Wars" "Gw.exe"
}

#----------------------------------------------------------------
 
w_metadata hegemonygold_demo games \
    title="Hegemony Gold" \
    publisher="Longbow Games" \
    year="2011" \
    media="download" \
    file1="HegemonyGoldInstaller.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Longbow Digital Arts/Hegemony Gold/Hegemony Gold.exe" \
    homepage="http://www.longbowgames.com/forums/topic/?id=2146" \
    rating="bronze"

load_hegemonygold_demo()
{
    if w_workaround_wine_bug 25767
    then
        w_warn "This game works, but has some rendering glitches in Wine."
    fi

    # 6 Mar 2011: 8c4d8aa8f997b106c78b065a4b200e5e1ab846a8
    # 28 Apr 2011: 93677013fc17f014b1640bed070e8bb1b2a17445
    # 25 Jun 2011: 4069656ea3c3760b67d1c5adff37de7472955f72
    # 5 Nov 2011: 723c575ff5fff77941a1c786e28f46c094b8159c

    w_download "http://www.longbowgames.com/downloads/Hegemony%20Gold%20Installer.exe" 723c575ff5fff77941a1c786e28f46c094b8159c HegemonyGoldInstaller.exe

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetWinDelay 500
        SetTitleMatchMode, 2
        Run, HegemonyGoldInstaller.exe
        WinWait,Hegemony
        if ( w_opt_unattended > 0 ) {
            ControlClick Button2 ; Next
            WinWait,Hegemony, License
            ControlClick Button2 ; Agree
            WinWait,Hegemony, Components
            Click, Left, 187, 185
            Sleep 500
            ControlClick Button2 ; Next
            WinWait,Hegemony, Location
            ControlClick Button2 ; Next
            WinWait,Hegemony, shortcuts
            ControlClick Button2 ; Install
            WinWait,Hegemony, Completing
            ControlFocus,Button4,launch
            Sleep 1000
            Send {Space}
            Sleep 500
            ControlClick Button2 ; finish
        }
        WinWaitClose,Hegemony
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Longbow Digital Arts\\Hegemony Gold" "Hegemony Gold.exe"
}

#----------------------------------------------------------------

w_metadata hegemony_demo games \
    title="Hegemony: Philip of Macedon Demo" \
    publisher="Longbow Games" \
    year="2010" \
    media="download" \
    file1="Hegemony_Philip_of_Macedon_Installer.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Longbow Digital Arts/Hegemony Philip of Macedon/Hegemony Philip of Macedon.exe"

load_hegemony_demo()
{
    # Oct 2010: d3d2aa020d38b594d112360ae40871662d35dea4
    # Nov 2010: 80cad805ad4bed0d3c493f2d9a40d06512c429a9 http://www.longbowgames.com/forums/topic/?id=2223&start=0#post22184
    # Feb 16 2011: 38e92e3e4d0f0d10393790bc37350a2094f60c37
    w_download "http://www.longbowgames.com/downloads/Hegemony%20Philip%20of%20Macedon%20Installer.exe" 38e92e3e4d0f0d10393790bc37350a2094f60c37 Hegemony_Philip_of_Macedon_Installer.exe

    cd "$W_CACHE/$W_PACKAGE"

    if w_workaround_wine_bug 24819
    then
        w_override_dlls disabled gameux
    fi

    w_ahk_do "
        SetTitleMatchMode, 2
        run, Hegemony_Philip_of_Macedon_Installer.exe
        winwait, Hegemony, installation
        if ( w_opt_unattended > 0 ) {
            controlclick, Button2
            Sleep 500
            winwait, Hegemony, License
            controlclick, Button2
            winwait, Hegemony, Components
            controlclick, Button2
            winwait, Hegemony, Install Location
            controlclick, Button2
            winwait, Hegemony, shortcuts
            controlclick, Button2
            Loop
            {
                ; Work around wine bug 24484
                IfWinExist, Log message, IKnownFolderManager
                {
                    send {Enter}
                }
                ; Work around wine bug 21261
                IfWinExist, Log message, Games Explorer
                {
                    send {Enter}
                }
                IfWinExist, Hegemony, has been installed
                {
                    break
                }
                Sleep (2000)
            }
            winwait, Hegemony, has been installed
            Sleep 500
            controlclick, Button4
            Sleep 500
            controlclick, Button2
        }
        WinWaitClose,Hegemony
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Longbow Digital Arts\\Hegemony Philip of Macedon" "Hegemony Philip of Macedon.exe"
}

#----------------------------------------------------------------

w_metadata hphbp_demo games \
    title="Harry Potter & The Half Blood Prince Demo" \
    publisher="EA" \
    year="2009" \
    media="download" \
    file1="Release_HBP_demo_PC_DD_DEMO_Final_348428.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/Harry Potter and the Half-Blood Prince Demo/pc/hp6_demo.exe"

load_hphbp_demo()
{
    case "$LANG" in
    ""|"C") w_die "Harry Potter will not install in the Posix locale; please do 'export LANG=en_US.UTF-8' or something like that" ;;
    esac

    w_download http://largedownloads.ea.com/pub/demos/HarryPotter/Release_HBP_demo_PC_DD_DEMO_Final_348428.exe dadc1366c3b5e641454aa337ad82bc8c5082bad2

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, Release_HBP_demo_PC_DD_DEMO_FINAL_348428.exe
        winwait, Harry Potter, Install
        if ( w_opt_unattended > 0 ) {
            controlclick, Button1, Harry Potter
            winwait, Setup, License
            controlclick, Button1
            controlclick, Button3
            winwait, Setup, License
            controlclick, Button1
            controlclick, Button3
            winwait, Setup, Destination
            controlclick, Button1
            winwait, Setup, begin
            controlclick, Button1
        }
        winwait, Setup, Finish
        if ( w_opt_unattended > 0 )
            controlclick, Button1
        winwaitclose
    "

    # Work around locale issues by symlinking the app's directory to not have a funny char
    # Won't really work on cygwin, but that's ok.
    cd "$W_PROGRAMS_X86_UNIX/Electronic Arts"
    ln -s "Harry Potter and the Half-Blood Prince"* "Harry Potter and the Half-Blood Prince Demo"

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\Harry Potter and the Half-Blood Prince Demo\\pc" hp6_demo.exe
}

#----------------------------------------------------------------

w_metadata imvu games \
    title="IMVU - Instant Messaging Virtual Universe" \
    publisher="IMVU" \
    year="2004" \
    media="download" \
    file1="InstallIMVU_465.0_st_c.exe" \
    installed_exe1="c:/users/$LOGNAME/Application Data/IMVUClient/IMVUClient.exe"

load_imvu()
{
    w_download http://static-akm.imvu.com/imvufiles/installers/InstallIMVU_465.0_st_c.exe 3a5c6c335227a5709c5772f91d8407edd07d4012

    if w_workaround_wine_bug 28541 "Installing Visual C++ 2008 runtime to avoid crash on startup"
    then
        w_call vcrun2008
    fi

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        Run, $file1
        if ( w_opt_unattended > 0 ) {
            WinWait,IMVU Setup, IMVU Extension
            ControlClick Button4 ; Don't install extension
            Sleep 500
            ControlClick Button2 ; Finish
            ; There's no way to tell it not to launch
            WinWait,IMVU Login, chrome
            Click, Left, 29, 230  ; Uncheck [run on startup]
            Sleep 500
            Click, Left, 416, 11  ; Click X on window decoration to close
            Sleep 500
            WinKill,IMVU Login, chrome ; and then close harshly, just in case?
        }
        winwaitclose
    "

    w_declare_exe "c:\\users\\$LOGNAME\\Application Data\\IMVUClient" "IMVUClient.exe"
}

#----------------------------------------------------------------

w_metadata kotor1 games \
    title="Star Wars: Knights Of The Old Republic" \
    publisher="Lucas Arts" \
    year="2003" \
    media="cd" \
    file1="KOTOR_1.iso" \
    file2="KOTOR_2.iso" \
    file3="KOTOR_3.iso" \
    file4="KOTOR_4.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/LucasArts/SWKotOR/swkotor.exe"

load_kotor1()
{
    # without virtual desktop, some in-game resolutions cause a crash.
    if w_workaround_wine_bug 16596
    then
        w_call vd=800x600
    fi

    w_mount "KOTOR_1"
    w_ahk_do "
        SetTitleMatchMode 2
        SetWinDelay 500
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait Star Wars, Welcome
        if ( w_opt_unattended > 0 ) {
            controlclick button1
            winwait Star Wars, Licensing Agreement
            controlclick button2
            winwait Question, Licensing Agreement
            controlclick button1
            winwait Star Wars, Destination Folder
            controlclick button1
            winwait Star Wars, Program Folder
            controlclick button2
            winwait Star Wars, Additional Shortcuts
            ;unselect start menu shortcuts
            controlclick button1
            controlclick button2
            controlclick button3
            controlclick button4
            controlclick button5
            controlclick button11
            winwait Star Wars, Review settings
            controlclick button1
        }
        winwait Next Disk, Please insert disk 2
    "
    w_mount "KOTOR_2"
    w_ahk_do "
        SetTitleMatchMode 2
        if ( w_opt_unattended > 0 ) {
            winwait Next Disk
            controlclick button2
        }
        winwait Next Disk, Please insert disk 3
    "
    w_mount "KOTOR_3"
    w_ahk_do "
        SetTitleMatchMode 2
        if ( w_opt_unattended > 0 ) {
            winwait Next Disk
            controlclick button2
        }
        winwait Next Disk, Please insert disk 4
    "
    w_mount "KOTOR_4"
    w_ahk_do "
        SetTitleMatchMode 2
        if ( w_opt_unattended > 0 ) {
            winwait Next Disk
            controlclick button2
            winwait Question, Desktop
            controlclick button2
            winwait Question, DirectX
            controlclick button2 ;don't install directx
        }
        winwait Star Wars, Complete
        if ( w_opt_unattended > 0 ) {
            controlclick button1 ;don't launch game
            controlclick button4
        }
        winwaitclose Star Wars, Complete
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\LucasArts\\SWKotOR" "swkotor.exe"
}

#--------------------------------------------------------------------

w_metadata kotor2 games \
    title="Star Wars: Knights of the Old Republic 2" \
    publisher="LucasArts" \
    year="2005" \
    media="cd" \
    file1="K2_UK_v_1_0_dsc_.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/LucasArts/SWKotOR2/swkotor2.exe"

load_kotor2()
{
    if w_workaround_wine_bug 16596
    then
        w_call vd=800x600
    fi

    w_mount "K2_UK_v_1_0_dsc_"
    w_ahk_do "
        SetTitleMatchMode 2
        SetWinDelay 500
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait Star Wars, Welcome
        if ( w_opt_unattended > 0 ) {
            controlclick button1
            winwait Star Wars, License Agreement
            controlclick button2
            winwait Question, Licensing Agreement
            controlclick button1
            winwait Star Wars, Destination Location
            controlclick button1
            winwait Star Wars, Program Folder
            controlclick button2
        }
        winwait Next Disk, disk 2
    "
    w_umount
    w_mount "K2_UK_v_1_0_dsc_"
    w_ahk_do "
        SetTitleMatchMode 2
        winwait Next Disk, disk 2
        if ( w_opt_unattended > 0 )
            controlclick button2
        winwait Next Disk, disk 3
    "
    w_umount
    w_mount "K2_UK_v_1_0_dsc_"
    w_ahk_do "
        SetTitleMatchMode 2
        winwait Next Disk, disk 3
        if ( w_opt_unattended > 0 )
            controlclick button2
        winwait Next Disk, disk 4
    "
    w_umount
    w_mount "K2_UK_v_1_0_dsc_"
    w_ahk_do "
        SetTitleMatchMode 2
        winwait Next Disk, disk 4
        if ( w_opt_unattended > 0 )
            controlclick button2
        winwait Next Disk, Play disc
    "
    w_umount
    w_mount "K2_UK_v_1_0_dsc_"
    w_ahk_do "
        SetTitleMatchMode 2
        SetWinDelay 500
        winwait Next Disk, Play disc
        if ( w_opt_unattended > 0 ) {
            controlclick button2
            winwait Question, shortcut
            controlclick button1
            winwait Question, DirectX
            controlclick button2
        }
        winwait Star Wars, Wizard Complete
        if ( w_opt_unattended > 0 ) {
            controlclick button1
            controlclick button2
            controlclick button4
        }
        winwaitclose Star Wars, Wizard Complete
    "

    # download 1.0a and 1.0b patches
    w_download "ftp://ftp.lucasarts.com/patches/pc/KotOR2 Patch v201420 UK.exe" ab97a0d41ae15782418d0fd1b2ad43ccf35ca070
    w_download "ftp://ftp.lucasarts.com/patches/pc/sw_pc_uk_from201420_to211427.exe" cf4ed797a0314b3ca047012f732321c6ba9a2388

    cd "$W_CACHE/$W_PACKAGE"

    # install 1.0a patch
    w_ahk_do "
        SetTitleMatchMode 2
        SetWinDelay 500
        run KotOR2 Patch v201420 UK.exe
        winwait RTPatch Software, 1.0a
        if ( w_opt_unattended > 0 ) {
            controlclick button1
            winwait RTPatch Software, updated
            controlclick button1
        }
        winwaitclose RTPatch Software
    "

    # install 1.0b patch
    w_ahk_do "
        SetTitleMatchMode 2
        SetWinDelay 500
        run sw_pc_uk_from201420_to211427.exe
        winwait RTPatch Software, 1.0b
        if ( w_opt_unattended > 0 ) {
            controlclick button1
            winwait Update1_0b.txt
            winclose Update1_0b.txt ;close readme that pops up
            winwait RTPatch Software, updated
            controlclick button1
        }
        winwaitclose RTPatch Software
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\LucasArts\\SWKotOR2" "swkotor2.exe"
}

#----------------------------------------------------------------

w_metadata losthorizon_demo games \
    title="Lost Horizon Demo" \
    publisher="Deep Silver" \
    year="2010" \
    media="manual_download" \
    file1="Lost_Horizon_Demo_EN.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Deep Silver/Lost Horizon Demo/fsasgame.exe"

load_losthorizon_demo()
{
    w_download_manual http://www.fileplanet.com/215704/download/Lost-Horizon-Demo Lost_Horizon_Demo_EN.exe

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        run Lost_Horizon_Demo_EN.exe
        WinWait,Lost Horizon Demo, Destination
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            Send {RAW}"$W_TMP"
            ControlClick Button2 ;Install
            WinWaitClose,Lost Horizon Demo,Installation
            Sleep 1000
            Click, Left, 169, 371
            WinWait,Lost Horizon Demo - InstallShield Wizard,Welcome
            Sleep 500
            ControlClick Button1 ;Next
            WinWait,Lost Horizon Demo - InstallShield Wizard,License
            ControlFocus,Button3,Lost Horizon Demo
            Sleep 500
            Send {Space}
            ControlClick Button1 ;Next
            WinWait,Lost Horizon Demo - InstallShield Wizard,program
            Sleep 500
            ControlClick Button2 ;Next
            WinWait,Lost Horizon Demo - InstallShield Wizard,features
            Sleep 500
            ControlClick Button4 ;Next
            WinWait,Lost Horizon Demo - InstallShield Wizard,begin
            Sleep 500
            ControlClick Button1 ;Next
        }
        WinWaitClose
        WinWait,Lost Horizon Demo - InstallShield Wizard,Complete
        if ( w_opt_unattended > 0 ) {
            ControlFocus,Button2,Lost Horizon
            Sleep 500
            Send {Space}
            Sleep 500
            ControlClick Button4 ; Finish
        }
        WinWaitClose
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Deep Silver\\Lost Horizon Demo" "fsasgame.exe"
}

#----------------------------------------------------------------

w_metadata lego_potc_demo games \
    title="Lego Pirates of the Caribbean Demo" \
    publisher="Travellers Tales" \
    year="2011" \
    media="manual_download" \
    file1="LPOTC_PC_Demo.zip" \
    installed_file1="$W_PROGRAMS_X86_WIN/Disney Interactive Studios/LEGO Pirates DEMO/LEGOPiratesDEMO.exe"

load_lego_potc_demo()
{
    w_download_manual http://www.gamershell.com/download_73976.shtml LPOTC_PC_Demo.zip 3025dcbbee9ff2d74d7837a78ef5b7aceae15d8f
    cd "$W_TMP"
    w_info "Unpacking $file1"
    w_try_unzip "$W_CACHE/$W_PACKAGE/$file1" LPOTC_PC_Demo.exe
    w_ahk_do "
        SetWinDelay, 500
        SetTitleMatchMode, 2
        SetTitleMatchMode, slow        ; since word English in first dialog can only be read 'slowly'
        run LPOTC_PC_Demo.exe
        if ( w_opt_unattended > 0 ) {
            winwait,LEGO,English
            sleep 500
            winactivate
            send {Tab}{Tab}{Enter}
            winwaitclose,LEGO,English

            winwait, LEGO, License
            winactivate
            send {Space}
            sleep 500
            send {Enter}
            winwaitclose, LEGO, License

            winwait, DirectX
            ControlClick, Button1  ; next
            ;send {Enter}  ; next
            winwaitclose, DirectX

            winwait, LEGO, License       ; DIRECTX shows up in slow text, could wait for that
            winactivate
            sleep 500
            ControlClick, Button1  ; accept
            ;send {Tab}{Tab}{Space} ; accept
            sleep 500
            send {Enter}
            winwaitclose, LEGO, License
        }
        winwait, LEGO, continue
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button2
            sleep 1000
        }
        winwaitclose, LEGO
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Disney Interactive Studios\\LEGO Pirates DEMO" LEGOPiratesDEMO.exe
}

#----------------------------------------------------------------

w_metadata lhp_demo games \
    title="LEGO Harry Potter Demo [Years 1-4]" \
    publisher="Travellers Tales / WB" \
    year="2010" \
    media="download" \
    file1="LEGOHarryPotterDEMO.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/WB Games/LEGO_Harry_Potter_DEMO/LEGOHarryPotterDEMO.exe"

load_lhp_demo()
{
    case "$LANG" in
    *UTF-8*|*utf8*) ;;
    *)
        w_warn "This installer fails in non-utf-8 locales.  Doing 'export LANG=en_US.UTF-8'."
        LANG=en_US.UTF-8
        export LANG
        ;;
    esac

    w_download "http://static.kidswb.com/legoharrypottergame/LEGOHarryPotterDEMO.exe" bb0a30ad9a7cc51c80e1bb1f3eec22e6ccc1a706

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, LEGOHarryPotterDEMO.exe
        winwait, LEGO, language
        if ( w_opt_unattended > 0 ) {
            controlclick, Button1
            winwait, LEGO, License
            controlclick, Button1
            controlclick, Button2
            winwait, LEGO, installation method
            controlclick, Button2
        }
        winwait, LEGO, Finish
        if ( w_opt_unattended > 0 )
            controlclick, Button1

        winwaitclose, LEGO, Finish
    "

    if w_workaround_wine_bug 23397
    then
        w_warn "If sound stutters, try switching to OSS sound in winecfg (winetricks sound=oss)"
    fi

    # Work around locale issues by symlinking the app's directory to not have a funny char
    # Won't really work on cygwin, but that's ok.
    cd "$W_PROGRAMS_X86_UNIX/WB Games"
    ln -s LEGO*Harry\ Potter*DEMO LEGO_Harry_Potter_DEMO

    w_declare_exe "$W_PROGRAMS_X86_WIN\\WB Games\\LEGO_Harry_Potter_DEMO" "LEGOHarryPotterDEMO.exe"
}

#----------------------------------------------------------------

w_metadata lswcs games \
    title="Lego Star Wars Complete Saga" \
    publisher="Lucasarts" \
    year="2009" \
    media="dvd" \
    file1="LEGOSAGA.iso" \
    installed_file1="$W_PROGRAMS_X86_WIN/LucasArts/LEGO Star Wars - The Complete Saga/LEGOStarWarsSaga.exe"

load_lswcs()
{
    w_mount LEGOSAGA
    w_ahk_do "
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        SetTitleMatchMode, 2
        winwait, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, LEGO, License Agreement
            send a{Enter}
        }
        winwait, LEGO, method
        if ( w_opt_unattended > 0 ) {
            ControlClick Easy Installation
            sleep 1000
        }
        winwaitclose, LEGO
    "
    # Installer crashes at end (http://bugs.winehq.org/show_bug.cgi?id=22529) but this doesn't seem to hurt.
    # Wait for all processes to exit, else unmount will fail
    #$W_WINESERVER -w

    w_declare_exe "$W_PROGRAMS_X86_WIN\\LucasArts\\LEGO Star Wars - The Complete Saga" "LEGOStarWarsSaga.exe"

    w_warn "This game is copy-protected, and requires the real disc in a real drive to run."
}

#----------------------------------------------------------------

w_metadata lemonysnicket games \
    title="Lemony Snicket: A Series of Unfortunate Events" \
    publisher="Activision" \
    year="2004" \
    media="cd" \
    file1="Lemony Snicket.iso"

load_lemonysnicket()
{
    w_mount "Lemony Snicket"
    w_ahk_do "
        SetTitleMatchMode, 2
        Run, ${W_ISO_MOUNT_LETTER}:setup.exe
        WinWait, Lemony, Welcome
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick, Button1 ; Next
            WinWait, Lemony, License
            sleep 1000
            ControlClick, Button2 ; Accept
            WinWait, Lemony, Minimum System
            sleep 1000
            ControlClick, Button2 ; Yes
            WinWait, Lemony, Destination
            sleep 1000
            ControlClick, Button1 ; Next
            WinWait, Lemony, Select Program Folder
            sleep 1000
            ControlClick, Button2 ; Next
            WinWait, Lemony, Start Copying
            sleep 1000
            ControlClick, Button1 ; Next
            WinWait, Question, Would you like to add a desktop shortcut
            sleep 1000
            ControlClick, Button2 ; No
            WinWait, Question, Would you like to register
            sleep 1000
            ControlClick, Button2 ; No
            ;WinWait, Information, Please register
            ;sleep 1000
            ;ControlClick, Button1 ; OK
            WinWait, Lemony, Complete
            sleep 1000
            ControlClick, Button4 ; Finish
            WinWait, Lemony, Play
            sleep 1000
            ControlClick, Button6 ; Exit
            WinWait, Lemony, Are you sure
            sleep 1000
            ControlClick, Button1 ; Yes already
        }
        WinWaitClose, Lemony
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Activision\\Lemony Snicket's A Series of Unfortunate Events" System\\game.exe
}

#----------------------------------------------------------------

w_metadata luxor_ar games \
    title="Luxor Amun Rising" \
    publisher="MumboJumbo" \
    year="2006" \
    media="cd" \
    file1="LUXOR_AMUNRISING.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/MumboJumbo/Luxor Amun Rising/Luxor AR.exe"

load_luxor_ar()
{
    w_mount LUXOR_AMUNRISING

    w_ahk_do "
        SetWinDelay, 500
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:Luxor_AR_Setup.exe
        winwait, Luxor
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button2   ; Agree
            winwait, Folder
            ControlClick, Button2   ; Install
            winwait, Completed
            ControlClick, Button2   ; Next
        }
        winwait, Success
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button6   ; Uncheck Play
            ControlClick, Button2   ; Close
        }
        winwaitclose
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\MumboJumbo\\Luxor Amun Rising" "Luxor AR.exe"
}

#----------------------------------------------------------------

w_metadata masseffect2 games \
    title="Mass Effect 2 (drm broken on wine)" \
    publisher="BioWare" \
    year="2010" \
    media="dvd" \
    file1="MassEffect2.iso" \
    file2="ME2_Disc2.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Mass Effect 2/Binaries/MassEffect2.exe" \
    wine_showstoppers="23184"

load_masseffect2()
{
    w_mount MassEffect2
    w_read_key

    if w_workaround_wine_bug 22091 "May hang or crash at end of install, but should install ok."
    then
        w_call nocrashdialog
    fi

    if w_workaround_wine_bug 23126 "Installing C runtime library" 1.3.0,
    then
        w_call vcrun2005
    fi
    if w_workaround_wine_bug 23125 "Installing d3dx10 libraries" 1.3.0,
    then
        w_call d3dx10
    fi
    # FIXME: only do this for nvidia cards
    if w_workaround_wine_bug 23151 "Disabling glsl"
    then
        w_call glsl=disabled
    fi
    if w_workaround_wine_bug 22919 "Installing physx"
    then
        w_call physx
    fi

    w_ahk_do "
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:Setup.exe
        winwait, Installer Language
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, Mass Effect
            send {Enter}
            winwait, Mass Effect, License
            ControlClick, Button4
            ControlClick, Button2
            winwait, Mass Effect, Registration Code
            send $W_KEY
            ControlClick, Button2
            winwait, Mass Effect, Install Type
            ControlClick, Button2
        }
        winwait, Insert Disc
    "
    sleep 5
    w_mount ME2_Disc2
    w_ahk_do "
        SetTitleMatchMode, 2
        if ( w_opt_unattended > 0 ) {
            winwait, Insert Disc
            ControlClick, Button4
            ; on windows, the first click doesn't seem to do it, so press enter, too
            sleep 1000
            send {Enter}
        }
        ; Some installs may not get to this point due to an installer hang/crash (bug 22919)
        ; The hang/crash happens after the Physx install but does not seem to affect gameplay
        loop
        {
            ifwinexist, Mass Effect, Finish
            {
                if ( w_opt_unattended > 0 ) {
                    winkill, Mass Effect
                }
                break
            }
            Process, exist, Installer.exe
            me2pid = %ErrorLevel%
            if me2pid = 0
                break
            sleep 1000
        }
    "
    w_workaround_wine_bug 6971 "Please upgrade to wine-1.3.23 or later; see http://wiki.winehq.org/Bug6971" 1.3.23,

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Mass Effect 2\\Binaries" "MassEffect2.EXE"
}

#----------------------------------------------------------------

w_metadata masseffect2_demo games \
    title="Mass Effect 2" \
    publisher="BioWare" \
    year="2010" \
    media="download" \
    file1="MassEffect2DemoEN.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Mass Effect 2 Demo/Binaries/MassEffect2.exe"

load_masseffect2_demo()
{
    w_download http://static.cdn.ea.com/bioware/u/f/eagames/bioware/masseffect2/ME2_DEMO/MassEffect2DemoEN.exe cda9a25387a98e29772b3ccdcf609f87188285e2

    if w_workaround_wine_bug 22091 "May hang or crash at end of install, but should install ok."
    then
        w_call nocrashdialog
    fi

    if w_workaround_wine_bug 23126 "Installing C runtime library" 1.3.0,
    then
        w_call vcrun2005
    fi
    if w_workaround_wine_bug 23125 "Installing d3dx10 libraries" 1.3.0,
    then
        w_call d3dx10
    fi
    # FIXME: only do this for nvidia cards
    if w_workaround_wine_bug 23151 "Disabling glsl"
    then
        w_call glsl=disabled
    fi
    if w_workaround_wine_bug 22919 "Installing physx"
    then
        w_call physx
    fi

    # Don't let self-extractor write into $W_CACHE
    case "$OS" in
        "Windows_NT")
            cp "$W_CACHE/$W_PACKAGE/MassEffect2DemoEN.exe" "$W_TMP"
            chmod +x "$W_TMP"/MassEffect2DemoEN.exe ;;
        *)
            ln -sf "$W_CACHE/$W_PACKAGE/MassEffect2DemoEN.exe" "$W_TMP" ;;
    esac
    cd "$W_TMP"
    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        run, MassEffect2DemoEN.exe
        winwait, Mass Effect 2 Demo
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            winwait, Mass Effect 2 Demo, conflicts
            send {Enter}
            winwait, Mass Effect, License
            ControlClick, Button4
            ;ControlClick, Button2
            send {Enter}
            winwait, Mass Effect, Install Type
            ControlClick, Button2
        }
        ; Some installs may not get to this point due to an installer hang/crash (bug 22919)
        ; The hang/crash happens after the Physx install but does not seem to affect gameplay
        loop
        {
            ifwinexist, Mass Effect, Finish
            {
                if ( w_opt_unattended > 0 ) {
                    winkill, Mass Effect
                }
                break
            }
            Process, exist, Installer.exe
            me2pid = %ErrorLevel%
            if me2pid = 0
                break
            sleep 1000
        }
    "
    if test `which wine-hotfix-6971` 2> /dev/null
    then
        if w_workaround_wine_bug 6971 "Pointing menu and icon at wine-hotfix-6971 so mouse will work, assuming your X supports XInput2"
        then
            w_declare_exe "$W_PROGRAMS_X86_WIN\\Mass Effect 2 Demo\\Binaries" "MassEffect2.EXE"
            myexec="Exec=env WINEPREFIX=\"$HOME/.local/share/wineprefixes/masseffect2_demo\" wine-hotfix-6971 cmd /c 'C:\\\\\\Run-masseffect2_demo.bat'"

            mymenu="$HOME/Desktop/Mass Effect 2 Demo.desktop"
            me2tries=0
            while test ! -f "$mymenu"
            do
                if test $me2tries -gt 120
                then
                    w_die "timeout waiting for winemenubuilder to finish :-("
                fi
                me2tries=`expr $me2tries + 1`
                echo "waiting for winemenubuilder to finish..."
                sleep 1
            done
            unset me2tries
            if test -f "$mymenu"
            then
                # this is a hack, hopefully the wine bug will be fixed soon
                sed -i "s,Exec=.*,$myexec," "$mymenu"
            fi
            mymenu="$HOME/.local/share/applications/wine/Programs/Mass Effect 2 Demo/Mass Effect 2 Demo.desktop"
            if test -f "$mymenu"
            then
                # this is a hack, hopefully the wine bug will be fixed soon
                sed -i "s,Exec=.*,$myexec," "$mymenu"
            fi
        fi
    else
        w_workaround_wine_bug 6971 "Please upgrade to wine-1.3.23 or later; see http://wiki.winehq.org/Bug6971" 1.3.23,
    fi

}

#----------------------------------------------------------------

w_metadata maxmagicmarker_demo games \
    title="Max & the Magic Marker Demo" \
    publisher="Press Play" \
    year="2010" \
    media="download" \
    file1="max_demo_pc.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/maxmagicmarker_demo/max and the magic markerdemo pc.exe"

load_maxmagicmarker_demo()
{
    w_download http://www.maxandthemagicmarker.com/maxdemo/max_demo_pc.zip 1a79c583ff40e7b2cf05d18a89a806fd6b88a5d1

    w_try mkdir "$W_PROGRAMS_X86_UNIX"/$W_PACKAGE
    cd "$W_PROGRAMS_X86_UNIX"/$W_PACKAGE
    w_try_unzip "$W_CACHE/$W_PACKAGE"/max_demo_pc.zip
    # Work around bug in game?!
    mv "max and the magic markerdemo pc" "max and the magic markerdemo pc"_Data

    w_declare_exe "$W_PROGRAMS_X86_WIN\\$W_PACKAGE" "max and the magic markerdemo pc.exe"
}

#----------------------------------------------------------------

w_metadata mdk games \
    title="MDK (3dfx)" \
    publisher="Playmates International" \
    year="1997" \
    media="cd" \
    file1="MDK.iso" \
    installed_exe1="C:/SHINY/MDK/MDK3DFX.EXE"

load_mdk()
{
    # Needed even on Windows, some people say.  Haven't tried the D3D version on win7 yet.
    w_call glidewrapper

    w_download http://www.falconfly.de/downloads/patch-mdk3dfx.zip edcff0160c62d23b00c55c0bdfa38a6e90d925b0

    w_mount MDK
    cd "$W_ISO_MOUNT_ROOT"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetTitleMatchMode, slow
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, MDK
        if ( w_opt_unattended > 0 ) {
            click, left, 80, 80   ; USA
            winwait, Welcome, purchasing MDK
            ControlClick, Button1    ; Next
            winwait, Select Target Platform
            ControlClick, Button6    ; Next
            winwait, Select Installation Options
            ControlClick, Button3    ; Large
            ControlClick, Button6    ; Next
            winwait, Destination
            ControlClick, Button1    ; Next
            winwait, Program Folder
            ControlClick, Button2    ; Next
            winwait, Start
            ControlClick, Button1    ; Next
            Loop {
                IfWinExist, Setup, ProgramFolder
                    send {Enter}
                IfWinExist, Setup Complete
                    break
                sleep 500
            }
        }
        WinWait, Setup Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button1  ; uncheck readme
            ControlClick, Button4  ; Finish
            WinWait, Question, DirectX
            ControlClick, Button2  ; No
            WinWait, Information, complete
            ControlClick, Button1  ; No
        }
        WinWaitClose
    "
    cd "$W_DRIVE_C/SHINY/MDK"
    w_try_unzip "$W_CACHE/$W_PACKAGE"/patch-mdk3dfx.zip

    w_declare_exe "C:\\SHINY\\MDK" "MDK3DFX.EXE"
    # TODO: wine fails to install menu items, add a workaround for that
}

#----------------------------------------------------------------

w_metadata menofwar games \
    title="Men of War" \
    publisher="Aspyr Media" \
    year="2009" \
    media="dvd" \
    file1="Men of War.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Aspyr/Men of War/mow.exe"

load_menofwar()
{
    w_mount "Men of War"

    cd "$W_ISO_MOUNT_ROOT"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetTitleMatchMode, slow
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, Select Setup Language, Select the language
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick, TNewButton1, Select Setup Language, Select the language
            winwait, Men of War
            sleep 1000
            ControlClick, TButton4, Men of War
            winwait, Setup - Men of War, ACCEPTANCE OF AGREEMENT
            sleep 1000
            ControlClick, TNewRadioButton1, Setup - Men of War, ACCEPTANCE OF AGREEMENT
            ControlClick, TNewButton1, Setup - Men of War, ACCEPTANCE OF AGREEMENT
        }
        winwait, Setup - Men of War, Setup has finished installing
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick, x242 y254
            ControlClick, x242 y278
            ControlClick, TNewButton1, Setup - Men of War, Setup has finished
        }
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Aspyr\\Men of War" "mow.exe"
}

#----------------------------------------------------------------

w_metadata mb_warband_demo games \
    title="Mount & Blade Warband Demo" \
    publisher="Taleworlds" \
    year="2010" \
    media="download" \
    file1="mb_warband_setup_1143.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Mount&Blade Warband/mb_warband.exe" \
    homepage="http://www.taleworlds.com"

load_mb_warband_demo()
{
    if w_workaround_wine_bug 23207 "" 1.3.23,
    then
        w_die "Please upgrade to wine-1.3.23 or later, built with gcc-4.4.5 or later, else game crashes on startup."
    fi
    w_workaround_wine_bug 6971 "Please upgrade to wine-1.3.23 or later; see http://wiki.winehq.org/Bug6971" 1.3.23,
    # Mouse still doesn't work quite right after picking menu, see bug 25705.

    w_download "http://download.taleworlds.com/mb_warband_setup_1143.exe" 94fb829068678e27bcd67d9e0fde7f08c51a23af 

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode 2
        run mb_warband_setup_1143.exe
        winwait Warband
        if ( w_opt_unattended > 0 ) {
            controlclick button2
            winwait Warband
            controlclick button2
            winwait Warband, Finish
            controlclick button4
            controlclick button2
        }
        winwaitclose Warband
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Mount&Blade Warband" "mb_warband.exe"
}

#----------------------------------------------------------------

w_metadata mise games \
    title="Monkey Island: Special Edition" \
    publisher="LucasArts" \
    year="2009" \
    media="dvd" \
    file1="SecretOfMonkeyIslandSE_ddsetup.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/LucasArts/The Secret of Monkey Island Special Edition/MISE.exe"

load_mise()
{
    w_download_manual "http://www.direct2drive.com/8241/product/Buy-The-Secret-of-Monkey-Island(R):-Special-Edition-Download" SecretOfMonkeyIslandSE_ddsetup.zip 2e32458698c9ec7ebce94ae5c57531a3fe1dbb9e

    if w_workaround_wine_bug 22161
    then
        # Doesn't crash, but you only get a black screen and a flood of d3dx fixme's without native d3dx9_36
        w_call d3dx9_36
    fi

    if w_workaround_wine_bug 24545
    then
        # Game wants to install directx, but we delete it. It really only needs xact for x3daudio?_?.dll
        w_call xact
    fi

    if w_workaround_wine_bug 24547
    then
        # It really does need vcrun2005, for msvp80.dll (and potentially one stub from msvcr80)
        w_call vcrun2005
    fi

    mkdir -p "$W_TMP/$W_PACKAGE"
    cd "$W_TMP/$W_PACKAGE"

    # Don't extract DirectX/dotnet35 installers, they just take up extra time and aren't needed. Luckily, MISE copes well and just skips them if they are missing:
    w_try unzip "$W_CACHE/$W_PACKAGE"/SecretOfMonkeyIslandSE_ddsetup.zip -x DirectX* dotnet*

    w_ahk_do "
        SetTitleMatchMode, 2
        run, setup.exe
        WinWait, The Secret of Monkey Island, This wizard will guide you
        sleep 1000
        ControlClick, Button2
        WinWait, The Secret of Monkey Island, License Agreement
        sleep 1000
        ControlSend, RichEdit20A1, {CTRL}{END}
        sleep 1000
        ControlClick, Button4
        sleep 1000
        ControlClick, Button2
        WinWait, The Secret of Monkey Island, Setup Type
        sleep 1000
        ControlClick, Button2
        WinWait, The Secret of Monkey Island, Click Finish
        sleep 1000
        ControlClick, Button2
        "

    # FIXME: This app has two different keys - you can use either one.  How do we handle that with w_read_key?
    if test -f "$W_CACHE"/$W_PACKAGE/activationcode.txt
    then
        MISE_KEY=`cat "$W_CACHE"/$W_PACKAGE/activationcode.txt`
        w_ahk_do "
            SetTitleMatchMode, 2
            run, $W_PROGRAMS_X86_WIN\\LucasArts\\The Secret of Monkey Island Special Edition\\MISE.exe
            winwait, Product Activation
            ControlClick, Edit1 ; Activation Code
            send $MISE_KEY
            ControlClick Button4 ; Activate Online
            winwait, Product Activation, SUCCESSFUL
            winClose
            sleep 1000
            Process, Close, MISE.exe
        "
    elif test -f "$W_CACHE"/$W_PACKAGE/unlockcode.txt
    then
        MISE_KEY=`cat "$W_CACHE"/$W_PACKAGE/unlockcode.txt`
        w_ahk_do "
            SetTitleMatchMode, 2
            run, $W_PROGRAMS_X86_WIN\\LucasArts\\The Secret of Monkey Island Special Edition\\MISE.exe
            winwait, Product Activation
            ControlClick, Edit3 ; Unlock Code
            send $MISE_KEY
            ControlClick Button6 ; Activate manual
            winClose
            sleep 1000
            Process, Close, MISE.exe
        "
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\LucasArts\\The Secret of Monkey Island Special Edition" "MISE.exe"
}

#----------------------------------------------------------------

w_metadata myth2_demo games \
    title="Myth II demo 1.7.2" \
    publisher="Project Magma" \
    year="2011" \
    media="download" \
    file1="Myth2_Demo_172.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Myth II Demo/Myth II Demo.exe" \
    homepage="http://projectmagma.net/"

load_myth2_demo()
{
    # Originally a 1998 game by Bungie; according to Wikipedia, they handed the
    # source code to Project Magma for further development.

    # 1 May 2011 1.7.2 sha1sum e0a8f707377e71314a471a09ad2a55179ea44588
    w_download http://tain.totalcodex.net/items/download/myth-ii-demo-windows \
        e0a8f707377e71314a471a09ad2a55179ea44588 $file1
    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run, $file1
        winwait, Setup, Welcome
        if ( w_opt_unattended > 0 ) {
            winactivate
            send {Enter} ; next
            winwait, Setup, Components
            send {Enter} ; next
            winwait, Setup, Location
            send {Enter} ; install
        }
        winwait, Setup, Complete
        if ( w_opt_unattended > 0 ) {
            controlclick, Button4   ; Don't run
            controlclick, Button2   ; Finish
        }
        winwaitclose
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Myth II Demo" "Myth II Demo.exe"
}

#----------------------------------------------------------------

w_metadata nfsshift_demo games \
    title="Need For Speed: SHIFT Demo" \
    publisher="EA" \
    year="2009" \
    media="download" \
    file1="NFSSHIFTPCDEMO.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/Need for Speed SHIFT Demo/shiftdemo.exe"

load_nfsshift_demo()
{
    #w_download http://cdn.needforspeed.com/data/downloads/shift/NFSSHIFTPCDEMO.exe 7b267654d08c54f15813f2917d9d74ec40905db7
    w_download http://www.legendaryreviews.com/download-center/demos/NFSSHIFTPCDEMO.exe 7b267654d08c54f15813f2917d9d74ec40905db7

    w_try cp "$W_CACHE/$W_PACKAGE/$file1" "$W_TMP"

    cd "$W_TMP"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetTitleMatchMode, slow
        run, $file1
        winwait, WinRAR
        if ( w_opt_unattended > 0 ) {
            ControlClick, Button2
            winwait, SHIFT, View the readme
            controlclick, Button1
            ; Not all systems need the Visual C++ runtime
            loop
            {
                ifwinexist, Visual C++
                {
                    controlclick, Button1
                    break
                }
                ifwinexist, Setup, SHIFT Demo License
                {
                    break
                }
                sleep 1000
            }
            winwait, Setup, SHIFT Demo License
            Sleep 1000
            send {Space}
            Sleep 1000
            send {Enter}
            winwait, Setup, DirectX
            Sleep 1000
            send {Space}
            Sleep 1000
            send {Enter}
            winwait, Setup, Destination
            Sleep 1000
            send {Enter}
            winwait, Setup, begin
            Sleep 1000
            controlclick, Button1
        }
        winwait, Setup, Finish
        if ( w_opt_unattended > 0 ) {
            Sleep 1000
            controlclick, Button5
            controlclick, Button1
        }
        winwaitclose, Setup, Finish
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\Need for Speed SHIFT Demo" "shiftdemo.exe"
}

#----------------------------------------------------------------

w_metadata nfsworld games \
    title="Need For Speed World" \
    publisher="EA" \
    year="2011" \
    media="download" \
    file1="setup_659.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/Need For Speed World/GameLauncher.exe"

load_nfsworld()
{
    w_workaround_wine_bug 27047 "Game fails with corrupt executable error in wine-1.3.19 and earlier" 1.3.20,

    # This changes frequently, I'm afraid
    # Be careful to update $file1 when you update the url
    w_download http://static.cdn.ea.com/blackbox/u/f/NFSWO/Launcher/weblaunch_1.8.40.659/akamai/setup_659.exe b1f10af09350e2b3f5ccbc679dbea628e9f432d0

    w_workaround_wine_bug 27048 "The patcher hangs a lot.  When it does, retry the patch (you may need to kill it first).  After five or ten tries, it should work."

    # FIXME: file bugs for these
    w_call ie7
    w_call dotnet20

    if test "$W_OPT_UNATTENDED" && w_workaround_wine_bug 25961
    then
        w_call vcrun2008
    fi

    if w_workaround_wine_bug 26915 "installing corefonts so help works"
    then
        w_call corefonts
    fi

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 500
        SetTitleMatchMode, 2
        run $file1
        winwait Setup - Need For Speed
        if ( w_opt_unattended > 0 ) {
            ControlClick TNewButton1        ; Next
            winwait Setup - Need For Speed, License
            ControlClick TNewRadioButton1   ; Accept
            sleep 1000
            ControlClick TNewButton2        ; Next
            winwait Setup - Need For Speed, be installed
            ControlClick TNewButton3        ; Next
            winwait Setup - Need For Speed, be downloaded
            ControlClick TNewButton4        ; Next
            winwait Setup - Need For Speed, shortcuts
            ControlClick TNewButton5        ; Next
            winwait Setup - Need For Speed, Tasks
            ControlClick TNewButton5        ; Next
            winwait Setup - Need For Speed, Ready to Install
            ControlClick TNewButton5        ; Next
        }
        winwait Setup - Need For Speed, Completing
        if ( w_opt_unattended > 0 ) {
            send {Space}                    ; uncheck readme
            send {Tab}
            send {Space}                    ; uncheck launch
            sleep 1000                      ; let launch uncheck take effect?
            ControlClick TNewButton5        ; Finish
        }
        winwaitclose
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\Need For Speed World" GameLauncher.exe
}

#----------------------------------------------------------------

w_metadata nfsworld_mono games \
    title="Need For Speed World (using Mono)" \
    publisher="EA" \
    year="2011" \
    media="download" \
    file1="setup_659.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/Need For Speed World/GameLauncher.exe"

load_nfsworld_mono()
{
    w_download http://static.cdn.ea.com/blackbox/u/f/NFSWO/Launcher/weblaunch_1.8.40.659/akamai/setup_659.exe b1f10af09350e2b3f5ccbc679dbea628e9f432d0

    if w_workaround_wine_bug 25658 "Installing Mono 2.6"
    then
        # newer mono fails?
        w_call mono26
        # Work around bug fixed in later versions of mono (thanks, Vincent)
        w_download http://madewokherd.nfshost.com/omgsecret/mono-winebug23458.tar.gz \
             156a7d79e70864b67af22315ae257dc798cb2a2e
        w_try tar -C "$W_PROGRAMS_X86_UNIX/Mono-2.6.7/lib" -xvf "$W_CACHE/$W_PACKAGE"/mono-winebug23458.tar.gz
    fi

    if test "$W_OPT_UNATTENDED" && w_workaround_wine_bug 25961
    then
        w_call vcrun2008
    fi

    if w_workaround_wine_bug 26915 "installing corefonts so help works"
    then
        w_call corefonts
    fi

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 500
        SetTitleMatchMode, 2
        run $file1
        winwait Setup - Need For Speed
        if ( w_opt_unattended > 0 ) {
            ControlClick TNewButton1        ; Next
            winwait Setup - Need For Speed, License
            ControlClick TNewRadioButton1   ; Accept
            sleep 1000
            ControlClick TNewButton2        ; Next
            winwait Setup - Need For Speed, be installed
            ControlClick TNewButton3        ; Next
            winwait Setup - Need For Speed, be downloaded
            ControlClick TNewButton4        ; Next
            winwait Setup - Need For Speed, shortcuts
            ControlClick TNewButton5        ; Next
            winwait Setup - Need For Speed, Tasks
            ControlClick TNewButton5        ; Next
            winwait Setup - Need For Speed, Ready to Install
            ControlClick TNewButton5        ; Next
            ;winwait Setup, do not have Microsoft .NET 2.0   ; only on old wine
            ;send {Enter}
        }
        winwait Setup - Need For Speed, Completing
        if ( w_opt_unattended > 0 ) {
            send {Space}                    ; uncheck readme
            send {Tab}
            send {Space}                    ; uncheck launch (Vincent says let it launch?)
            sleep 1000                      ; let launch uncheck take effect?
            ControlClick TNewButton5        ; Finish
        }
        winwaitclose
    "

    # Work around winebrowser snafu mentioned in http://bugs.winehq.org/show_bug.cgi?id=13891
    # else you'll quickly get a dialog saying the app is broken
    # FIXME: file a bug for this
    if w_workaround_wine_bug 0000 "Kludging registry entry for winebrowser so patcher starts"
    then
        $WINE reg add "HKCR\\http\\shell\\open\\command" /ve /d "C:\\windows\\system32\\winebrowser.exe -nohome \"%1\"" /f
    fi

    # Create custom start batch file
    # FIXME: Before wine-1.3.22, del /s will crash, see http://bugs.winehq.org/show_bug.cgi?id=26885
    cat > "$W_DRIVE_C/run-$W_PACKAGE.bat" <<__EOF__
c:

rem Work around mono bug mentioned by Vincent
cd "c:\\users\\%USERNAME%\\Local Settings\\Application Data"
if exist "Electronic Arts Inc" del /s "Electronic Arts Inc\\user.config"

echo Warning, do not move window, Vincent says it will break keyboard input
cd "C:\\Program Files\\Electronic Arts\\Need For Speed World"
GameLauncher.exe
__EOF__

}

#----------------------------------------------------------------

w_metadata njcwp_trial apps \
    title="NJStar Chinese Word Processor trial" \
    publisher="NJStar" \
    year="2009" \
    media="download" \
    file1="njcwp.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/NJStar Chinese WP/njstar.exe" \
    homepage="http://www.njstar.com/cms/njstar-chinese-word-processor"

load_njcwp_trial()
{
    w_download http://www.njstar.com/download/njcwp.exe 006da155bad1ac4a73b953c98cb821eb7fd96507
    cd "$W_CACHE/$W_PACKAGE"
    if test "$W_OPT_UNATTENDED"
    then
        w_ahk_do "
        SetTitleMatchMode, 2
        run $file1
        WinWait, Setup, Wizard
        ControlClick Button2 ; next
        WinWait, Setup, License
        ControlClick Button2 ; agree
        WinWait, Setup, Install
        ControlClick Button2 ; install
        WinWait, Setup, Completing
        ControlClick Button4 ; do not launch
        ControlClick Button2 ; finish
        WinWaitClose
        "
    else
        w_try $WINE $file1
    fi
    w_declare_exe "$W_PROGRAMS_X86_WIN\\NJStar Chinese WP" "njstar.exe"
}

#----------------------------------------------------------------

w_metadata njjwp_trial apps \
    title="NJStar Japanese Word Processor trial" \
    publisher="NJStar" \
    year="2009" \
    media="download" \
    file1="njjwp.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/NJStar Japanese WP/njstarj.exe" \
    homepage="http://www.njstar.com/cms/njstar-japanese-word-processor"

load_njjwp_trial()
{
    w_download http://www.njstar.com/download/njjwp.exe 363d22e4ca7b79d0290a8ccdb0fa99169971d418
    cd "$W_CACHE/$W_PACKAGE"
    if test "$W_OPT_UNATTENDED"
    then
        w_ahk_do "
        SetTitleMatchMode, 2
        run $file1
        WinWait, Setup, Wizard
        ControlClick Button2 ; next
        WinWait, Setup, License
        ControlClick Button2 ; agree
        WinWait, Setup, Install
        ControlClick Button2 ; install
        WinWait, Setup, Completing
        ControlClick Button4 ; do not launch
        ControlClick Button2 ; finish
        WinWaitClose
        "
    else
        w_try $WINE $file1
    fi
    w_declare_exe "$W_PROGRAMS_X86_WIN\\NJStar Japanese WP" "njstarj.exe"
}

#----------------------------------------------------------------

w_metadata oblivion games \
    title="Elder Scrolls: Oblivion" \
    publisher="Bethesda Game Studios" \
    year="2006" \
    media="dvd" \
    file1="Oblivion.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Bethesda Softworks/Oblivion/Oblivion.exe"

load_oblivion()
{
    w_mount "Oblivion"

    cd "$W_ISO_MOUNT_ROOT"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, Setup.exe
        winwait, Oblivion, Welcome to the
        if ( w_opt_unattended > 0 ) {
            sleep 500
            controlclick, Button1
            winwait, Oblivion, License Agreement
            sleep 500
            controlclick, Button3
            sleep 500
            controlclick, Button1
            winwait, Oblivion, Choose Destination
            sleep 500
            controlclick, Button1
            winwait, Oblivion, Ready to Install
            sleep 500
            controlclick, Button1
            winwait, Oblivion, Complete
            sleep 500
            controlclick, Button1
            sleep 500
            controlclick, Button2
            sleep 500
            controlclick, Button3
        }
        winwaitclose, Oblivion, Complete
    "

    if w_workaround_wine_bug 20074 "Installing native d3dx9_36"
    then
        w_call d3dx9_36
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Bethesda Softworks\\Oblivion" "Oblivion.exe"
}

#----------------------------------------------------------------

w_metadata osmos_demo games \
    title="Osmos demo" \
    publisher="Hemisphere Games" \
    year="2009" \
    media="download" \
    file1="OsmosDemo_Installer_1.6.0.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/OsmosDemo/OsmosDemo.exe"

load_osmos_demo()
{
    w_download http://www.hemispheregames.com/blog/wp-content/uploads/2010/01/OsmosDemo_Installer_1.6.0.exe 4880eb20ff850bf337bbae20455ee90f614e507e

    cd "$W_CACHE/$W_PACKAGE"
    w_try $WINE $file1 ${W_OPT_UNATTENDED:+ /S}

    if w_workaround_wine_bug 24416 "installing C runtime library" 1.3.8,
    then
        w_call vcrun2005
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\OsmosDemo" "OsmosDemo.exe"
}

#----------------------------------------------------------------

w_metadata penpenxmas games \
    title="Pen-Pen Xmas Olympics" \
    publisher="Army of Trolls / Black Cat" \
    year="2007" \
    media="download" \
    file1="PenPenXmasOlympics100.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/PPO/PPO.exe"

load_penpenxmas()
{
    W_BROWSERAGENT=1 \
    w_download http://retrospec.sgn.net/download/files/PenPenXmasOlympics100.exe 36ec83cffa0ad3cc19dea33193b54bdaaea6db5b

    cd "$W_CACHE/$W_PACKAGE"
    $WINE PenPenXmasOlympics100.exe $W_UNATTENDED_SLASH_S
    w_declare_exe "$W_PROGRAMS_X86_WIN\\PPO" "PPO.exe"
}

#----------------------------------------------------------------

w_metadata plantsvszombies games \
    title="Plants vs. Zombies" \
    publisher="PopCap Games" \
    year="2009" \
    media="download" \
    file1="PlantsVsZombiesSetup.exe" \
    installed_file1="$W_PROGRAMS_X86_WIN/PopCap Games/Plants vs. Zombies/PlantsVsZombies.exe"

load_plantsvszombies()
{
    w_download "http://downloads.popcap.com/www/popcap_downloads/PlantsVsZombiesSetup.exe" c46979be135ef1c486144fa062466cdc51b740f5

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        run PlantsVsZombiesSetup.exe
        winwait, Plants vs. Zombies Installer
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            send {Enter}
            winwait, Plants vs. Zombies License Agreement
            ControlClick Button1
        }
        winwait, Plants vs. Zombies Installation Complete!
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            send {Space}{Enter}
            ControlClick, x309 y278, Plants vs. Zombies Installation Complete!,,,, Pos
        }
        WinWaitClose
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\PopCap Games\\Plants vs. Zombies" "PlantsVsZombies.exe"
}

#----------------------------------------------------------------

w_metadata popfs games \
    title="Prince of Persia The Forgotten Sands" \
    publisher="Ubisoft" \
    year="2010" \
    media="dvd" \
    file1="PoP_TFS.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Ubisoft/Prince of Persia The Forgotten Sands/Prince of Persia.exe"

load_popfs()
{
    w_mount PoP_TFS

    w_ahk_do "
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:Setup.exe
        winwait, Prince of Persia, Language
        if ( w_opt_unattended > 0 ) {
            sleep 500
            ControlClick, Button3
            winwait, Prince of Persia, Welcome
            sleep 500
            ControlClick, Button1
            winwait, Prince of Persia, License
            sleep 500
            ControlClick, Button5
            sleep 500
            ControlClick, Button2
            winwait, Prince of Persia, Click Install
            sleep 500
            ControlClick, Button1
            ; Avoid error when creating desktop shortcut
            Loop
            {
                IfWinActive, Prince of Persia, Click Finish
                    break
                IfWinExist, Prince of Persia, desktop shortcut
                {
                sleep 500
                    ControlClick, Button1, Prince of Persia, desktop shortcut
                    break
                }
                sleep 5000
            }
        }
        winwait, Prince of Persia, Click Finish
        if ( w_opt_unattended > 0 ) {
            sleep 500
            ControlClick, Button4
        }
    "

if w_workaround_wine_bug 24346
then
    w_call dsoundbug9612
fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Ubisoft\\Prince of Persia The Forgotten Sands" "Prince of Persia.exe"
}

#----------------------------------------------------------------

w_metadata puzzleagent_demo games \
    title="Puzzle Agent Demo" \
    publisher="Telltale Games" \
    year="2010" \
    media="download" \
    file1="PuzzleAgent_PC_Setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Telltale Games/Puzzle Agent/Puzzle Agent/Grickle101.exe"

load_puzzleagent_demo()
{
    w_download http://telltale.vo.llnwd.net/o15/games/puzzleagent/100/PuzzleAgent_PC_Setup.exe ac0012889fd80237928207c9d19b02f5968761a4

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        Run, PuzzleAgent_PC_Setup.exe
        SetTitleMatchMode, 2
        WinWait,Puzzle Agent Setup, Welcome
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button2 ; Next
            WinWait,Puzzle Agent Setup, properly
            Sleep 500
            ControlClick Button5 ;DirectX
            Sleep 500
            ControlClick Button2 ; Next
            WinWait,Puzzle Agent Setup, before
            Sleep 500
            ControlClick Button2 ; Agree
            WinWait,Puzzle Agent Setup, different
            Sleep 500
            ControlClick Button2 ; Install
            WinWait,Puzzle Agent Setup, your
            Sleep 500
            ControlClick Button4 ; Play
            Sleep 500
            ControlClick Button5 ; will
            Sleep 500
            ControlClick Button2 ; Finish
        }
        WinWaitClose, Puzzle Agent
    "

    if w_workaround_wine_bug 25210 ""  1.3.8,
    then
        w_call vcrun2008
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Telltale Games\\Puzzle Agent\\Puzzle Agent" "Grickle101.exe"
}

#----------------------------------------------------------------

w_metadata ragnarok games \
    title="Ragnarok" \
    publisher="GRAVITY" \
    year="2002" \
    media="manual_download" \
    file1="iRO-13.2.2-FullInstall-20110421-1717.msi" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Gravity/Ragnarok Online/Ragnarok.exe"

load_ragnarok()
{
    if w_workaround_wine_bug 657 "Visual C++ 6 runtime"
    then
        w_call vcrun6
    fi
    if w_workaround_wine_bug 28228 "Installing Visual C++ 2008 runtime"
    then
        w_call vcrun2008
    fi

    # publisher puts SHA1 checksums on download page, nice
    # BDA295E3A2A57CD02BD122ED7BF4836AC012369A
    w_download_manual http://www.playragnarok.com/downloads/clientdownload.aspx iRO-13.2.2-FullInstall-20110421-1717.msi bda295e3a2a57cd02bd122ed7bf4836ac012369a

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        Run, msiexec /i $file1
        SetTitleMatchMode, 2
        WinWait, Ragnarok Online Setup, Please read the Ragnarok Online License Agreement
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button1
            Sleep 500
            ControlClick Button3
            }
            WinWait, Ragnarok Online Setup, Completed the Ragnarok Online Setup Wizard
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button1 ;Direct
        }
    "

    # Game autoupdates:
    killall "Ragnarok.exe"
}

#----------------------------------------------------------------

w_metadata rct3deluxe games \
    title="RollerCoaster Tycoon 3 Deluxe (drm broken on wine)" \
    publisher="Atari" \
    year="2004" \
    media="cd" \
    file1="RCT3.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Atari/RollerCoaster Tycoon 3/RCT3.EXE"\
    wine_showstoppers="21448"

load_rct3deluxe()
{
    w_mount RCT3

    if w_workaround_wine_bug 26396
    then
        w_call quartz
    fi

    # FIXME: make videos and music work
    # Game still doesn't show .wmv logo videos nor play .wma background audio in menu
    # though it does in Jake's screencast.  Loading wmp9 and devenum gets it to 
    # try to load the .wmv logos, but it crashes in quartz :-(   
    # But at least it's playable without the logo videos and background.

    w_ahk_do "
        SetWinDelay 500
        SetTitleMatchMode, 2
        run ${W_ISO_MOUNT_LETTER}:setup-rtc3.exe
        if ( w_opt_unattended > 0 ) {
            WinWait, Select Setup Language
            controlclick, TButton1   ; accept
            WinWait Setup - RollerCoaster Tycoon 3, Welcome
            controlclick, TButton1   ; Next
            WinWait Setup - RollerCoaster Tycoon 3, License
            controlclick, TRadioButton1   ; Accept
            sleep 500
            controlclick, TButton2   ; Next
            WinWait Setup - RollerCoaster Tycoon 3, Destination
            controlclick, TButton3   ; Next
            WinWait Setup - RollerCoaster Tycoon 3, Start Menu
            controlclick, TButton4   ; Next
            WinWait Setup - RollerCoaster Tycoon 3, Additional
            controlclick, TButton4   ; Next
            WinWait Setup - RollerCoaster Tycoon 3, begin
            controlclick, TButton4   ; Install
            WinWait, Atari Product Registration
            controlclick, Button6   ; Close
            WinWait, Product Registration, skip
            controlclick, Button2   ; Yes, skip
        }
        WinWait Setup - RollerCoaster Tycoon 3, finished
        if ( w_opt_unattended > 0 ) {
            controlclick, TNewCheckListBox1   ; uncheck Launch
            controlclick, TButton4   ; Finish
        }
        WinWaitClose Setup - RollerCoaster Tycoon 3, finished
        "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Atari\\RollerCoaster Tycoon 3" RCT3.EXE
}

#----------------------------------------------------------------

w_metadata rayman2_demo games \
    title="Rayman 2 High Demo" \
    publisher="Ubisoft" \
    year="1999" \
    media="download" \
    file1="rayman2high.zip" \
    installed_exe1="c:/UbiSoft/Rayman2Demo/Rayman2Demo.exe"

load_rayman2_demo()
{
    w_download "ftp://ftp.ubisoft.com/Rayman2/rayman2high.zip" 14b2ad6f41e2e1358f3a4a5167d67a7111ea4fb5

    cd "$W_TMP"
    w_try unzip "$W_CACHE/$W_PACKAGE/rayman2high.zip"

    if w_workaround_wine_bug 16596
    then
        w_call vd=800x600
    fi

    if w_workaround_wine_bug 21159
    then
        w_call dinput
    fi

    w_ahk_do "
        SetWinDelay 500
        SetTitleMatchMode, 3
        Run, SETUP.EXE
        WinWaitActive, UBI Soft Installer - Language Choice
        if ( w_opt_unattended > 0 ) {
            ControlClick button1 ; OK
            WinWait, Ubi Soft Installer - Rayman 2 Demo
            ControlClick button1 ; Install
            WinWait, Ubi Soft Installer - Configuration choice
            ControlClick button1 ; Install
            WinWait, Ubi Soft Installer - Installation Directory
            ControlClick button1 ; OK
            WinWait, Ubi Soft Installer - Shortcut Choice
            ControlClick button1 ; OK
            WinWait, Ubi Soft Installer - Information file
            ControlClick button2 ; No
        }
        WinWait, Ubi Soft Installer - Rayman 2 Demo
        if ( w_opt_unattended > 0 ) {
            ControlClick button4 ; Quit
        }
        WinWaitClose
    "

    myexec="Exec=env WINEPREFIX=\"$HOME/.local/share/wineprefixes/rayman2_demo\" wine "'C:\\\\\\windows\\\\\\UbiSoft\\\\\\SetupUbi.exe -play Rayman2'
    mymenu="$HOME/Desktop/To Play Rayman 2 Demo.desktop"
    if test -f "$mymenu" && w_workaround_wine_bug 26303 "Fixing desktop entry"
    then
        # this is a hack, hopefully the wine bug will be fixed soon
        sed -i "s,Exec=.*,$myexec," "$mymenu"
    fi
    mymenu="$HOME/.local/share/applications/wine/Programs/Ubi Soft Games/Rayman 2 Demo/1 To Play Rayman 2 Demo.desktop"
    if test -f "$mymenu" && w_workaround_wine_bug 26304 "Fixing system menu"
    then
        # this is a hack, hopefully the wine bug will be fixed soon
        sed -i "s,Exec=.*,$myexec," "$mymenu"
    fi

    w_declare_exe "c:\\UbiSoft\\Rayman2Demo" "Rayman2Demo.exe"
}

#----------------------------------------------------------------

w_metadata riseofnations_demo games \
    title="Rise of Nations Trial" \
    publisher="Microsoft" \
    year="2003" \
    media="manual_download" \
    file1="RiseOfNationsTrial.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Games/Rise of Nations Trial/nations.exe"

load_riseofnations_demo()
{
    w_download_manual http://download.cnet.com/Rise-of-Nations-Trial-Version/3000-7562_4-10730812.html RiseOfNationsTrial.exe 33cbf1ebc0a93cb840f6296d8b529f6155db95ee

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        run RiseOfNationsTrial.exe
        WinWait,Rise Of Nations Trial Setup
        if ( w_opt_unattended > 0 ) {
            sleep 2500
            ControlClick CButtonClassName2
            WinWait,Rise Of Nations Trial Setup, installed
            sleep 2500
            ControlClick CButtonClassName7
        }
        WinWaitClose
    "

    if w_workaround_wine_bug 9027
    then
        w_call directmusic
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Games\\Rise of Nations Trial" "nations.exe"
}

#----------------------------------------------------------------

w_metadata secondlife games \
    title="Second Life Viewer" \
    publisher="Linden Labs" \
    year="2003-2011" \
    media="download" \
    file1="Second_Life_2-5-0-220251_Setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/SecondLifeViewer2/SecondLife.exe"

load_secondlife()
{
    w_download http://download.cloud.secondlife.com/Viewer-2-5/Second_Life_2-5-0-220251_Setup.exe 841b089eb8b7b782718538c697cba5fd714f5eac

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run, Second_Life_2-5-0-220251_Setup.exe
        if ( w_opt_unattended > 0 ) {
            winwait, Installer Language
            send {Enter}
            winwait, Installation Folder
            send {Enter}
        }
        winwait, Second Life, Start Second Life now
        if ( w_opt_unattended > 0 ) {
            send {Tab}{Enter}
        }
        winwaitclose
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\SecondLifeViewer2" "SecondLife.exe"
}

#----------------------------------------------------------------

w_metadata sims3 games \
    title="The Sims 3 (drm broken on wine)" \
    publisher="EA" \
    year="2009" \
    media="dvd" \
    file1="Sims3.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/The Sims 3/Game/Bin/TS3.exe" \
    wine_showstoppers="26273"

load_sims3()
{
    if w_workaround_wine_bug 22350 "Launcher needs .net"
    then
        w_call dotnet20
    fi

    if w_workaround_wine_bug 21517 "Old wine needs native DirectX for this game" 1.3.8,
    then
        w_call d3dx9_36
    fi

    w_read_key

    w_mount Sims3
    # Default lang, USA, accept defaults, uncheck EA dl mgr, uncheck readme
    w_ahk_do "
        run ${W_ISO_MOUNT_LETTER}:Sims3Setup.exe
        winwait, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            SetTitleMatchMode, 2
            winwait, - InstallShield Wizard
            sleep 1000
            ControlClick &Next >, - InstallShield Wizard
            sleep 1000
            send uuuuuu{Tab}{Tab}{Enter}
            sleep 1000
            send a{Enter}
            sleep 1000
            send {Raw}$W_KEY
            send {Enter}
            winwait, - InstallShield Wizard, Setup Type
            send {Enter}
            winwait, - InstallShield Wizard, Click Install to begin
            send {Enter}
            winwait, - InstallShield Wizard, EA Download Manager
            ControlClick Yes, - InstallShield Wizard
            send {Enter}
        }
        winwait, - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick View the readme file, - InstallShield Wizard
            ControlClick Finish, - InstallShield Wizard
        }
        winwaitclose
    "
    w_umount

    # DVD Region code is last digit.
    # FIXME: download appropriate one rather than just US version.
    w_download http://akamai.cdn.ea.com/eadownloads/u/f/sims/sims3/patches/TS3_1.19.44.010001_Update.exe 7d21a81aaea70bf102267456df4629ce68be0cc8

    cd "$W_CACHE"/$W_PACKAGE
    w_ahk_do "
        run TS3_1.19.44.010001_Update.exe
        SetTitleMatchMode, 2
        winwait, - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Finish, - InstallShield Wizard
        }
        winwaitclose
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\The Sims 3\\Game\\Bin" "TS3.exe"
}

#----------------------------------------------------------------

w_metadata simsmed games \
    title="The Sims Medieval (drm broken on wine)" \
    publisher="EA" \
    year="2011" \
    media="dvd" \
    file1="TSimsM.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/The Sims Medieval/Game/Bin/TSM.exe" \
    wine_showstoppers="26273"

load_simsmed()
{
    if w_workaround_wine_bug 21517 "Old wine needs native DirectX for this game" 1.3.8,
    then
        w_call d3dx9_36
    fi

    w_read_key

    w_mount TSimsM
    # Default lang, USA, accept defaults, uncheck EA dl mgr, uncheck readme
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 1000
        run ${W_ISO_MOUNT_LETTER}:SimsMedievalSetup.exe
        winwait, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            SetTitleMatchMode, 2
            winwait, - InstallShield Wizard
            ControlClick &Next >, - InstallShield Wizard
            sleep 1000
            send uuuuuu{Tab}{Tab}{Enter}
            WinWait, Sims, License
            ControlClick Button3   ; Accept
            sleep 1000
            ControlClick Button1   ; Next
            sleep 1000
            send {Raw}$W_KEY
            send {Enter}
            winwait, - InstallShield Wizard, Setup Type
            ControlClick &Complete    ; was not defaulting to complete?
            send {Enter}
            winwait, - InstallShield Wizard, Click Install to begin
            send {Enter}

            ; Handle optional dialogs
            ; In Wine-1.3.16 and lower, before 
            ; http://www.winehq.org/pipermail/wine-cvs/2011-March/076262.html,
            ; wine didn't claim to already have .net 4 installed,
            ; and ran into bug 25535.
            Loop 
            {
                ; .net 4 install sometimes fails nicely
                ifWinExist,, .NET Framework 4 has not been installed
                {
                    ControlClick Button3    ; Finish
                }
                ; .net 4 install sometimes explodes
                ifWinExist .NET Framework Initialization Error
                {
                    send {Enter}
                }
                ifWinExist, Sims, Customer Experience Improvement
                {
                    send {Enter}           ; Next
                }
                ifWinExist, - InstallShield Wizard, Complete
                    break
                sleep 1000
            }
        }
        winwait, - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1   ; Do not view readme
            send {Enter}           ; Finish
        }
        winwaitclose
    "

    # DVD Region code is last digit.
    # FIXME: download appropriate one rather than just US version.
    w_download http://akamai.cdn.ea.com/eadownloads/u/f/sims/sims/patches/TheSimsMedievalPatch_1.1.10.00001_Update.exe 7214ced8af7315741e05024faeacf9053b999b1b

    cd "$W_CACHE"/$W_PACKAGE
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run TheSimsMedievalPatch_1.1.10.00001_Update.exe
        winwait, Medieval, will reset any in-progress quests
        send {Enter}
        winwait, Medieval, Welcome
        if ( w_opt_unattended > 0 ) {
            send {Enter}
        }
        winwait, - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Finish, - InstallShield Wizard
        }
        winwaitclose
    "

    if w_workaround_wine_bug 25535 ".net 4 doesn't install on Wine, fixing menu to run game directly"
    then
        myexec="Exec=env WINEPREFIX=\"$HOME/.local/share/wineprefixes/$W_PACKAGE\" wine cmd /c 'C:\\\\\\Run-$W_PACKAGE.bat'"
        mymenu="$HOME/.local/share/applications/wine/Programs/Electronic Arts/The Sims Medieval/The Sims™ Medieval.desktop"
        if test -f "$mymenu"
        then
            sed -i "s,Exec=.*,$myexec," "$mymenu"
        fi
        mymenu="$HOME/Desktop/The Sims™ Medieval.desktop"
        if test -f "$mymenu"
        then
            sed -i "s,Exec=.*,$myexec," "$mymenu"
        fi
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\The Sims Medieval\\Game\\Bin" "TSM.exe"
}

#----------------------------------------------------------------

w_metadata sims3_gen games \
    title="The Sims 3: Generations (drm broken on Wine)" \
    publisher="EA" \
    year="2011" \
    media="dvd" \
    file1="Sims3EP04.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/The Sims 3 Generations/Game/Bin/TS3EP04.exe" \
    wine_showstoppers="26273"

load_sims3_gen()
{
    if [ ! -f "$W_PROGRAMS_X86_WIN/Electronic Arts/The Sims 3/Game/Bin/TS3.exe" ]
    then
        die "You must have sims3 installed to install sims3_gen!"
    fi

    w_read_key
    w_mount Sims3EP04
    
    # Default lang, USA, accept defaults, uncheck EA dl mgr, uncheck readme
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 1000
        run ${W_ISO_MOUNT_LETTER}:Sims3EP04Setup.exe
        winwait, - InstallShield Wizard
        if ( w_opt_unattended > 0 ) {
            send {Enter}
            loop
            {
                SetTitleMatchMode, 2
                ifwinexist, - InstallShield Wizard, Setup will now attempt to update
                {
                    ControlClick, Button1, - InstallShield Wizard
                    sleep 1000
                    winwait, - InstallShield Wizard, Setup has finished updating The Sims
                    sleep 1000
                    controlclick, Button1, - InstallShield Wizard
                    sleep 1000
                }
                ifwinexist, Sims, License
                {
                    winactivate, Sims, License
                    sleep 1000
                    ControlClick, Button3
                    sleep 1000
                    ControlClick, Button1
                    sleep 1000
                    break
                }
                sleep 1000
            }
            winwait, Sims, Please enter the entire Registration Code
            sleep 1000
            send {Raw}$W_KEY
            send {Enter}
            winwait, - InstallShield Wizard, Setup Type
            ControlClick &Complete    ; was not defaulting to complete?
            send {Enter}
            winwait, - InstallShield Wizard, Click Install to begin
            send {Enter}
            winwait, - InstallShield Wizard, Would you like to install the latest
            sleep 1000
            ControlClick, Button4 ; No thanks
            sleep 1000
            ControlClick, Button1
            sleep 1000
        }
        winwait, - InstallShield Wizard, Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1   ; Do not view readme
            send {Enter}           ; Finish
        }
        winwaitclose
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\The Sims 3 Generations/Game/Bin" "TS3EP04.exe"
}

#----------------------------------------------------------------

w_metadata splitsecond games \
    title="Split Second" \
    publisher="Disney" \
    year="2010" \
    media="dvd" \
    file1="SplitSecond.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Disney Interactive Studios/Split Second/SplitSecond.exe"

load_splitsecond()
{
    if w_workaround_wine_bug 22774 "" 1.3.0
    then
        w_warn "On wine, install takes an extra 7 minutes at the end, please be patient."
    fi

    if w_workaround_wine_bug 22865
    then
        w_warn "This game is currently unplayable on wine due to rendering problems; see winehq bug 22865."
    fi

    # Key is used in first run activation, no need to read it here.
    w_mount SplitSecond

    # Aborts with dialog about FirewallInstallHelper.dll if that's not on the path (e.g. in current dir)
    cd "$W_ISO_MOUNT_ROOT"
    w_ahk_do "
        SetTitleMatchMode, 2
        run setup.exe
        winwait, Split, Language
        sleep 500
        ControlClick, Next, Split, Language ; FIXME: Use button name
        winwait, Split, game installation
        sleep 500
        ControlClick, Button1, Split, game installation
        winwait, Split, license
        sleep 500
        ControlClick, Button5, Split, license
        sleep 500
        ControlClick, Button2, Split, license
        winwait, Split, DirectX
        sleep 500
        ControlClick, Button5, Split, DirectX
        sleep 500
        ControlClick, Button2, Split, DirectX
        winwait, Split, installation method
        sleep 500
        controlclick, Next, Split, installation method ; FIXME: Use button name
        winwait, DirectX needs to be updated
        sleep 500
        send {Enter}
        winwait, Split, begin
        sleep 500
        ControlClick, Button1
        winwait, Split, completed
        sleep 500
        ControlClick, Button1, Split
        sleep 500
        ControlClick, Button4, Split
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Disney Interactive Studios\\Split Second" "SplitSecond.exe"
}

#----------------------------------------------------------------

w_metadata splitsecond_demo games \
    title="Split Second Demo" \
    publisher="Disney" \
    year="2010" \
    media="manual_download" \
    file1="SplitSecondDemo_FilePlanet.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Disney Interactive Studios/Split Second/SplitSecondDEMO.exe"

load_splitsecond_demo()
{
    w_download_manual http://www.fileplanet.com/212404/210000/fileinfo/Split/Second-Demo SplitSecondDemo_FilePlanet.exe 72b070712cfe951297263fae143521b45dae16b4

    if w_workaround_wine_bug 22774 "" 1.3.0
    then
        w_warn "On wine, install takes an extra 7 minutes at the end, please be patient."
    fi

    if w_workaround_wine_bug 22865
    then
        w_warn "This game is currently unplayable on wine due to rendering problems; see winehq bug 22865."
    fi

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        run, SplitSecondDemo_FilePlanet.exe 
        winwait, Split, Language
        ;ControlClick, Next, Split, Language  ; does not quite work, have to use {Enter} instead
        Send {Enter}
        winwait, Split, game installation
        ControlClick, Button1, Split, game installation
        winwait, Split, license
        ControlClick, Button5, Split, license
        ControlClick, Button2, Split, license
        winwait, Split, DirectX
        ControlClick, Button5, Split, DirectX
        ControlClick, Button2, Split, DirectX
        winwait, Split, installation path
        ControlClick, Button1, Split, installation path
        winwait, Split, Game features
        ControlClick, Button2, Split, Game features
        winwait, Split, start copying
        ControlClick, Button1, Split, start copying
        winwait, Split, completed
        ControlClick, Button1, Split, completed
        ControlClick, Button4, Split, completed
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Disney Interactive Studios\\Split Second Demo" "SplitSecondDEMO.exe"
}

#----------------------------------------------------------------

w_metadata spore games \
    title="Spore" \
    publisher="EA" \
    year="2008" \
    media="dvd" \
    file1="SPORE.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/SPORE/Sporebin/SporeApp.exe"

load_spore()
{
    w_mount SPORE

    w_read_key

    w_ahk_do "
        SetTitleMatchMode, 2
        run, ${W_ISO_MOUNT_LETTER}:SPORESetup.exe
        winwait, Language
        if ( w_opt_unattended > 0 ) {
            sleep 500
            controlclick, Button1
            winwait, SPORE, Welcome
            sleep 500
            controlclick, Button1
            winwait, SPORE, License
            sleep 500
            controlclick, Button3
            sleep 500
            controlclick, Button1
            winwait, SPORE, Registration Code
            send {RAW}$W_KEY
            sleep 500
            controlclick, Button2
            winwait, SPORE, Setup Type
            sleep 500
            controlclick, Button6
            winwait, SPORE, Shortcut
            sleep 500
            controlclick, Button6
            winwait, SPORE, begin
            sleep 500
            controlclick, Button1
            winwait, Question
            ; download managers are usually a pain, so always say no to such questions
            sleep 500
            controlclick, Button2
        }
        winwait, SPORE, complete
        sleep 500
        if ( w_opt_unattended > 0 ) {
            controlclick, Button1
            sleep 500
            controlclick, Button2
            sleep 500
            controlclick, Button4
        }
        winwaitclose, SPORE, complete
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\SPORE\\Sporebin" "SporeApp.exe"
}

#----------------------------------------------------------------

w_metadata spore_cc_demo games \
    title="Spore Creature Creator trial" \
    publisher="EA" \
    year="2008" \
    media="download" \
    file1="792248d6ad421d577132c2b648bbed45_scc_trial_na.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Electronic Arts/SPORE/Sporebin/SporeCreatureCreator.exe"

load_spore_cc_demo()
{
    w_download http://na.llnet.cdn.ea.com/u/f/eagames/spore/scc/promo/792248d6ad421d577132c2b648bbed45_scc_trial_na.exe 06da5558e6ebbc39d2fac955eceab78cf8470e07

    w_info "The installer runs on for about a minute after it's done."

    cd "$W_CACHE/$W_PACKAGE"
    if test "$W_OPT_UNATTENDED"
    then
        w_ahk_do "
            SetWinDelay 1000
            SetTitleMatchMode, 2
            run $file1
            winwait, Wizard, Welcome to the SPORE
            send N
            winwait, Wizard, Please read the following
            send a
            send N
            winwait, Wizard, your setup
            send N
            winwait, Wizard, options below
            send N
            winwait, Wizard, We're ready
            ;send i       ; didn't take once?
            ControlClick, Button1
            winwait, Question, do not install the latest
            send N        ; reject EA Download Manager
            winwait, Wizard, Launch
            send {SPACE}{DOWN}{SPACE}{ENTER}
            winwaitclose
        "
        while ps | grep $file1 | grep -v grep > /dev/null
        do
            w_info "Waiting for installer to finish."
            sleep 2
        done
    else
        w_try "$WINE" "$file1"
    fi
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Electronic Arts\\SPORE\\Sporebin" \
        "SporeCreatureCreator.exe"
}

#----------------------------------------------------------------

w_metadata starcraft2_demo games \
    title="Starcraft II Demo" \
    publisher="Blizzard" \
    year="2010" \
    media="manual_download" \
    file1="SC2-WingsOfLiberty-enUS-Demo-Installer.zip" \
    installed_exe1="$W_PROGRAMS_X86_WIN/StarCraft II Demo/StarCraft II.exe"

load_starcraft2_demo()
{
    w_download_manual http://www.fileplanet.com/217982/210000/fileinfo/Starcraft-2-Demo SC2-WingsOfLiberty-enUS-Demo-Installer.zip 4c06ad755fbde73f135a7359bf6bfdbd2c6eb00e

    cd "$W_TMP"
    w_try_unzip "$W_CACHE/$W_PACKAGE"/SC2-WingsOfLiberty-enUS-Demo-Installer.zip

    w_ahk_do "
        SetTitleMatchMode, 2
        Run, Installer.exe
        WinWait, StarCraft II Installer
        if ( w_opt_unattended > 0 ) {
            sleep 500
            ControlClick, x300 y200
            winwait, End User License Agreement
            winactivate
            ;MouseMove, 300, 300
            ;Click WheelDown, 70
            Sleep, 1000
            ControlClick, Button2  ; Accept
            winwaitclose
            winwait, StarCraft II Installer
            sleep 1000
            ControlClick, x800 y500
            ; Is there any better wait to await completion?
            Loop {
                PixelGetColor, color, 473, 469   ; the 1 in 100%
                ; The digits are drawn white, but because the whole
                ; window is flickering, it cycles through about 20
                ; brightnesses.  Check a bunch of them to reduce
                ; chances of getting stuck for a long time.
                ifEqual, color, 0xffffff
                    break
                ifEqual, color, 0xf4f4f4
                    break
                ifEqual, color, 0xf1f1f1
                    break
                ifEqual, color, 0xf0f0f0
                    break
                ifEqual, color, 0xeeeeee
                    break
                ifEqual, color, 0xebebeb
                    break
                ifEqual, color, 0xe4e4e4
                    break
                sleep 500 ; changes rapidly, so sample often
            }
            ControlClick, x800 y500   ; Finish
            winwaitclose
            ; no way to tell game to not start?
            process, wait, SC2.exe
            sleep 2000
            process, close, SC2.exe
        }
        "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\StarCraft II Demo" "StarCraft II.exe"
}

#----------------------------------------------------------------

w_metadata theundergarden_demo games \
    title="The UnderGarden Demo" \
    publisher="Atari" \
    year="2010" \
    media="manual_download" \
    file1="TheUnderGarden_PC_B34_SRTB.30_28OCT10.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/The UnderGarden/TheUndergarden.exe"

load_theundergarden_demo()
{
    w_download_manual http://www.bigdownload.com/games/the-undergarden/pc/the-undergarden-demo TheUnderGarden_PC_B34_SRTB.30_28OCT10.exe acf90c422ac2f2f242100f39bedfe7df0c95f7a

    if w_workaround_wine_bug 25384
    then
        w_call vcrun2008
    fi
    if w_workaround_wine_bug 25385
    then
        w_call d3dx9_36
    fi

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        Run, TheUnderGarden_PC_B34_SRTB.30_28OCT10.exe
        WinWait,WinRAR
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick Button2 ; Install
            WinWait,Select Setup Language, during
            Sleep 500
            ControlClick TNewButton1 ;OK
            WinWait,Setup - The UnderGarden, your
            Sleep 500
            ControlClick TNewButton1 ;OK
            WinWait,Setup - The UnderGarden, License
            Sleep 500
            ControlClick TNewRadioButton1 ; accept
            Sleep 500
            ControlClick TNewButton2 ; Next
            WinWait,Setup - The UnderGarden, different
            Sleep 500
            ControlClick TNewButton3 ;Next
            WinWait,Setup - The UnderGarden, shortcuts
            Sleep 500
            ControlClick TNewButton4 ;OK
            WinWait,Setup - The UnderGarden, additional
            Sleep 500
            ControlFocus,TNewCheckListBox1,desktop
            Sleep 500
            Send {Space}
            Sleep 500
            ControlClick TNewButton4 ; Next
            WinWait,Setup - The UnderGarden, review
            Sleep 500
            ControlClick TNewButton4 ;Install
            WinWait,Microsoft Visual C, Visual
            Sleep 500
            ControlClick Button13 ;Cancel
            WinWait,Microsoft Visual C, want
            Sleep 500
            ControlClick Button1 ;Yes
            WinWait,Microsoft Visual C, chosen
            Sleep 500
            ControlClick Button2 ;Finish
            WinWait,Framework 3, Press
            Sleep 500
            ControlClick Button21 ;Cancel
            WinWait,Framework 3, want
            Sleep 500
            ControlClick Button1 ;Yes
            WinWait,Installing Microsoft, Runtime
            Sleep 500
            ControlClick Button6 ;Cancel
        }
        WinWait,Setup,launched
        if ( w_opt_unattended > 0 ) {
            Sleep 500
            ControlClick TNewButton4 ;Finish
        }
        WinWaitClose,Setup,launched
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\The UnderGarden" "TheUndergarden.exe"
}

#----------------------------------------------------------------

w_metadata tmnationsforever games \
    title="TrackMania Nations Forever" \
    publisher="Nadeo" \
    year="2009" \
    media="download" \
    file1="tmnationsforever_setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/TmNationsForever/TmForever.exe"

load_tmnationsforever()
{
    if w_workaround_wine_bug 20915
    then
        # FIXME: script this?
        w_warn "To fix choppy sound/low fps, try setting Settings/Advanced/Audio to portaudio when starting the game."
    fi

    # Before:      cab0cf66db0471bc2674a3b1aebc35de0bca6ed0
    # 29 Mar 2011: 23388798d5c90ad4a233b4cd7e9fcafd69756978
    w_download "http://files.trackmaniaforever.com/tmnationsforever_setup.exe" 23388798d5c90ad4a233b4cd7e9fcafd69756978

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, 2
        Run, tmnationsforever_setup.exe
        WinWait,Select Setup Language
        if ( w_opt_unattended > 0 ) {
            Sleep 1000
            ControlClick TNewButton1 ; OK
            WinWait,Setup - TmNationsForever,Welcome
            Sleep 1000
            ControlClick TNewButton1 ; Next
            WinWait,Setup - TmNationsForever,License
            Sleep 1000
            ControlClick TNewRadioButton1 ; Accept
            Sleep 1000
            ControlClick TNewButton2 ; Next
            WinWait,Setup - TmNationsForever,Where
            Sleep 1000
            ControlClick TNewButton3 ; Next
            WinWait,Setup - TmNationsForever,shortcuts
            Sleep 1000
            ControlClick TNewButton4 ; Next
            WinWait,Setup - TmNationsForever,perform
            Sleep 1000
            ControlClick TNewButton4 ; Next
            WinWait,Setup - TmNationsForever,installing
            Sleep 1000
            ControlClick TNewButton4 ; Install
        }
        WinWait,Setup - TmNationsForever,finished
        if ( w_opt_unattended > 0 ) {
            Sleep 1000
            ControlFocus, TNewCheckListBox1, TmNationsForever, finished
            Sleep 1000
            Send {Space} ; don't start game
            ControlClick TNewButton4 ; Finish
        }
        WinWaitClose
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\TmNationsForever" "TmForever.exe"
}

#----------------------------------------------------------------

w_metadata trainztcc_2004 games \
    title="Trainz: The Complete Collection: TRS2004" \
    publisher="Paradox Interactive" \
    year="2008" \
    media="dvd" \
    file1="TRS2006DVD.iso" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Auran/TRS2004/TRS2004.exe"

load_trainztcc_2004()
{
    w_call mfc42

    w_read_key
    # yup, they got the volume name wrong
    w_mount TRS2006DVD
    cd ${W_ISO_MOUNT_ROOT}/TRS2004_SP4_DVD_Installer_BUILD_2370/Installer/Disk1
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run setup.exe
        if ( w_opt_unattended > 0 ) {
            winwait TRS2004 Setup, Please install the latest drivers
            send {Enter}
            winwait TRS2004, Welcome
            send {Enter}
            winwait TRS2004, License
            ControlClick Button2
            winwait TRS2004, serial
            winactivate
            send ${W_RAW_KEY}{Enter}
            winwait TRS2004, Destination
            send {Enter}
            winwait Install DirectX
            send n
            winwait Windows Update, Your computer already
            send {Enter}
        }
        winwait TRS2004, Complete
        if ( w_opt_unattended > 0 ) {
            send {Space}     ; uncheck View Readme
            send {Enter}     ; Finish
        }
        winwaitclose
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Auran\\TRS2004" "TRS2004.exe"

    # And, while we're at it, also install the accompanying paint shed app
    cd ${W_ISO_MOUNT_ROOT}/TRAINZ_PAINTSHED
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run Trainz_Paint_Shed_Setup.exe
        if ( w_opt_unattended > 0 ) {
            winwait Trainz Paint Shed, Welcome
            send {Enter}
            winwait Trainz Paint Shed, License
            send a           ; accept
            send {Enter}     ; Next
            winwait Trainz Paint Shed, Destination
            send {Enter}
            winwait Trainz Paint Shed, Install
            send {Enter}
        }
        winwait Trainz Paint Shed, Complete
        if ( w_opt_unattended > 0 ) {
            send {Enter}     ; Finish
        }
        winwaitclose
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Auran\\Trainz Paint Shed" "Trainz Paint Shed.exe" paintshed
}

#----------------------------------------------------------------

w_metadata sammax301_demo games \
    title="Sam & Max 301: The Penal Zone" \
    publisher="Telltale Games" \
    year="2010" \
    media="manual_download" \
    file1="SamMax301_PC_Setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Telltale Games/Sam and Max - The Devil's Playhouse/The Penal Zone/SamMax301.exe"

load_sammax301_demo()
{
    w_download_manual "http://www.fileplanet.com/211314/210000/fileinfo/Sam-&-Max:-Devil's-Playhouse---Episode-One-Demo" SamMax301_PC_Setup.exe 83f47b7f3a5074a6e29bdc9b4f1fd2c4471d9641

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        SetWinDelay 500
        run SamMax301_PC_Setup.exe
        winwait Sam and Max The Penal Zone Setup, Welcome
        if ( w_opt_unattended > 0 ) {
            controlclick button2 ; Next
            winwait Sam and Max The Penal Zone Setup, DirectX
            controlclick button5 ; Uncheck check directx
            controlclick button2 ; Next
            winwait Sam and Max The Penal Zone Setup, License
            controlclick button2 ; I Agree
            winwait Sam and Max The Penal Zone Setup, Location
            controlclick button2 ; Install
            winwait Sam and Max The Penal Zone Setup, Finish
            controlclick button4 ; Uncheck play now 
            controlclick button5 ; Uncheck create shortcut
            controlclick button2 ; Finish
        }
        winwaitclose Sam and Max The Penal Zone Setup
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Telltale Games\\Sam and Max - The Devil's Playhouse\\The Penal Zone" "SamMax301.exe"
}

#----------------------------------------------------------------

w_metadata sammax304_demo games \
    title="Sam & Max 304: Beyond the Alley of the Dolls" \
    publisher="Telltale Games" \
    year="2010" \
    media="manual_download" \
    file1="SamMax304_PC_setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Telltale Games/Sam and Max - The Devil's Playhouse/Beyond the Alley of the Dolls/SamMax304.exe"

load_sammax304_demo()
{
    w_download_manual "http://www.fileplanet.com/214770/210000/fileinfo/Sam-&-Max:-The-Devi's-Playhouse---Beyond-the-Alley-of-the-Dolls-Demo" SamMax304_PC_setup.exe 1a385a1f1e83770c973e6457b923b7a44bbe44d8

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetTitleMatchMode, 2
        Run, $file1
        WinWait,Sam and Max Beyond the Alley of the Dolls Setup
        if ( w_opt_unattended > 0 ) {
            ControlClick Button2 ; Next
            WinWait,Sam and Max Beyond the Alley of the Dolls Setup,DirectX
            ControlClick Button2 ; Next - Directx check defaulted
            WinWait,Sam and Max Beyond the Alley of the Dolls Setup,License
            ControlClick Button2 ; Agree
            WinWait,Sam and Max Beyond the Alley of the Dolls Setup,Location
            ControlClick Button2 ; Install
            WinWait,Sam and Max Beyond the Alley of the Dolls Setup,Finish
            ControlClick Button4 ; Uncheck Play Now
            ControlClick Button2 ; Finish
        }
        WinWaitClose
    "

    if w_workaround_wine_bug 24250 "Installing visual C++ runtimes" 1.3.15,
    then
        w_call vcrun2005
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Telltale Games\\Sam and Max - The Devil's Playhouse\\Beyond the Alley of the Dolls" "SamMax304.exe"
}

#----------------------------------------------------------------

w_metadata tropico3_demo games \
    title="Tropico 3 Demo" \
    publisher="Kalypso Media GmbH" \
    year="2009" \
    media="manual_download" \
    file1="Tropico3Demo.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Kalypso/Tropico 3 Demo/Tropico3 Demo.exe"

load_tropico3_demo()
{
    w_download_manual "http://www.tropico3.com/?p=downloads" Tropico3Demo.exe e031749db346ac3a87a675787c81eb1ca8cb5909

    if w_workaround_wine_bug 24819 "Disabling gameux"
    then
        w_override_dlls disabled gameux
    fi

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetWinDelay 1000
        SetTitleMatchMode, 2
        Run, Tropico3Demo.exe
        WinWait,Installer
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1 ; OK
            WinWait,Tropico,Welcome
            ControlClick Button2 ; Next
            WinWait,Tropico,License
            ControlClick Button2 ; Agree
            WinWait,Tropico,Typical
            ControlClick Button2 ; Next
        }
        WinWait,Tropico,Completing
        if ( w_opt_unattended > 0 ) {
            ControlClick Button4 ; Uncheck Run Now
            ControlClick Button2 ; Finish
        }
        WinWaitClose
    "

    w_workaround_wine_bug 16328 "seawater is invisible in this wine, please update to 1.3.9 or later" 1.3.9,

    if w_workaround_wine_bug 24845 "disabling mmdevapi to fix sound" 1.3.21,
    then
        w_override_dlls disabled mmdevapi
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Kalypso\\Tropico 3 Demo" "Tropico3 Demo.exe"
}

#----------------------------------------------------------------

w_metadata singularity games \
    title="Singularity" \
    publisher="Activision" \
    year="2010" \
    media="dvd" \
    file1="SNG_DVD.iso"

load_singularity()
{
    w_read_key
    w_mount SNG_DVD

    w_ahk_do "
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        winwait, Activision(R) - InstallShield, Select the language for the installation from the choices below.
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button1, Activision(R) - InstallShield, Select the language for the installation from the choices below.
            sleep 1000
            winwait, Singularity(TM), Keycode Check
            sleep 1000
            Send $W_KEY
            sleep 1000
            Send {Enter}
            ; Well this is annoying...
            Winwait, Keycode Check, The Keycode you entered appears to be valid.
            sleep 1000
            Send {Enter}
            winwait, Singularity(TM), The InstallShield Wizard will install Singularity(TM) on your computer
            sleep 1000
            controlclick, Button1, Singularity(TM), The InstallShield Wizard will install Singularity(TM) on your computer
            winwait, Singularity(TM), Please read the following license agreement carefully
            sleep 1000
            controlclick, Button5, Singularity(TM), Please read the following license agreement carefully
            sleep 1000
            controlclick, Button2, Singularity(TM), Please read the following license agreement carefully
            winwait, Singularity(TM), Minimum System Requirements
            sleep 1000
            controlclick, Button1, Singularity(TM), Minimum System Requirements
            winwait, Singularity(TM), Select the setup type to install
            controlclick, Button4, Singularity(TM), Select the setup type to install
        }
        ; Loop until installer window has been gone for at least two seconds
        Loop
        {
            sleep 1000
            IfWinExist, Singularity
                continue
            IfWinExist, Activision
                continue
            sleep 1000
            IfWinExist, Singularity
                continue
            IfWinExist, Activision
                continue
            break
        }
        "

    if w_workaround_wine_bug 6971 "Setting mwo=force... please upgrade to wine-1.3.23" 1.3.23,
    then
        w_call mwo=force
    fi

    if w_workaround_wine_bug 22548
    then
        echo "Disabling \'depth of field\'"
        cat > "$W_TMP"/dof.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Activision\Singularity]
"DepthOfField"=dword:00000000

_EOF_
        w_try_regedit "$W_TMP_WIN"\\dof.reg
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Activision\\Singularity(TM)\\Binaries" "Singularity.exe"

    # Clean up crap left over in c:\ when the installer runs the vc 2008 redistributable installer
    cd "$W_DRIVE_C"
    rm -f VC_RED.* eula.*.txt globdata.ini install.exe install.ini install.res.*.dll vcredist.bmp
}

#----------------------------------------------------------------

w_metadata wglgears benchmarks \
    title="wglgears" \
    publisher="Clinton L. Jeffery" \
    year="2005" \
    media="download" \
    file1="wglgears.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/misc/wglgears.exe"

load_wglgears()
{
    w_download http://www2.cs.uidaho.edu/~jeffery/win32/wglgears.exe d65d2098bc11af76cb614946342913b1af62924d
    mkdir -p "$W_PROGRAMS_X86_UNIX/misc"
    cp "$W_CACHE"/wglgears/wglgears.exe "$W_PROGRAMS_X86_UNIX/misc"
    chmod +x "$W_PROGRAMS_X86_UNIX/misc/wglgears.exe"

    w_declare_exe "$W_PROGRAMS_X86_WIN\\misc" wglgears.exe
}

#----------------------------------------------------------------

w_metadata stalker_pripyat_bench benchmarks \
    title="S.T.A.L.K.E.R Call of Pripyat benchmark" \
    publisher="GSC Game World" \
    year="2009" \
    media="manual_download" \
    file1="stkcop-bench-setup.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Call Of Pripyat Benchmark/Benchmark.exe"

load_stalker_pripyat_bench()
{
    # Much faster
    w_download_manual http://www.bigdownload.com/games/stalker-call-of-pripyat/pc/stalker-call-of-pripyat-benchmark stkcop-bench-setup.exe 8691c3f289ecd0521bed60ffd46e65ad080206e0
    #w_download http://files.gsc-game.com/st/bench/stkcop-bench-setup.exe 8691c3f289ecd0521bed60ffd46e65ad080206e0

    cd "$W_CACHE/$W_PACKAGE"

    # FIXME: a bit fragile, if you're browsing the web while installing, it sometimes gets stuck.
    w_ahk_do "
        SetTitleMatchMode, 2
        run stkcop-bench-setup.exe
        WinWait,Setup - Call Of Pripyat Benchmark
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick TNewButton1 ; Next
            WinWait,Setup - Call Of Pripyat Benchmark,License
            sleep 1000
            ControlClick TNewRadioButton1 ; accept
            sleep 1000
            ControlClick TNewButton2 ; Next
            WinWait,Setup - Call Of Pripyat Benchmark,Destination
            sleep 1000
            ControlClick TNewButton3 ; Next
            WinWait,Setup - Call Of Pripyat Benchmark,shortcuts
            sleep 1000
            ControlClick TNewButton4 ; Next
            WinWait,Setup - Call Of Pripyat Benchmark,performed
            sleep 1000
            ControlClick TNewButton4 ; Next
            WinWait,Setup - Call Of Pripyat Benchmark,ready
            sleep 1000
            ControlClick, TNewButton4 ; Next  (nah, who reads doc?)
        }
        WinWait,Setup - Call Of Pripyat Benchmark,finished
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            Send {Space}  ; uncheck launch
            sleep 1000
            ControlClick TNewButton4 ; Finish
        }
        WinWaitClose,Setup - Call Of Pripyat Benchmark,finished
    "

    if w_workaround_wine_bug 24868
    then
        w_call d3dx9_31
        w_call d3dx9_42
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Call Of Pripyat Benchmark" "Benchmark.exe"
}

#----------------------------------------------------------------

w_metadata torchlight games \
    title="Torchlight - boxed version" \
    publisher="Runic Games" \
    year="2009" \
    media="dvd" \
    file1="Torchlight.iso"

load_torchlight()
{
    w_mount "Torchlight"
    w_ahk_do "
        SetTitleMatchMode, 2
        Run, ${W_ISO_MOUNT_LETTER}:Torchlight.exe
        WinWait, Torchlight Setup, This wizard will guide
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            ControlClick, Button2, Torchlight Setup, This wizard will guide
            WinWait, Torchlight Setup, Please review the license terms
            sleep 1000
            ControlClick, Button2, Torchlight Setup, Please review the license terms
            WinWait, Torchlight Setup, Choose Install Location
            sleep 1000
            ControlClick, Button2, Torchlight Setup, Choose Install Location
            WinWait, Torchlight Setup, Installation Complete
            sleep 1000
            ControlClick, Button2, Torchlight Setup, Installation Complete
            WinWait, Torchlight Setup, Completing the Torchlight Setup Wizard
            sleep 1000
            ControlClick, Button4, Torchlight Setup, Completing the Torchlight Setup Wizard
            ControlClick, Button2, Torchlight Setup, Completing the Torchlight Setup Wizard
        }
        WinWaitClose, Torchlight Setup
    "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Runic Games\\Torchlight" Torchlight.exe
}

#----------------------------------------------------------------

w_metadata twfc games \
    title="Transformers: War for Cybertron" \
    publisher="Activision" \
    year="2010" \
    media="dvd" \
    file1="TWFC_DVD.iso"

load_twfc()
{
    w_read_key
    w_mount TWFC_DVD

    w_ahk_do "
        run ${W_ISO_MOUNT_LETTER}:setup.exe
        SetTitleMatchMode, 2
        winwait, Activision, Select the language for the installation
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, Button1, Activision, Select the language for the installation
            winwait, Transformers, Press NEXT to verify your key
            sleep 1000
            send $W_KEY
            send {Enter}
            winwait, Keycode Check, The Keycode you entered appears to be valid
            sleep 1000
            send {Enter}
            winwait, Transformers, The InstallShield Wizard will install Transformers
            sleep 1000
            controlclick, Button1, Transformers, The InstallShield Wizard will install Transformers
            winwait, Transformers, License Agreement
            sleep 1000
            controlclick, Button5, Transformers, License Agreement
            sleep 1000
            controlclick, Button2, Transformers, License Agreement
            winwait, Transformers, Minimum System Requirements
            sleep 1000
            controlclick, Button1, Transformers, Minimum System Requirements
            winwait, Transformers, Select the setup type to install
            sleep 1000
            controlclick, Button4, Transformers, Select the setup type to install
        }
        ; Installer exits silently. Prevent an early umount
        Loop
        {
            sleep 1000
            IfWinExist, Transformers
                continue
            IfWinExist, Activision
                continue
            sleep 1000
            IfWinExist, Transformers
                continue
            IfWinExist, Activision
                continue
            break
        }
    "

    if w_workaround_wine_bug 6971 "Setting mwo=force... please upgrade to wine-1.3.23" 1.3.23,
    then
        w_call mwo=force
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Activision\\Transformers - War for Cybertron\\Binaries" "TWFC.exe"

    # Clean up crap left over in c:\ when the installer runs the vc 2008 redistributable installer
    cd "$W_DRIVE_C"
    rm -f VC_RED.* eula.*.txt globdata.ini install.exe install.ini install.res.*.dll vcredist.bmp
}

#----------------------------------------------------------------

w_metadata ut3 games \
    title="Unreal Tournament 3" \
    publisher="Midway Games" \
    year="2007" \
    media="dvd" \
    file1="UT3_RC7.iso" \
    file2="UT3Patch5.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Unreal Tournament 3/Binaries/UT3.exe"

load_ut3()
{
    w_download_manual "http://www.filefront.com/13709855/UT3Patch5.exe" UT3Patch5.exe
    w_try w_mount UT3_RC7

    w_ahk_do "
        run ${W_ISO_MOUNT_LETTER}:SetupUT3.exe
        SetTitleMatchMode, slow    ; else can't see EULA text
        SetTitleMatchMode, 2
        SetWinDelay 1000
        WinWait, Choose Setup Language
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1   ; OK
            WinWait, Unreal Tournament 3, GAMESPY ; License Agreement
            ControlClick Button2   ; Yes
            WinWait, Unreal Tournament 3, UnrealEd ; License Agreement
            ControlClick Button2   ; Yes
            WinWait, , Choose Destination
            ControlClick Button1   ; Next
            WinWait, AGEIA PhysX v7.09.13 Setup, License
            ControlClick Button3   ; Accept
            sleep 1000
            ControlClick Button4   ; Next
            WinWait, AGEIA PhysX v7.09.13, Finish
            ControlClick Button1   ; Finish
            ; game now begins installing
        }
        WinWait, , InstallShield Wizard Complete
        if ( w_opt_unattended > 0 ) {
            ControlClick Button4   ; Finish
        }
        WinWaitClose
    "

    cd "$W_CACHE/$W_PACKAGE"
  
    w_ahk_do "
        SetTitleMatchMode, 2
        run UT3Patch5.exe
        WinWait, License
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1   ; Accept
            WinWait, End User License Agreement
            ControlClick Button1   ; Accept
            WinWait, Patch UT3
            ControlClick Button1   ; Yes
        }
        WinWait, , UT3 was successfully patched!
        if ( w_opt_unattended > 0 ) {
            ControlClick Button1   ; OK
        }
        WinWaitClose
    "

    if w_workaround_wine_bug 6971 "Setting mwo=force... please upgrade to wine-1.3.23" 1.3.23,
    then
        w_call mwo=force
        w_warn "Mouse will be disabled in in-game menu. Must use keyboard to navigate.  Alternately, patch wine as described in bug 6971 to use xinput2."
    fi

    # FIXME: enter user's key if -q
    w_declare_exe "$W_PROGRAMS_X86_WIN\\Unreal Tournament 3\\Binaries" "UT3.exe"
}

#----------------------------------------------------------------

w_metadata wog games \
    title="World of Goo Demo" \
    publisher="2D Boy" \
    year="2008" \
    media="download" \
    file1="WorldOfGooDemo.1.0.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/WorldOfGooDemo/WorldOfGoo.exe"

load_wog()
{
    if ! test -f "$W_CACHE/wog/WorldOfGooDemo.1.0.exe"
    then
        # Get temporary download location
        w_download "http://www.worldofgoo.com/dl2.php?lk=demo&filename=WorldOfGooDemo.1.0.exe"
        URL=`cat "$W_CACHE/wog/dl2.php?lk=demo&filename=WorldOfGooDemo.1.0.exe" |
           grep WorldOfGooDemo.1.0.exe | sed 's,.*http,http,;s,".*,,'`
        rm "$W_CACHE/wog/dl2.php?lk=demo&filename=WorldOfGooDemo.1.0.exe"

        w_download "$URL" e61d8253b9fe0663cb3c69018bb3d2ec6152d488
    fi

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 500
        run WorldOfGooDemo.1.0.exe
        winwait, World of Goo Setup, License Agreement
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            WinActivate
            send {Enter}
            winwait, World of Goo Setup, Choose Components
            send {Enter}
            winwait, World of Goo Setup, Choose Install Location
            send {Enter}
            winwait, World of Goo Setup, Thank you
            ControlClick, Make me dirty right now, World of Goo Setup, Thank you
            send {Enter}
        }
        winwaitclose, World of Goo Setup
        "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\WorldOfGooDemo" WorldOfGoo.exe
}

#----------------------------------------------------------------

w_metadata wot games \
    title="World of Tanks" \
    publisher="Wargaming" \
    year="2011" \
    media="download" \
    file1="WoT_0.6.7_us_setup.exe" \
    installed_exe1="c:/Games/World_of_Tanks/WorldOfTanks.exe" \
    wine_showstoppers="20395"   # list a showstopper to hide this from average users for now

load_wot()
{
    if w_workaround_wine_bug 20395 "game requires raw input hack"
    then
        w_open_webpage https://gist.github.com/895204#gistcomment-41069
        w_warn "You need to apply rawinput-hack.patch from vincas for this game to work"
    fi
    if w_workaround_wine_bug 25370 "installing msxml3 to avoid startup crash"
    then
        w_call msxml3
    fi
    if w_workaround_wine_bug 11675 "need d3dx9_36 for effects framework"
    then
        w_call d3dx9_36
    fi
    if w_workaround_wine_bug 25779 "installing ie7 for launcher"
    then
        w_call ie7
    fi

    # http://cdn1.worldoftanks.com/patches/auto/WoT_0.6.7_us_setup.exe.torrent
    w_download http://cdn1.worldoftanks.com/patches/auto/WoT_0.6.7_us_setup.exe 440c4b3f8269d3746c912db94d697eccb139d3a6

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        SetWinDelay 500
        run $file1
        winwait, Setup - World of Tanks
        if ( w_opt_unattended > 0 ) {
            ControlClick, TNewButton1   ; Next
            winwait, Setup - World of Tanks, Select Destination
            ControlClick, TNewButton3   ; Next
            winwait, Setup - World of Tanks, Select Start
            ControlClick, TNewButton4   ; Next
            winwait, Setup - World of Tanks, Select Additional
            ControlClick, TNewButton4   ; Next
            winwait, Setup - World of Tanks, Ready
            ControlClick, TNewButton4   ; Next
        }
        winwait, Setup - World of Tanks, Completing
        if ( w_opt_unattended > 0 ) {
            ControlFocus, TNewCheckListBox1
            send {space}                      ; uncheck Wiki
            sleep 500
            ControlClick, TNewButton4   ; Finish
            winwaitclose
        }
        "
    w_declare_exe "c:\\Games\\World_of_Tanks" WorldOfTanks.exe
}

#----------------------------------------------------------------

w_metadata wowtrial games \
    title="World of Warcraft trial" \
    publisher="Blizzard" \
    year="2010" \
    media="download" \
    file1="WOW-4.0.0.12911-enUS-Trial.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/World of Warcraft/WoW.exe"

load_wowtrial()
{
    w_download http://us.media.battle.net.edgesuite.net/downloads/wow-installers/WOW-4.0.0.12911-enUS-Trial.exe 1efb32d10afc4c200a8f34d44980077668085c95

    cd "$W_CACHE/$W_PACKAGE"

    w_ahk_do "
        SetTitleMatchMode, slow
        SetTitleMatchMode, 2
        run WOW-4.0.0.12911-enUS-Trial.exe
        winwait, World of Warcraft Installer
        if ( w_opt_unattended > 0 ) {
            ; Wait for it to find servers
            sleep 6000
            controlclick, x400 y440 ; Install
            winwait, End User License Agreement
            sleep 1000
            controlclick, Button2 ; Accept
            winwait, World of Warcraft Installer
            sleep 1000
            controlclick, x680 y560 ; OK
        }
        winwait, World of Warcraft v4, Play
        if ( w_opt_unattended > 0 ) {
            ; Wait until left side of progress bar is green; that means the game is playable.
            ;Loop
            ;{
            ;    PixelGetColor, color, 33, 592
            ;    FileAppend, loop1 color is %color%, log.txt
            ;    ifEqual, color, 0x017425
            ;    {
            ;        break
            ;    }
            ;    sleep 5000
            ;}
            ; Wait until left side of progress bar goes blackish, that means game is fully loaded
            Loop
            {
                PixelGetColor, color, 33, 592
                ;FileAppend, loop2 color is %color%, log.txt
                ifEqual, color, 0x003C10
                {
                    break
                }
                sleep 5000
            }
            ; All done downloading, so quit
            winclose
        }
        winwaitclose
    "
    w_declare_exe "$W_PROGRAMS_X86_WIN\\World of Warcraft" WoW.exe
}

#----------------------------------------------------------------

w_metadata zootycoon2_demo games \
    title="Zoo Tycoon 2 demo" \
    publisher="Microsoft" \
    year="2004" \
    media="download" \
    file1="Zoo2Trial.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Microsoft Games/Zoo Tycoon 2 Trial Version/zt2demoretail.exe"

load_zootycoon2_demo()
{
    w_download "http://download.microsoft.com/download/9/f/6/9f6a95f0-f34a-4312-9749-77b81d3de245/Zoo2Trial.exe" 60ad1bb34351f97b579c58234b926055f7979126

    cd "$W_CACHE/$W_PACKAGE"
    w_ahk_do "
        ; Uses winwaitactive, because the windows appear and immediately after another window
        ; gets in the way, then disappears after a second or so
        SetTitleMatchMode, 2
        run Zoo2Trial.exe
        winwaitclose, APPMESSAGE
        winwaitactive, Zoo Tycoon 2 Trial, AUTORUN
        if ( w_opt_unattended > 0 ) {
            sleep 1000
            controlclick, CButtonClassName1, Zoo Tycoon 2 Trial, AUTORUN
            winwaitclose, APPMESSAGE
            winwaitactive, Zoo Tycoon 2 Trial, INSTALLTYPE
            ; 1 second was not enough.
            sleep 3000
            controlclick, CButtonClassName1, Zoo Tycoon 2 Trial, INSTALLTYPE
        }
        winwaitactive, Zoo Tycoon 2 Trial, COMPLETE
        winclose, Zoo Tycoon 2 Trial, COMPLETE
        "

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Microsoft Games\\Zoo Tycoon 2 Trial Version" "zt2demoretail.exe"
}

#----------------------------------------------------------------
# Gog.com games
#----------------------------------------------------------------

w_metadata beneath_a_steel_sky_gog games \
    title="Beneath a Steel Sky (GOG.com, free)" \
    publisher="Virgin Interactive" \
    year="1994" \
    file1="setup_beneath_a_steel_sky.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/GOG.com/Beneath a Steel Sky/ScummVM/scummvm.exe"

load_beneath_a_steel_sky_gog()
{
    winetricks_load_gog "beneath_a_steel_sky" "Beneath a Steel Sky" "" "TsCheckBox4" "ScummVM\\scummvm.exe -c \"C:\\Program Files\\GOG.com\\Beneath a Steel Sky\\beneath.ini\" beneath" "" "" "75176395,1f99e12643529baa91fecfb206139a8921d9589c"
}

w_metadata sacrifice_gog games \
    title="Sacrifice (GOG.com)" \
    publisher="Interplay" \
    year="2000" \
    media="manual_download" \
    file1="setup_sacrifice.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/GOG.com/Sacrifice/Sacrifice.exe"

load_sacrifice_gog()
{
    winetricks_load_gog "sacrifice" "Sacrifice" "" "TsCheckBox2" "sacrifice" "" "" "591161642,63e77685599ce20c08b004a9fa3324e466ce1679"
}

w_metadata the_witcher_2_gog games \
    title="The Witcher 2: Assassins of Kings" \
    publisher="Atari" \
    year="2011" \
    media="manual_download" \
    file1="setup_the_witcher_2.exe" \
    installed_exe1="$W_PROGRAMS_X86_WIN/GOG.com/The Witcher 2/bin/witcher2.exe"

load_the_witcher_2_gog()
{
    winetricks_load_gog "the_witcher_2" \
        "The Witcher 2 - Assassins of Kings" \
        "setup_the_witcher_2-1.bin,2048477,b826cd7b096fd98eab78517752522b2a3ca8af5e\
        setup_the_witcher_2-2.bin,2050788,a419926e4d02de81d79d586bf893150d3231833c \
        setup_the_witcher_2-3.bin,2050788,6974cadc29fb8a8795aa245c5f8bb24e5e0cff5e \
        setup_the_witcher_2-4.bin,2050788,ed79c1e9456801addf6fd6e687528fa01354b0d8 \
        setup_the_witcher_2-5.bin,1631852,354cb73ae3e73cb88dedc53dd472803862a654cf \
        setup_the_witcher_2.bin,129136,d3aa93bf147e155c5035ae15444916feabfd47b4" \
        "" "bin/witcher2.exe" "" "The Witcher 2" \
        "2308,9ca06383301f242143f69fe08974f9d4d713ac6b"
}

# Brief HOWTO for adding a GOG game:
# - "beneath_a_steel_sky" is the installer exe name, minus "setup_" and ".exe"
# - "Beneath a Steel Sky" is installer window title, minus "Setup - "
# - There are no other files for this game, so this parameter is empty.
#   Otherwise it should be of the following form:
#   file_name[,length[,sha1sum]] [...]
# - "TsCheckBox4" is the control name for the checkbox deciding whether it will
#   install some reader (Foxit in this case, could be acrobat reader). That
#   installation is enabled by default, and would just bloat the generic
#   AutoHotKey script, so it gets disabled.
# - "ScummVM\\[...]" is the command line to run the game, as fetched from the
#   shortcut/launcher installer/wine creates, which will be used in BAT scripts
#   created by wisotool
# - The part in the url which is specific to this game is identical to its "id"
#   (first parameter), so this parameter is left out.
# - The install directory is the same as installer window title (second
#   parameter), so this parameter is left out.
# - Main installer size and sha1sum, separated by a comma.

#----------------------------------------------------------------
# Steam Games
#----------------------------------------------------------------

w_metadata alienswarm_steam games \
    title="Alien Swarm (Steam)" \
    publisher="Valve" \
    year="2010" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/alien swarm/swarm.exe"

load_alienswarm_steam()
{
    w_steam_install_game 630 "Alien Swarm"
}

#----------------------------------------------------------------

w_metadata bioshock2_steam games \
    title="Bioshock 2 (Steam)" \
    publisher="2k" \
    year="2010" \
    media="download" \
    wine_showstoppers="7065" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/bioshock2/blort.exe"

load_bioshock2_steam()
{
    w_steam_install_game 8850 "BioShock 2"
}

#----------------------------------------------------------------

w_metadata borderlands_steam games \
    title="Borderlands (Steam, nonfree)" \
    publisher="2K Games" \
    year="2009" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/borderlands/Binaries/Borderlands.exe"

load_borderlands_steam()
{
    w_steam_install_game 8980 "Borderlands"
}

#----------------------------------------------------------------

w_metadata civ5_demo_steam games \
    title="Civ V Demo (Steam)" \
    publisher="2K Games" \
    year="2010" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/sid meier's civilization v - demo/CivilizationV.exe"

load_civ5_demo_steam()
{
    # Start autohotkey watching for directx9 option in the background, and select it when it comes up
    w_ahk_do  "
        SetWinDelay 500
        loop
        {
            ifWinExist, Sid Meier's Civilization V - Demo - Steam
            {
                winactivate
                click 26,108    ; select directx9
                sleep 500
                click 200,150   ; Play
            }
            ifWinExist, Updating Sid Meier's Civilization V - Demo
            {
                break
            }
            sleep 1000
        }
    " &
    _job=$!
	# While that's running, install the game.
	# You'll see *two* Autohotkey icons until that first script
	# finds the dialog it's looking for, clicks, and exits.
	w_info "If you already own the full Civ 5 game on steam, the installer won't even appear."
    w_steam_install_game 65900 "Sid Meier's Civilization V - Demo"
    kill -HUP $_job   # just in case
}

#----------------------------------------------------------------

w_metadata ruse_demo_steam games \
    title="Ruse Demo (Steam)" \
    publisher="Ubisoft" \
    year="2010" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/r.u.s.e. demo/Ruse.exe"

load_ruse_demo_steam()
{
    w_steam_install_game 33310 "R.U.S.E."

    if w_workaround_wine_bug 21939 "Installing Windows Media so game can start"
    then
        w_call wmp9
    fi

    if w_workaround_wine_bug 22016 "Turning off HDR to avoid washed out graphics"
    then
        for dir in "$W_PROGRAMS_X86_UNIX/Steam/userdata"/*/config
        do
            file=../33310/local/Option.ini
            if test -f $file
            then
                sed -i "s/UseHDR = true/UseHDR = false/" $file
            else
                mkdir -p ../33310/local
                cat > "$file" <<_EOF_
[advanced_video]
        UseHDR = false
_EOF_
            fi
        done
    fi
}

#----------------------------------------------------------------

w_metadata supermeatboy_steam games \
    title="Super Meat Boy (Steam, nonfree)" \
    publisher="Independent" \
    year="2010" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/super meat boy/SuperMeatBoy.exe"

load_supermeatboy_steam()
{
    w_steam_install_game 40800 "Super Meat Boy"
}

#----------------------------------------------------------------

w_metadata trine_steam games \
    title="Trine (Steam)" \
    publisher="Frozenbyte" \
    year="2009" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/trine/trine_launcher.exe"

load_trine_steam()
{
    w_steam_install_game 35700 "Trine"

    if w_workaround_wine_bug 21939 "Installing Windows Media Player so game can start"
    then
        w_call wmp9
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Steam\\steamapps\\common\\trine" "trine_launcher.exe"
}

#----------------------------------------------------------------

w_metadata trine_demo_steam games \
    title="Trine Demo (Steam)" \
    publisher="Frozenbyte" \
    year="2009" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/trine demo/trine_launcher.exe"

load_trine_demo_steam()
{
    w_steam_install_game 35710 "Trine Demo"

    if w_workaround_wine_bug 21939 "Installing Windows Media Player so game can start"
    then
        w_call wmp9
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Steam\\steamapps\\common\\trine demo" "trine_launcher.exe"
}

#----------------------------------------------------------------

w_metadata wormsreloaded_demo_steam games \
    title="Worms Reloaded Demo (Steam)" \
    publisher="Team17" \
    year="2010" \
    media="download" \
    installed_exe1="$W_PROGRAMS_X86_WIN/Steam/steamapps/common/worms reloaded/WormsReloaded.exe"

load_wormsreloaded_demo_steam()
{
    if w_workaround_wine_bug 26646 "Installing xact to enable sound"
    then
        w_call xact
    fi
    if w_workaround_wine_bug 26646 "Setting dsoundhw=Emulation to fix choppy sound"
    then
        w_call dsoundhw=Emulation
    fi
    w_steam_install_game 22690 "Worms Reloaded Demo"
}

#----------------------------------------------------------------
# Settings
#----------------------------------------------------------------
# DirectSound settings

winetricks_set_dsound_var()
{
    arg=$2
    case $2 in
    [Ff]*) arg=Full;;
    [Ss]*) arg=Standard;;
    [Bb]*) arg=Basic;;
    [Ee]*) arg=Emulation;;
    esac

    echo "Setting DirectSound $1 to $arg"
    cat > "$W_TMP"/set-dsound.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\DirectSound]
"$1"="$arg"

_EOF_
    w_try_regedit "$W_TMP_WIN"\\set-dsound.reg
}

w_metadata dsoundbug9612 settings \
    title="Use DirectSound MaxShadowSize=0 workaround for wine bug 9612"

load_dsoundbug9612()
{
    if w_workaround_wine_bug 9612
    then
        winetricks_set_dsound_var MaxShadowSize 0
    fi
}

w_metadata dsoundhw=Full settings \
    title="Set DirectSound hardware acceleration to Full (default)"
w_metadata dsoundhw=Standard settings \
    title="Set DirectSound hardware acceleration to Standard"
w_metadata dsoundhw=Basic settings \
    title="Set DirectSound hardware acceleration to Basic"
w_metadata dsoundhw=Emulation settings \
    title="Set DirectSound hardware acceleration to Emulation"

load_dsoundhw()
{
    winetricks_set_dsound_var HardwareAcceleration $1
}

#----------------------------------------------------------------
# Direct3D settings

winetricks_set_wined3d_var()
{
    # Filter out/correct bad or partial values
    # Confusing because dinput uses 'disable', but d3d uses 'disabled'
    # see wined3d_dll_init() in dlls/wined3d/wined3d_main.c
    # and DllMain() in dlls/ddraw/main.c
    case $2 in
    disable*) arg=disabled;;
    enable*) arg=enabled;;
    hard*) arg=hardware;;
    repack) arg=repack;;
    backbuffer|fbo|gdi|none|opengl|readdraw|readtex|texdraw|textex|auto) arg=$2;;
    [0-9]*) arg=$2;;
    *) w_die "illegal value $2 for $1";;
    esac

    echo "Setting Direct3D/$1 to $arg"
    cat > "$W_TMP"/set-wined3d.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"$1"="$arg"

_EOF_
    w_try_regedit "$W_TMP_WIN"\\set-wined3d.reg
}

#----------------------------------------------------------------

w_metadata glsl=enabled settings \
    title="Enable glsl shaders (default)"
w_metadata glsl=disabled settings \
    title="Disable glsl shaders, use arb shaders (faster, but sometimes breaks)"

load_glsl()
{
    winetricks_set_wined3d_var UseGLSL $1
}

#----------------------------------------------------------------

w_metadata multisampling=enabled settings \
    title="Enable Direct3D multisampling"
w_metadata multisampling=disabled settings \
    title="Disable Direct3D multisampling"

load_multisampling()
{
    winetricks_set_wined3d_var Multisampling $1
}

#----------------------------------------------------------------

w_metadata npm=repack settings \
    title="Set NonPower2Mode to repack"

load_npm()
{
    winetricks_set_wined3d_var NonPower2Mode $1
}

#----------------------------------------------------------------
 
w_metadata orm=fbo settings \
    title="Set OffscreenRenderingMode=fbo (default)"
w_metadata orm=backbuffer settings \
    title="Set OffscreenRenderingMode=backbuffer"

load_orm()
{
    winetricks_set_wined3d_var OffscreenRenderingMode $1
}

#----------------------------------------------------------------

w_metadata psm=enabled settings \
    title="Set PixelShaderMode to enabled"
w_metadata psm=disabled settings \
    title="Set PixelShaderMode to disabled"

load_psm()
{
    winetricks_set_wined3d_var PixelShaderMode $1
}

#----------------------------------------------------------------

w_metadata strictdrawordering=enabled settings \
    title="Enable StrictDrawOrdering"
w_metadata strictdrawordering=disabled settings \
    title="Disable StrictDrawOrdering (default)"

load_strictdrawordering()
{
    winetricks_set_wined3d_var StrictDrawOrdering $1
}

#----------------------------------------------------------------

w_metadata rtlm=auto settings \
    title="Set RenderTargetLockMode to auto (default)"
w_metadata rtlm=disabled settings \
    title="Set RenderTargetLockMode to disabled"
w_metadata rtlm=readdraw settings \
    title="Set RenderTargetLockMode to readdraw"
w_metadata rtlm=readtex settings \
    title="Set RenderTargetLockMode to readtex"
w_metadata rtlm=texdraw settings \
    title="Set RenderTargetLockMode to texdraw"
w_metadata rtlm=textex settings \
    title="Set RenderTargetLockMode to textex"

load_rtlm()
{
    winetricks_set_wined3d_var RenderTargetLockMode $1
}

#----------------------------------------------------------------
# DirectDraw settings

w_metadata ddr=gdi settings \
    title="Set DirectDrawRenderer to gdi"
w_metadata ddr=opengl settings \
    title="Set DirectDrawRenderer to opengl"

load_ddr()
{
    winetricks_set_wined3d_var DirectDrawRenderer $1
}

#----------------------------------------------------------------
# DirectInput settings

w_metadata mwo=force settings \
    title="Set DirectInput MouseWarpOverride to force (needed by some games)"
w_metadata mwo=enabled settings \
    title="Set DirectInput MouseWarpOverride to enabled (default)"
w_metadata mwo=disable settings \
    title="Set DirectInput MouseWarpOverride to disable"

load_mwo()
{
    # Filter out/correct bad or partial values
    # Confusing because dinput uses 'disable', but d3d uses 'disabled'
    # see alloc_device() in dlls/dinput/mouse.c
    case $1 in
    enable*) arg=enabled;;
    disable*) arg=disable;;
    force) arg=force;;
    *) w_die "illegal value $1 for MouseWarpOverride";;
    esac

    echo "Setting MouseWarpOverride to $arg"
    cat > "$W_TMP"/set-mwo.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\DirectInput]
"MouseWarpOverride"="$arg"

_EOF_
    w_try_regedit "$W_TMP"/set-mwo.reg
}

#----------------------------------------------------------------
# X11 Driver settings

w_metadata grabfullscreen=y settings \
    title="Force cursor clipping for full-screen windows (needed by some games)"
w_metadata grabfullscreen=n settings \
    title="Disable cursor clipping for full-screen windows (default)"

load_grabfullscreen()
{
    case $1 in
    y|n) arg=$1;;
    *) w_die "illegal value $1 for GrabFullscreen";;
    esac

    echo "Setting GrabFullscreen to $arg"
    cat > "$W_TMP"/set-gfs.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"GrabFullscreen"="$arg"

_EOF_
    w_try_regedit "$W_TMP"/set-gfs.reg
}

#----------------------------------------------------------------
# Other settings

#----------------------------------------------------------------

w_metadata alldlls=default settings \
    title="Remove all DLL overrides"
w_metadata alldlls=builtin settings \
    title="Override most common DLLs to builtin"

load_alldlls()
{
    case $1 in
    default) w_override_no_dlls ;;
    builtin) w_override_all_dlls ;;
    esac
}

w_metadata fontsmooth=disable settings \
    title="Disable font smoothing"
w_metadata fontsmooth=bgr settings \
    title="Enable subpixel font smoothing for BGR LCDs"
w_metadata fontsmooth=rgb settings \
    title="Enable subpixel font smoothing for RGB LCDs"
w_metadata fontsmooth=gray settings \
    title="Enable subpixel font smoothing"

load_fontsmooth()
{
    case $1 in
    disable)   FontSmoothing=0; FontSmoothingOrientation=1; FontSmoothingType=0;;
    gray|grey) FontSmoothing=2; FontSmoothingOrientation=1; FontSmoothingType=1;;
    bgr)       FontSmoothing=2; FontSmoothingOrientation=0; FontSmoothingType=2;;
    rgb)       FontSmoothing=2; FontSmoothingOrientation=1; FontSmoothingType=2;;
    *) w_die "unknown font smoothing type $1";;
    esac

    echo "Setting font smoothing to $1"

    cat > "$W_TMP"/fontsmooth.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Control Panel\Desktop]
"FontSmoothing"="$FontSmoothing"
"FontSmoothingGamma"=dword:00000578
"FontSmoothingOrientation"=dword:0000000$FontSmoothingOrientation
"FontSmoothingType"=dword:0000000$FontSmoothingType

_EOF_
    w_try_regedit "$W_TMP_WIN"\\fontsmooth.reg
}

#----------------------------------------------------------------

w_metadata forcemono settings \
    title="Force using mono instead of .Net (for debugging)"

load_forcemono()
{
    w_override_dlls native mscoree
    w_override_dlls disabled mscorsvw.exe
}

#----------------------------------------------------------------

w_metadata heapcheck settings \
    title="Enable heap checking with GlobalFlag"

load_heapcheck()
{
    cat > "$W_TMP"/heapcheck.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager]
"GlobalFlag"=dword:00200030

_EOF_
    w_try_regedit "$W_TMP_WIN"\\heapcheck.reg
}

#----------------------------------------------------------------

w_metadata hosts settings \
    title="Add empty C:\windows\system32\drivers\etc\{hosts,services} files"

load_hosts()
{
    # Create fake system32\drivers\etc\hosts and system32\drivers\etc\services files.
    # The hosts file is used to map network names to IP addresses without DNS.
    # The services file is used map service names to network ports.
    # Some apps depend on these files, but they're not implemented in wine.
    # Fortunately, empty files in the correct location satisfy those apps.
    # See http://bugs.winehq.org/show_bug.cgi?id=12076

    # It's in system32 for both win32/win64
    mkdir -p "$W_WINDIR_UNIX"/system32/drivers/etc
    touch "$W_WINDIR_UNIX"/system32/drivers/etc/hosts
    touch "$W_WINDIR_UNIX"/system32/drivers/etc/services
}

#----------------------------------------------------------------

w_metadata native_mdac settings \
    title="Override odbc32, odbccp32 and oledb32"

load_native_mdac()
{
    # Set those overrides globally so user programs get MDAC's odbc
    # instead of wine's unixodbc
    w_override_dlls native,builtin odbc32 odbccp32 oledb32
}

#----------------------------------------------------------------

w_metadata native_oleaut32 settings \
    title="Override oleaut32"

load_native_oleaut32()
{
    w_override_dlls native,builtin oleaut32
}

#----------------------------------------------------------------

w_metadata nocrashdialog settings \
    title="Disable crash dialog"

load_nocrashdialog()
{
    echo "Disabling graphical crash dialog"
    cat > "$W_TMP"/crashdialog.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\WineDbg]
"ShowCrashDialog"=dword:00000000

_EOF_
    cd "$W_TMP"
    w_try_regedit crashdialog.reg
}

#----------------------------------------------------------------

w_metadata nt40 settings \
    title="Set windows version to Windows NT 4.0"

load_nt40()
{
    w_set_winver nt40
}

#----------------------------------------------------------------

w_metadata sandbox settings \
    title="Sandbox the wineprefix - remove links to HOME"

load_sandbox()
{
    w_skip_windows sandbox && return

    # Unmap drive Z
    # Might want to unpack gecko first, since Wine won't be able to get to /usr/lib/wine after this
    rm -f "$WINEPREFIX/dosdevices/z:"

    if test -d "$WINEPREFIX/drive_c/users/$USER/Documents"
    then
        for dir in Desktop Documents Music Pictures Videos
        do
            rm -f "$WINEPREFIX/drive_c/users/$USER/$dir" > /dev/null 2>&1
            mkdir -p "$WINEPREFIX/drive_c/users/$USER/$dir"
        done
    elif test -d "$WINEPREFIX/drive_c/users/$USER/My Documents"
    then
        for dir in Desktop "My Documents" "My Music" "My Pictures" "My Videos"
        do
            rm -f "$WINEPREFIX/drive_c/users/$USER/$dir" > /dev/null 2>&1
            mkdir -p "$WINEPREFIX/drive_c/users/$USER/$dir"
        done
    else
        w_die "don't know name of My Documents folder, can't sandbox"
    fi


    # Disable unixfs
    # Unfortunately, when you run with a different version of wine, wine will recreate this key.
    # See http://bugs.winehq.org/show_bug.cgi?id=22450
    $WINE regedit /d 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\Namespace\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}'

    # Disable recreation of the above key - or any updating of the regisry - when running with new version of wine.
    echo disable > "$WINEPREFIX/.update-timestamp"
}

#----------------------------------------------------------------

w_metadata sound=alsa settings \
    title="Set sound driver to ALSA"
w_metadata sound=coreaudio settings \
    title="Set sound driver to Mac CoreAudio"
w_metadata sound=disabled settings \
    title="Set sound driver to disabled"
w_metadata sound=esd settings \
    title="Set sound driver to esound"
w_metadata sound=jack settings \
    title="Set sound driver to Jack"
w_metadata sound=nas settings \
    title="Set sound driver to NAS"
w_metadata sound=oss settings \
    title="Set sound driver to OSS"

load_sound()
{
    echo "Setting sound driver to $1"
    cat > "$W_TMP"/set-sound.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Drivers]
"Audio"="$1"

_EOF_
    w_try_regedit "$W_TMP_WIN"\\set-sound.reg
}

#----------------------------------------------------------------

w_metadata vd=off settings \
    title="Disable virtual desktop"
w_metadata vd=640x480 settings \
    title="Enable virtual desktop, set size to 640x480"
w_metadata vd=800x600 settings \
    title="Enable virtual desktop, set size to 800x600"
w_metadata vd=1024x768 settings \
    title="Enable virtual desktop, set size to 1024x768"
w_metadata vd=1280x1024 settings \
    title="Enable virtual desktop, set size to 1280x1024"
w_metadata vd=1440x900 settings \
    title="Enable virtual desktop, set size to 1440x900"

load_vd()
{
    size=$1
    case $size in
    off|disabled)
        cat > "$W_TMP"/vd.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"=-
[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"=-

_EOF_
        ;;
    [1-9]*x[1-9]*)
        cat > "$W_TMP"/vd.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"
[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="$size"

_EOF_
        ;;
    *)
        w_die "you want a virtual desktop of $size?  I don't understand."
        ;;
    esac
    w_try_regedit "$W_TMP_WIN"/vd.reg
}

#----------------------------------------------------------------

w_metadata videomemorysize=default settings \
    title="Let Wine detect amount of video card memory"
w_metadata videomemorysize=512 settings \
    title="Tell Wine your video card has 512MB RAM"
w_metadata videomemorysize=1024 settings \
    title="Tell Wine your video card has 1024MB RAM"

load_videomemorysize()
{
    size=$1
    echo "Setting video memory size to $size"

    case $size in
    default)

    cat > "$W_TMP"/set-video.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"VideoMemorySize"=-

_EOF_
    ;;
    *)
    cat > "$W_TMP"/set-video.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"VideoMemorySize"="$size"

_EOF_
    esac
    w_try_regedit "$W_TMP_WIN"\\set-video.reg
}

#----------------------------------------------------------------

w_metadata vista settings \
    title="Set windows version to Windows Vista"

load_vista()
{
    w_set_winver vista
}

#----------------------------------------------------------------

w_metadata volnum settings \
    title="Rename drive_c to harddiskvolume0 (needed by some installers)"

load_volnum() {
    w_skip_windows "volnum" && return

    # Recent Microsoft installers are often based on "windows package manager", see
    # http://support.microsoft.com/kb/262841 and
    # http://www.microsoft.com/technet/prodtechnol/windowsserver2003/deployment/winupdte.mspx
    # These installers check the drive name, and if it doesn't start with 'harddisk',
    # they complain "Unable to find a volume for file extraction", see
    # http://bugs.winehq.org/show_bug.cgi?id=5351
    # You may be able to work around this by using the installer's /x or /extract switch,
    # but renaming drive_c to "harddiskvolume0" lets you just run the installer as normal.

    if test ! -d "$WINEPREFIX"/harddiskvolume0/
    then
        ln -s drive_c "$WINEPREFIX"/harddiskvolume0
        rm "$WINEPREFIX"/dosdevices/c:
        ln -s ../harddiskvolume0 "$WINEPREFIX"/dosdevices/c:
        echo "Renamed drive_c to harddiskvolume0"
    else
        echo "drive_c already named harddiskvolume0"
    fi
}

#----------------------------------------------------------------

w_metadata vsm=hardware settings \
    title="Set VertexShaderMode to hardware"

load_vsm()
{
    winetricks_set_wined3d_var VertexShaders $1
}

#----------------------------------------------------------------

w_metadata win2k settings \
    title="Set windows version to Windows 2000"

load_win2k()
{
    w_set_winver win2k
}

#----------------------------------------------------------------

w_metadata win31 settings \
    title="Set windows version to Windows 3.1"

load_win31()
{
    w_set_winver win31
}

#----------------------------------------------------------------

w_metadata win7 settings \
    title="Set windows version to Windows 7"

load_win7()
{
    w_set_winver win7
}

#----------------------------------------------------------------

w_metadata win95 settings \
    title="Set windows version to Windows 95"

load_win95()
{
    w_set_winver win95
}

#----------------------------------------------------------------

w_metadata win98 settings \
    title="Set windows version to Windows 98"

load_win98()
{
    w_set_winver win98
}

#----------------------------------------------------------------

# Really, we should support other values, since winetricks did
w_metadata winver= settings \
    title="Set windows version to default (winxp)"

load_winver()
{
    w_set_winver winxp
}

#----------------------------------------------------------------

w_metadata winxp settings \
    title="Set windows version to Windows XP"

load_winxp()
{
    w_set_winver winxp
}

#----------------------------------------------------------------

#---- Derived Metadata ----
# Generated automatically by measuring time and space requirements of all verbs
# size_MB includes size of virgin wineprefix, but not the cached installer

for data in \
    3dmark03:size_MB=895,time_sec=149 \
    3dmark05:size_MB=1255,time_sec=208 \
    3dmark06:size_MB=2627,time_sec=461 \
    3dmark2000:size_MB=165,time_sec=71 \
    3dmark2001:size_MB=260,time_sec=141 \
    7zip:size_MB=53,time_sec=9 \
    abiword:size_MB=119,time_sec=15 \
    adobeair:size_MB=132,time_sec=8 \
    algodoo_demo:size_MB=165,time_sec=52 \
    allcodecs:size_MB=48,time_sec=3 \
    allfonts:size_MB=132,time_sec=114 \
    amstream:size_MB=48,time_sec=2 \
    aoe3_demo:size_MB=4472,time_sec=422 \
    aoe_demo:size_MB=164,time_sec=35 \
    art2kmin:size_MB=363,time_sec=36 \
    atmlib:size_MB=454,time_sec=73 \
    autohotkey:size_MB=53,time_sec=4 \
    baekmuk:size_MB=138,time_sec=3 \
    bioshock_demo:size_MB=7510,time_sec=1543 \
    bladekitten_demo:size_MB=1444,time_sec=174 \
    cjkfonts:size_MB=48,time_sec=4 \
    cmake:size_MB=85,time_sec=8 \
    cnc3_demo:size_MB=5244,time_sec=1022 \
    cod4mw_demo:size_MB=5730,time_sec=1108 \
    cod_demo:size_MB=574,time_sec=115 \
    colorprofile:size_MB=47,time_sec=1 \
    comctl32:size_MB=49,time_sec=1 \
    comdlg32ocx:size_MB=49,time_sec=1 \
    controlpad:size_MB=69,time_sec=4 \
    corefonts:size_MB=62,time_sec=2 \
    crypt32:size_MB=178,time_sec=71 \
    crysis2:size_MB=8259,time_sec=1200 \
    crysis2_demo_mp:size_MB=5259,time_sec=1473 \
    d3dcompiler_43:size_MB=138,time_sec=51 \
    d3dx10:size_MB=50,time_sec=4 \
    d3dx11_43:size_MB=48,time_sec=1 \
    d3dx9:size_MB=126,time_sec=3 \
    d3dx9_26:size_MB=48,time_sec=2 \
    d3dx9_28:size_MB=48,time_sec=1 \
    d3dx9_31:size_MB=48,time_sec=2 \
    d3dx9_35:size_MB=50,time_sec=2 \
    d3dx9_36:size_MB=48,time_sec=1 \
    d3dx9_42:size_MB=48,time_sec=1 \
    d3dxof:size_MB=48,time_sec=2 \
    dc2ba_demo:size_MB=209,time_sec=38 \
    deadspace2:size_MB=12693,time_sec=720 \
    devenum:size_MB=59,time_sec=2 \
    diablo2:size_MB=2577,time_sec=37 \
    dinput:size_MB=48,time_sec=1 \
    dinput8:size_MB=61,time_sec=2 \
    dirac:size_MB=50,time_sec=4 \
    directmusic:size_MB=63,time_sec=4 \
    directplay:size_MB=61,time_sec=3 \
    directx9:size_MB=387,time_sec=12 \
    dirt2_demo:size_MB=6241,time_sec=977 \
    divinity2_demo:size_MB=2906,time_sec=2627 \
    dmsynth:size_MB=57,time_sec=2 \
    dotnet11:size_MB=94,time_sec=15 \
    dotnet20:size_MB=360,time_sec=64 \
    dotnet30:size_MB=645,time_sec=302 \
    dotnet35:size_MB=1149,time_sec=445 \
    dragonage:size_MB=23771,time_sec=673 \
    dragonage2_demo:size_MB=4014,time_sec=1428 \
    droid:size_MB=63,time_sec=8 \
    dsound:size_MB=48,time_sec=1 \
    dxdiag:size_MB=75,time_sec=6 \
    dxdiagn:size_MB=48,time_sec=1 \
    eufonts:size_MB=58,time_sec=2 \
    eve:size_MB=5313,time_sec=1568 \
    eve:size_MB=11215,time_sec=467 \
    farmsim2011_demo:size_MB=48,time_sec=4 \
    ffdshow:size_MB=53,time_sec=4 \
    fifa11_demo:size_MB=4932,time_sec=845 \
    firefox:size_MB=113,time_sec=7 \
    firefox4:size_MB=147,time_sec=36 \
    flash:size_MB=57,time_sec=3 \
    fontfix:size_MB=47,time_sec=0 \
    fontxplorer:size_MB=51,time_sec=5 \
    gdiplus:size_MB=50,time_sec=2 \
    gecko110:size_MB=47,time_sec=0 \
    gfw:size_MB=211,time_sec=11 \
    glut:size_MB=47,time_sec=1 \
    gothic4_demo:size_MB=7719,time_sec=1402 \
    guildwars:size_MB=224,time_sec=392 \
    hegemony_demo:size_MB=1927,time_sec=315 \
    hegemonygold_demo:size_MB=2339,time_sec=247 \
    hon:size_MB=1536,time_sec=337 \
    hphbp_demo:size_MB=2898,time_sec=556 \
    icodecs:size_MB=60,time_sec=29 \
    ie6:size_MB=340,time_sec=58 \
    ie7:size_MB=181,time_sec=44 \
    ie8:size_MB=202,time_sec=39 \
    imvu:size_MB=194,time_sec=17 \
    jet40:size_MB=54,time_sec=3 \
    l3codecx:size_MB=60,time_sec=5 \
    lhp_demo:size_MB=3200,time_sec=645 \
    liberation:size_MB=50,time_sec=3 \
    lucida:size_MB=51,time_sec=1 \
    masseffect2_demo:size_MB=8291,time_sec=1397 \
    mb_warband_demo:size_MB=1495,time_sec=35 \
    mdac25:size_MB=97,time_sec=6 \
    mdac27:size_MB=70,time_sec=3 \
    mdac28:size_MB=75,time_sec=4 \
    mfc40:size_MB=48,time_sec=0 \
    mfc42:size_MB=47,time_sec=1 \
    mingw:size_MB=132,time_sec=3 \
    mono210:size_MB=463,time_sec=26 \
    mono26:size_MB=434,time_sec=26 \
    mono28:size_MB=550,time_sec=28 \
    mozillabuild:size_MB=891,time_sec=26 \
    mpc:size_MB=87,time_sec=2 \
    msasn1:size_MB=178,time_sec=3 \
    mshflxgd:size_MB=47,time_sec=0 \
    msi2:size_MB=62,time_sec=4 \
    msls31:size_MB=48,time_sec=0 \
    msmask:size_MB=47,time_sec=0 \
    mspaint:size_MB=49,time_sec=0 \
    msscript:size_MB=48,time_sec=0 \
    msxml3:size_MB=49,time_sec=1 \
    msxml4:size_MB=55,time_sec=0 \
    msxml6:size_MB=54,time_sec=1 \
    nfsshift_demo:size_MB=4877,time_sec=157 \
    ogg:size_MB=54,time_sec=1 \
    opensymbol:size_MB=49,time_sec=1 \
    openwatcom:size_MB=274,time_sec=12 \
    osmos_demo:size_MB=67,time_sec=5 \
    pdh:size_MB=48,time_sec=0 \
    penpenxmas:size_MB=49,time_sec=6 \
    physx:size_MB=213,time_sec=5 \
    plantsvszombies:size_MB=156,time_sec=24 \
    pngfilt:size_MB=49,time_sec=0 \
    puzzleagent_demo:size_MB=495,time_sec=36 \
    python26:size_MB=160,time_sec=9 \
    python26_comtypes:size_MB=46,time_sec=1 \
    quartz:size_MB=62,time_sec=3 \
    quicktime72:size_MB=219,time_sec=9 \
    quicktime76:size_MB=237,time_sec=6 \
    rayman2_demo:size_MB=239,time_sec=146 \
    riched20:size_MB=49,time_sec=0 \
    riched30:size_MB=48,time_sec=0 \
    richtx32:size_MB=48,time_sec=0 \
    safari:size_MB=210,time_sec=4 \
    sammax301_demo:size_MB=1419,time_sec=341 \
    sammax304_demo:size_MB=1642,time_sec=88 \
    secondlife:size_MB=266,time_sec=24 \
    secur32:size_MB=47,time_sec=0 \
    shockwave:size_MB=134,time_sec=6 \
    sims3:size_MB=12884,time_sec=584 \
    sketchup:size_MB=319,time_sec=15 \
    spotify:size_MB=59,time_sec=4 \
    starcraft2_demo:size_MB=5241,time_sec=211 \
    tahoma:size_MB=48,time_sec=0 \
    takao:size_MB=176,time_sec=3 \
    tmnationsforever:size_MB=1871,time_sec=116 \
    uff:size_MB=47,time_sec=0 \
    unifont:size_MB=51,time_sec=0 \
    usp10:size_MB=50,time_sec=0 \
    ut3:size_MB=7355,time_sec=426 \
    utorrent:size_MB=48,time_sec=1 \
    vb2run:size_MB=48,time_sec=0 \
    vb3run:size_MB=47,time_sec=0 \
    vb4run:size_MB=49,time_sec=0 \
    vb5run:size_MB=49,time_sec=0 \
    vb6run:size_MB=50,time_sec=1 \
    vc2005express:size_MB=1614,time_sec=173 \
    vc2005trial:size_MB=7156,time_sec=53 \
    vcrun2003:size_MB=47,time_sec=0 \
    vcrun2005:size_MB=60,time_sec=2 \
    vcrun2008:size_MB=60,time_sec=2 \
    vcrun2010:size_MB=71,time_sec=7 \
    vcrun6:size_MB=51,time_sec=0 \
    vcrun6sp6:size_MB=109,time_sec=2 \
    vjrun20:size_MB=319,time_sec=57 \
    vlc:size_MB=221,time_sec=7 \
    wenquanyi:size_MB=50,time_sec=0 \
    windowscodecs:size_MB=53,time_sec=2 \
    winhttp:size_MB=49,time_sec=0 \
    wininet:size_MB=47,time_sec=0 \
    wme9:size_MB=136,time_sec=5 \
    wmi:size_MB=62,time_sec=12 \
    wmp10:size_MB=161,time_sec=7 \
    wmp9:size_MB=143,time_sec=12 \
    wog:size_MB=124,time_sec=5 \
    wsh56js:size_MB=45,time_sec=0 \
    xact:size_MB=60,time_sec=6 \
    xinput:size_MB=47,time_sec=2 \
    xmllite:size_MB=50,time_sec=4 \
    xvid:size_MB=54,time_sec=2 \
    zootycoon2_demo:size_MB=299,time_sec=32 \

do
    cmd=${data%%:*}
    file="`echo "$WINETRICKS_METADATA"/*/$cmd.vars`"
    if test -f "$file"
    then
        case $data in
        *size_MB*)
            size_MB=${data##*size_MB=}       # remove anything before value
            size_MB=${size_MB%%,*}           # remove anything after value
            echo size_MB=$size_MB >> "$file"
            ;;
        esac

        case $data in
        *time_sec*)
            time_sec=${data##*time_sec=}
            time_sec=${time_sec%%,*}
            echo time_sec=$time_sec >> "$file"
        esac
    fi
    unset size_MB time_sec
done

#---- Main Program ----

winetricks_stats_save()
{
    # Save opt-in status
    if test "$WINETRICKS_STATS_REPORT"
    then
        echo "$WINETRICKS_STATS_REPORT" > "$W_CACHE"/track_usage
    fi
}

winetricks_stats_init()
{
    # Load opt-in status if not already set by a commandline option
    if test ! "$WINETRICKS_STATS_REPORT" && test -f "$W_CACHE"/track_usage
    then
        WINETRICKS_STATS_REPORT=`cat "$W_CACHE"/track_usage`
    fi

    if test ! "$WINETRICKS_STATS_REPORT" 
    then
        # No opt-in status found.  If GUI active, ask user whether they would like to opt in.
        case $WINETRICKS_GUI in
        zenity) 
            case $LANG in
            *)
                title="One-time question about helping Winetricks development"
                question="Would you like to help winetricks development by letting winetricks report statistics?  You can turn reporting off at any time with the command 'winetricks --optout'"
                thanks="Thanks!  You won't be asked this question again.  Remember, you can turn reporting off at any time with the command 'winetricks --optout'"
                declined="OK, winetricks will *not* report statistics.  You won't be asked this question again."
                ;;
            esac
            if $WINETRICKS_GUI --question --text "$question" --title "$title"
            then
                $WINETRICKS_GUI --info --text "$thanks"
                WINETRICKS_STATS_REPORT=1
            else
                $WINETRICKS_GUI --info --text "$declined"
                WINETRICKS_STATS_REPORT=0
            fi
            echo $WINETRICKS_STATS_REPORT > "$W_CACHE"/track_usage
            ;;
        esac
    fi
    winetricks_stats_save
}

# Retrieve a short string with the operating system name and version
winetricks_os_description()
{
    (
    case "$OS" in
    "Windows_NT")
        echo windows ;;
    *)  echo "$WINETRICKS_WINE_VERSION" ;;
    esac 
    ) | tr '\012' ' '
}

winetricks_stats_report()
{
    # If user has opted in to usage tracking, report what he used (if anything)
    case "$WINETRICKS_STATS_REPORT" in
    1) ;;
    *) return;;
    esac
    test -f "$WINETRICKS_WORKDIR"/breadcrumbs || return

    WINETRICKS_STATS_BREADCRUMBS=`cat "$WINETRICKS_WORKDIR"/breadcrumbs | tr '\012' ' '`
    echo "You opted in, so reporting '$WINETRICKS_STATS_BREADCRUMBS' to the winetricks maintainer so he knows which winetricks verbs get used and which don't.  Use --optout to disable future reports."

    report="os=`winetricks_os_description`&winetricks=$WINETRICKS_VERSION&breadcrumbs=$WINETRICKS_STATS_BREADCRUMBS"
    report="`echo $report | sed 's/ /%20/g'`"
    # Just do a HEAD request with the raw commandline.  
    # Yes, this can be fooled by caches.  That's ok.
    if [ -x "`which wget 2>/dev/null`" ]
    then
        wget --spider "http://kegel.com/data/winetricks-usage?$report" > /dev/null 2>&1 || true
    elif [ -x "`which curl 2>/dev/null`" ]
    then
        curl -I "http://kegel.com/data/winetricks-usage?$report" > /dev/null 2>&1 || true
    fi
}

winetricks_stats_log_command()
{
    # log what we execute for possible later statistics reporting
    echo "$*" >> "$WINETRICKS_WORKDIR/breadcrumbs"

    # and for the user's own reference later, when figuring out what he did
    case "$OS" in
    "Windows_NT") _W_LOGDIR="$W_WINDIR_UNIX"/Temp ;;
    *) _W_LOGDIR="$WINEPREFIX" ;;
    esac
    mkdir -p "$_W_LOGDIR"
    echo "$*" >> "$_W_LOGDIR"/winetricks.log
    unset _W_LOGDIR
}

# Launch a new terminal window if in gui, or 
# spawn a shell in the current window if commandline.
# New shell contains proper WINEPREFIX and WINE environment variables.
# May be useful when debugging verbs.
winetricks_shell()
{
    (
    cd "$W_DRIVE_C"
    export WINE

    case $WINETRICKS_GUI in
    none)
        $SHELL
        ;;
    *)
        for term in gnome-terminal konsole Terminal xterm
        do
            if test `which $term` 2> /dev/null
            then
                $term
                break
            fi
        done
        ;;
    esac
    )
}

# Usage: execute_command verb[=argument]
execute_command()
{
    case "$1" in
    *=*) arg=`echo $1 | sed 's/.*=//'`; cmd=`echo $1 | sed 's/=.*//'`;;
    *) cmd="$1"; arg="" ;;
    esac

    case "$1" in

    # FIXME: avoid duplicated code
    apps|benchmarks|dlls|fonts|games|prefix|settings)
        WINETRICKS_CURMENU=$1
        ;;

    # Late options
    -*)
        if ! winetricks_handle_option $1
        then
            winetricks_usage
            exit 1
        fi
        ;;

    # Hard-coded verbs
    main) WINETRICKS_CURMENU=main ;;
    help) w_open_webpage http://winetricks.org/help ;;
    list) winetricks_list_all ;;
    list-cached) winetricks_list_cached ;;
    list-download) winetricks_list_download ;;
    list-manual-download) winetricks_list_manual_download ;;
    list-installed) winetricks_list_installed ;;
    unattended) winetricks_set_unattended 1 ;;
    attended) winetricks_set_unattended 0 ;;
    showbroken) W_OPT_SHOWBROKEN=1 ;;
    hidebroken) W_OPT_SHOWBROKEN=0 ;;
    prefix=*) winetricks_set_wineprefix "$arg" ;;
    annihilate) winetricks_annihilate_wineprefix ;;
    folder) xdg-open "$WINEPREFIX" ;;
    winecfg) $WINE winecfg ;;
    regedit) $WINE regedit ;;
    taskmgr) $WINE taskmgr & ;;
    shell) winetricks_shell ;;

    # These have to come before *=disabled to avoid looking like dlls
    fontsmooth=disable*) w_call fontsmooth=disable ;;
    glsl=disable*) w_call glsl=disabled ;;
    multisampling=disable*) w_call multisampling=disabled ;;
    mwo=disable*) w_call mwo=disable ;;   # FIXME: relax matching so we can handle these spelling differences in verb instead of here
    psm=disable*) w_call psm=disabled ;;
    rtlm=disable*) w_call rtlm=disabled ;;
    sound=disable*) w_call sound=disabled ;;
    strictdrawordering=disable*) w_call strictdrawordering=disabled ;;

    # For convenience, allow users to use lower case and abbreviate.
    # FIXME: expand this?
    dsoundhw=f*) w_call dsoundhw=Full ;;
    dsoundhw=s*) w_call dsoundhw=Standard ;;
    dsoundhw=b*) w_call dsoundhw=Basic ;;
    dsoundhw=e*) w_call dsoundhw=Emulation ;;

    # Use winecfg if you want a gui for plain old dll overrides
    alldlls=*) w_call $1 ;;
    *=native) w_do_call native $cmd;;
    *=builtin) w_do_call builtin $cmd;;
    *=disabled) w_do_call disabled $cmd;;

    # Hacks for backwards compatibility
    cc580) w_call comctl32 ;;
    comdlg32.ocx) w_call comdlg32ocx ;;
    dotnet1) w_call dotnet11 ;;
    dotnet2) w_call dotnet20 ;;
    firefox3) w_call firefox35 ;;  # the one that works
    fm20) w_call controlpad ;;   # art2kmin also comes with fm20.dll
    fontsmooth-bgr) w_call fontsmooth=bgr ;;
    fontsmooth-disable) w_call fontsmooth=disable ;;
    fontsmooth-gray) w_call fontsmooth=gray ;;
    fontsmooth-rgb) w_call fontsmooth=rgb ;;
    glsl-disable) w_call glsl=disabled ;;
    glsl-enable) w_call glsl=enabled ;;
    ie6_full) w_call ie6 ;;
    jscript) w_call wsh56js ;;            # FIXME: use wsh57 instead?
    npm-repack) w_call npm=repack ;;
    oss) w_call sound=oss ;;
    psm=off) w_call psm=disabled ;;
    psm=on) w_call psm=enabled ;;
    python) w_call python26 ;;
    python-comtypes) w_call python26_comtypes ;;
    vbrun60) w_call vb6run ;;
    vcrun2005sp1) w_call vcrun2005 ;;
    vcrun2008sp1) w_call vcrun2008 ;;
    vsm-hard) w_call vsm=hardware ;;
    wsh56) w_call wsh57 ;;
    xlive) w_call gfw ;;

    # Normal verbs, with metadata and load_ functions
    *)
        if winetricks_metadata_exists $1
        then
            w_call "$1"
        else
            echo Unknown arg $1
            winetricks_usage
            exit 1
        fi
        ;;
    esac
}

if ! test "$WINETRICKS_LIB"
then
    # If user opted out, save that preference now.
    winetricks_stats_save

    # If user specifies menu on commandline, execute that command, but don't commit to commandline mode
    # FIXME: this code is duplicated several times; unify it
    if echo "$WINETRICKS_CATEGORIES" | grep -w "$1" > /dev/null
    then
        WINETRICKS_CURMENU=$1
        shift
    fi

    case "$1" in
    volnameof=*)
        # Debug code.  Remove later?
        # Since linux's volname command can't handle dvds, winetricks has its own,
        # implemented using dd, old gum, and some string I had laying around.
        # You can try it like this:
        #  winetricks volnameof=/dev/sr0
        # or
        #  winetricks volnameof=foo.iso
        # This will read the volname from the given image and put it to stdout.
        winetricks_volname ${1#volnameof=}
        ;;
    "")
        # GUI case
        # No non-option arguments given, so read them from GUI, and loop until user quits
        winetricks_detect_gui
        winetricks_detect_sudo
        while true
        do
            case $WINETRICKS_CURMENU in
            main) verbs=`winetricks_mainmenu` ;;
            prefix)
                verbs=`winetricks_prefixmenu`;
                # Cheezy hack: choosing type of package in prefix menu == whether to isolate.
                case "$verbs" in
                apps|benchmarks|games) WINETRICKS_OPT_SHAREDPREFIX=0 ;;
                *)     WINETRICKS_OPT_SHAREDPREFIX=1 ;;
                esac
                # Cheezy hack #2: choosing 'attended' or 'unattended' leaves you in same menu
                case "$verbs" in
                attended) winetricks_set_unattended 0 ; continue;;
                unattended) winetricks_set_unattended 1 ; continue;;
                esac
                ;;
            settings) verbs=`winetricks_settings_menu` ;;
            *) verbs="`winetricks_showmenu`" ;;
            esac

            if test "$verbs" = ""
            then
                # "user didn't pick anything, back up a level in the menu"
                case "$WINETRICKS_CURMENU"-"$WINETRICKS_OPT_SHAREDPREFIX" in
                apps-0|benchmarks-0|games-0|main-*) WINETRICKS_CURMENU=prefix ;;
                prefix-*) break ;;
                *)    WINETRICKS_CURMENU=main ;;
                esac
            elif echo "$WINETRICKS_CATEGORIES" | grep -w "$verbs" > /dev/null
            then
                WINETRICKS_CURMENU=$verbs
            else
                winetricks_stats_init
                # Otherwise user picked one or more real verbs.
                case "$verbs" in
                prefix=*)
                    # prefix menu is special, it only returns one verb, and the
                    # verb can contain spaces
                    execute_command "$verbs"
                    # after picking a prefix, want to land in main.
                    WINETRICKS_CURMENU=main ;;
                *)
                    for verb in $verbs
                    do
                        execute_command "$verb"
                    done
                    case "$WINETRICKS_CURMENU"-"$WINETRICKS_OPT_SHAREDPREFIX" in
                    prefix-*|apps-0|benchmarks-0|games-0) 
                        # After installing isolated app, return to prefix picker
                        WINETRICKS_CURMENU=prefix
                        ;;
                    *)
                        # Otherwise go to main menu.
                        WINETRICKS_CURMENU=main
                        ;;
                    esac
                    ;;
                esac
            fi
        done
        ;;
    *)
        winetricks_stats_init
        # Commandline case
        winetricks_detect_sudo
        # User gave commandline arguments, so just run those verbs and exit
        for verb
        do
            case $verb in
            *.verb)
                # Load the verb file
                case $verb in
                */*) . $verb ;;
                *) . ./$verb ;;
                esac
                # And forget that the verb comes from a file
                verb="`echo $verb | sed 's,.*/,,;s,.verb,,'`"
                ;;
            esac
            execute_command "$verb"
        done
        ;;

    esac

    winetricks_stats_report
fi
