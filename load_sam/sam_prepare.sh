

--- transfer the bam file from CG to paradigm4 ftp servers ---

a key file is provided to CG: id_storage

transfer is initiated at CG:

[sciotlos@lx-research05 P4_bam] $ scp -i id_storage ./GS000038929-ASM.normal.sort.bam
 storage@access.paradigm4.com

the file arrived at Paradigm4:

Jasons-MacBook-Pro:Downloads admin$ ssh -i ./id_storage storage@access.paradigm4.com ls -lh
total 325G
drwxrwxrwx. 3 storage storage 4.0K Jan  4 14:42 @eaDir
-rwxrwxr-x. 1 storage storage 325G Jan  7 00:47 GS000038929-ASM.normal.sort.bam
-rw-rw-r--. 1 storage storage 303K Jan  4 15:21 tests.log
-rw-r--r--. 1 storage storage    4 Jan  5 17:34 test.txt


--- mount the bam disk to VB ---

install NFS client on VB(ubuntu 14.04)

$ sudo apt-get install nfs-common
root@ubuntu1404vm:~# dpkg --status nfs-common
Package: nfs-common
Status: install ok installed
Priority: standard
Section: net
Installed-Size: 729
.....



dns server is 10.0.20.7
p4backupstation is 10.0.20.49

on the nfs server side (10.0.20.49), export list config:
/etc/exports
10.0.2.0/24(rw, sync, no_subtree_check, insecure)

on VB

$ showmount 10.0.20.49
Export list for 10.0.20.49:
/volume1/storage 10.0.2.0/24, 10.0.20.0/24
/volume1/diskstation 10.0.20.238, 10.0.20.223, 10.0.20.224

$ sudo mount -t nfs -o nolock 10.0.20.49:/volume1/storage /mnt/temp

mzhang@ubuntu1404vm:~$ ls -thl /mnt/temp/
total 325G
-rwxrwxr-x 1 539 539 325G Jan  7 00:47 GS000038929-ASM.normal.sort.bam
-rw-r--r-- 1 539 539    4 Jan  5 17:34 test.txt
-rw-rw-r-- 1 539 539 303K Jan  4 15:21 tests.log
drwxrwxrwx 3 539 539 4.0K Jan  4 14:42 @eaDir


--- pull out small sam file for testing ---

$ sudo apt-get install samtools

$ dpkg --status samtools
Package: samtools
Status: install ok installed
Priority: optional
Section: science
Installed-Size: 1305
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Architecture: amd64
Version: 0.1.19-1
.....

$ samtools view /mnt/temp/GS000038929-ASM.normal.sort.bam
  |head -10000000 > ~/Paradigm4_labs/my_variant_warehouse/load_sam/cg.sam

mzhang@ubuntu1404vm:~/Paradigm4_labs/my_variant_warehouse/load_sam$ ls -tlh
total 1.2G
-rw-rw-r-- 1 mzhang mzhang 2.0K Jan 13 14:34 sam_prepare.sh
-rw-rw-r-- 1 mzhang mzhang 1.2G Jan 13 14:18 cg.sam







