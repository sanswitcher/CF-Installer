#!/bin/bash
echo "Write names of partitons in Compact Flash(example: sda1 and sda2):"
read 'Partition 1:' sdx1
read 'Partition 2:' sdx2

mkdir /mnt1
mkdir /mnt2
mount /dev/$sdx1 /mnt1
mount /dev/$sdx2 /mnt2
mount hda1_installer3.dsk /mnt

echo "Copy files from hda1_installer3.dsk to partition 1"
cd /mnt
tar cf - . | (cd /mnt1; tar xf -)
sync
echo "Copy files from hda1_installer3.dsk to partition 2"
tar cf - . | (cd /mnt2; tar xf -)
sync

# create bindata.bin and fill it with fixed data
awk 'BEGIN {printf("babeface000000010000000000000000\n")}' | xxd -r -p > /home/a/bindata.bin
#get the number of hdparm entries
hdparm --fibmap /mnt1/boot/zImage.tree.initrd | awk 'FNR>4 {sum++} END {printf("%08x\n",sum)}' | xxd -r -p >> /home/a/bindata.bin
# fill bindata.bin with additional fixed data
awk 'BEGIN {printf("000000000000000000000000\n")}' | xxd -r -p >> /home/a/bindata.bin
#put hdparm numbers into the bindata.bin file
hdparm --fibmap /mnt1/boot/zImage.tree.initrd | awk 'FNR>4 {printf("%08x %08x\n",$2,$4)}' | xxd -r -p >> /home/a/bindata.bin
#fill bindata.bin with zeros until 1k
xxd -ps -c 1 /home/a/bindata.bin | awk '{sum++} END {for (i=sum;i<512;i++) printf("00\n")}' | xxd -r -p >> /home/a/bindata.bin

#produce the checksum
sum="0x"$(xxd -g 4 /home/a/bindata.bin | awk '{$2=strtonum("0x" $2);$3=strtonum("0x" $3);$4=strtonum("0x" $4);$5=strtonum("0x" $5);sum=sum+$2+$3+$4+$5} END {printf("%08x\n",sum)}')
echo "Checksum: $sum"
sum10=$(printf("%u\n",$sum))
(( isum=4294967296-$sum10 ))
isum16=$(printf("%08x\n",$isum))
echo "Inverse checksum: $isum16"
#put the checksum number at the right position into file bindata1.bin
xxd -ps -c 4 /home/a/bindata.bin | awk s=$isum16'{i++;out="$1";if(i==3){printf("%08x\n" ,s)}else{print $out}}' | xxd -r -p > /home/a/bindata1.bin

#put bindata1.bin to the cf-drive
cp /home/a/bindata1.bin /mnt1/boot/zImage.tree.initrd.map
#read the environment numbers 
addr1=$(hdparm --fibmap /mnt1/boot/zImage.tree.initrd.map | awk 'FNR>4 {printf("ATA()0x%08x\n",$2)}')

# create bindata.bin and fill it with fixed data
awk 'BEGIN {printf("babeface000000010000000000000000\n")}' | xxd -r -p > /home/a/bindata.bin
#get the number of hdparm entries
hdparm --fibmap /mnt2/boot/zImage.tree.initrd | awk 'FNR>4 {sum++} END {printf("%08x\n",sum)}' | xxd -r -p >> /home/a/bindata.bin
# fill bindata.bin with additional fixed data
awk 'BEGIN {printf("000000000000000000000000\n")}' | xxd -r -p >> /home/a/bindata.bin
#put hdparm numbers into the bindata.bin file
hdparm --fibmap /mnt2/boot/zImage.tree.initrd | awk 'FNR>4 {printf("%08x %08x\n",$2,$4)}' | xxd -r -p >> /home/a/bindata.bin
#fill bindata.bin with zeros until 1k
xxd -ps -c 1 /home/a/bindata.bin | awk '{sum++} END {for (i=sum;i<1024;i++) printf("00\n")}' | xxd -r -p >> /home/a/bindata.bin

#produce the checksum
sum="0x"$(xxd -g 4 /home/a/bindata.bin | awk '{$2=strtonum("0x" $2);$3=strtonum("0x" $3);$4=strtonum("0x" $4);$5=strtonum("0x" $5);sum=sum+$2+$3+$4+$5} END {printf("%08x\n",sum)}')
echo "Checksum: $sum"
sum10=$(printf("%u\n",$sum)) 
(( isum=4294967296-$sum10 ))
isum16=$(printf("%08x\n",$isum))
echo "Inverse checksum: $isum16"
#put the checksum number at the right position into file bindata1.bin
xxd -ps -c 4 /home/a/bindata.bin | awk s=$isum16'{i++;out="$1";if(i==3){printf("%08x\n" ,s)}else{print $out}}' | xxd -r -p > /home/a/bindata2.bin

#put bindata2.bin to the cf-drive
cp /home/a/bindata2.bin /mnt2/boot/zImage.tree.initrd.map
#read the environment numbers 
addr2=$(hdparm --fibmap /mnt2/boot/zImage.tree.initrd.map | awk 'FNR>4 {printf("ATA()0x%08x\n",$2)}')

echo "Enter the following command on your switch console:"
echo "setenv OSLoader \"$addr1;$addr2\""
echo "setenv OSRootPartition \"hda1;hda2\""
echo "saveenv"
echo "reset"

umount /dev/$sdx1
umount /dev/$sdx2
umount /mnt
