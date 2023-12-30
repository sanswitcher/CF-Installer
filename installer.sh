#!/bin/bash
# fixed values: ftp-protocol to transfer the files
#               destination filename: hda1_installer3.dsk
#               PLATFORM=SWBD34
FS='ext3'
echo "Write number of SWBD platform. Exemple: SWBD109. See: switch-types-blads-ids-product-names.pdf"
read 'Platform:' PLATFORM
truncate -s 500M hda1_installer3.dsk
TARGET_DEV=hda1_installer3.dsk
mke2fs -F -g32768 -b4096 -j $TARGET_DEV
PROTOCOL=ftp
read -p "Enter ipaddr: " ipaddr
read -p "Enter Username: " user
read -s -p "Enter Password: " pw
echo
ACCOUNT=$user:$pw
read -p "Enter Sourcepath: " SOURCE_PATH
#
TMPMNT='/mnt'
TYPE=release
mount $TARGET_DEV $TMPMNT
/bin/mkdir -p /$PLATFORM
# SOURCE_PATH=192.168.50.57/admin/brocade/v7.4.2f
WGET_PATH=$PROTOCOL://$ACCOUNT@$ipaddr/$SOURCE_PATH
echo $WGET_PATH
wget -a /var/log/wget_clean.log -T 60 --tries=3 -N -nH -P /$PLATFORM $WGET_PATH/platform_names
wget -a /var/log/wget_clean.log -T 60 --tries=3 -N -nH -P /$PLATFORM $WGET_PATH/$PLATFORM/release.plist
mount -t $FS $TARGET_DEV /mnt
mkdir /mnt/proc
mkdir /mnt/mnt
mkdir /mnt/lib
mkdir /mnt/lib/modules
ln -sf default /mnt/lib/modules/2.6.14.2
mkdir /mnt/etc
wget -a /var/log/wget_clean.log -T 60 --tries=3 -N -nH -P /$PLATFORM $WGET_PATH/$PLATFORM/group
mkdir -p /mnt/fabos/share
mkdir -p /mnt/fabos/lib
mkdir /mnt/dev
mkdir -p /mnt/var/lib/rpm
rpm --root /mnt --initdb

function putit()
{
#  echo "complete Filename" $1
  VALUE="$1"
  fn=${VALUE##*/}
  path=${VALUE%/*}
#  echo $path und $fn
wget -a /var/log/wget_clean.log -T 60 --tries=3 -N -nH -P /mnt/$PLATFORM $WGET_PATH/$path/$fn
cw=`pwd`
cd /mnt
rpm2cpio /mnt/$PLATFORM/$fn | cpio -idm --make-directories --unconditional --extract-over-symlinks
cd $cw
}

tail -c +289 /$PLATFORM/release.plist > /$PLATFORM/release.plist1
filename=/$PLATFORM/release.plist1
echo filename: $filename

n=1
while read line
do
  echo Extracting $line
  putit $line

done < $filename

    echo "Updating the file system table..."

    case "$PLATFORM" in
    "SWBD141" | "SWBD142" |"SWBD148" | "SWBD156" | "SWBD157" | "SWBD158")
    cat > ${TMPMNT}/etc/fstab << EOF
/dev/root   /       $FS rw,noatime  0 0
none        /proc       proc    defaults    0 0
none        /sys        sysfs   defaults    0 0
none        /dev/pts    devpts  mode=620    0 0
EOF

;;
*)
cat > ${TMPMNT}/etc/fstab << EOF
/dev/root	/		$FS	rw,noatime	0 0
none		/proc		proc	defaults	0 0
none		/dev/pts	devpts	mode=620	0 0
EOF
;;
    esac

    echo "Fixing up pdm wrong directory for rcp"
    ln -sf ../usr/bin/rcp /mnt/bin/rcp

    echo "Fixing up /etc/modules.conf..."

    cat > /mnt/etc/modules.conf << EOF
keep
path=/fabos/modules
alias eth1 eepro100
EOF

echo "Fixing fabos/sbin/sname"
    if [ ! -x /mnt/fabos/sbin/sname ] ; then
          ln -sf ../bin/sname /mnt/fabos/sbin/sname
    fi

echo "Add some important empty files"  
touch /mnt/etc/fabos/upgrade_status1
touch /mnt/etc/fabos/licenses
touch /mnt/fabos/share/release
ln -s default /mnt/lib/modules/preferred
mkdir /mnt/var/config
mkdir /mnt/var/tmp

echo "ssh-keygen"
ssh-keygen -q -b 1024 -t rsa -f /mnt/etc/ssh_host_rsa_key -N ''
chmod 600 /mnt/etc/ssh_host_rsa_key
chmod 600 /mnt/etc/ssh_host_rsa_key.pub
ssh-keygen -q -t dsa -f /mnt/etc/ssh_host_dsa_key -N ''
chmod 600 /mnt/etc/ssh_host_dsa_key
chmod 600 /mnt/etc/ssh_host_dsa_key.pub
ssh-keygen -q -t ecdsa -f /mnt/etc/ssh_host_ecdsa_key -N ''
chmod 600 /mnt/etc/ssh_host_ecdsa_key
chmod 600 /mnt/etc/ssh_host_ecdsa_key.pub

echo "Removing temp files"
rm -Rf /mnt/home/*
rm -Rf /mnt/home.??*
rmdir /mnt/home 2> /dev/null
rm  -Rf /mnt/$PLATFORM/*
rmdir /mnt/$PLATFORM

echo Unmounting $TARGET_DEV\; Please wait!
umount /mnt
