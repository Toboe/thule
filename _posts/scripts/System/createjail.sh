#!/bin/bash
jail_dir="/home/jails/$1jail"

echo ${jail_dir}
mkdir -p ${jail_dir}

cd /usr/src

#make buildworld
make installworld DESTDIR=${jail_dir}
#cd /usr/src/etc
make distribution DESTDIR=${jail_dir}
#mount -t devfs devfs ${jail_dir}/dev
echo ""
echo "Create jail $1 successfully complite"
echo ""
exit 64







