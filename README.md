# CF-Installer
These scripts help to create a bootable cf-drive for brocade switches on linux machines.

Please read the pdf-document "How to install the brocade OS on an empty CF drive.pdf"

# P.S.
1)You need to create partitions on a Compact Flash Drive using the fdisk utility!
Disk partitioning must begin with sector 63. To do this, when creating the first partition, use the command:
terminal$ fdisk -c=dos -u=cylinders /dev/sda

2)Partitions must be formatted with a block size of 4k:
terminal& mkfs -t ext3 -b 4096 /dev/sda1

3)A brief description of the algorithm for calculating the CRC-32 checksum for the FabricOS kernel map-file.
The map-file contains the CRC-32 checksum of the map-file written to the CF. The checksum depends on the sector-by-sector position of the map-file on the CF. If we calculate the checksum of all lines (bytes), except the line with the checksum, invert the resulting value and take the last byte, then we will get the checksum of the map-file in which the same checksum is written. The algorithm is similar to CRC-32K2 (Koopman {1,1,30}).

4)The first time you successfully load the OS, you need to reflash the device to the version loaded on CF. To do this, you need to log in as root(password:fibranne). Use the command: firmwarecleaninstall.

5)Equipment licenses are stored in the following files:
/etc/Fabos/license/licensesdb
/etc/Fabos/license/licenses
Theoretically, on a damaged device they can be detected by HEX-headers.
