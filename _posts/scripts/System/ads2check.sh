#/bin/sh
fsck -t ext2fs /dev/ad4s2 
#fsck -y /dev/ad4s1 &&
fsck -y /dev/ad4s3 
echo "HAIL TO THE KING, BICHES!!!!" 
reboot
