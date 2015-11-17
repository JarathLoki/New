#!/bin/bash 
#    This program installs Gentoo 2014 & Newer. 
#    Remember This wipes out the entire Hard Drive. 
#    Make sure this is what you want to do !!!!!!!!!! 
# 
#    All programs Copyrighted by there respective companies. 
# 
#    Copyright (C) 2014-15  Eric Teeter teetere @ charter.net 
# 
#    This program is free software: you can redistribute it and/or modify 
#    it under the terms of the GNU General Public License as published by 
#    the Free Software Foundation, either version 3 of the License, or 
#    (at your option) any later version. 
# 
#    This program is distributed in the hope that it will be useful, 
#    but WITHOUT ANY WARRANTY; without even the implied warranty of 
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
#    GNU General Public License for more details. 
# 
#    You should have received a copy of the GNU General Public License 
#    along with this program.  If not, see <http://www.gnu.org/licenses/>. 
# 
#    This License only cover this script the software that is installed from 
#    Ubuntu package by this script and they may use other licenses 
#    it is up to the user to verfiy those and approve them. 

#variables to used between scripts 
export genkern password3 password4 ipans IP_add NetMask Broadcast Gateway HostName Realm ans User 
password3=1 
password4=2 

#Number of proccessors plus one to set -j 
NoProc=$(( $(nproc) + 1 )) 
genkern=$1 

if [ `whoami` != "root" ]; then 
   echo "You must run this as root" 
   exit 1 
fi 

#Figure the swap size 
mem=`grep MemTotal /proc/meminfo | awk '{print $2}'` 
swap=`echo "($mem+50)/100+131" | bc` #ending postion for Swap partion 
clear 


echo -e "\e[1;31mRemoving\e[0m the old partions and putting on new ones" 
echo -e "\e[41m\e[1;33m Caution !!! \e[1;36mYou are about to loose all info on this drive \e[0m" 
read -p "Do you still want to partion this drive (y,n)? " par 
if [ "${par:0:1}" == "n" ] || [ "${par:0:1}" == "N" ] 
then exit 1 
fi 

# Remove each partition 
for v_partition in $(parted -s /dev/sda print|awk '/^ / {print $1}') 
do 
   parted -s /dev/sda rm ${v_partition} 
done 

#Make sure that you remove all data 
parted -s /dev/sda -- mkpart primary 1 -1 
parted -s /dev/sda mklabel msdos 
mkfs.vfat /dev/sda1 
parted -s /dev/sda rm 1 

#Setup Hard Drive 
parted -s /dev/sda mklabel gpt 
parted -s /dev/sda unit mib 
parted -s /dev/sda mkpart primary 1 3 
parted -s /dev/sda name 1 grub 
parted -s /dev/sda toggle 1 bios_grub 
parted -s /dev/sda mkpart primary 3 131 
parted -s /dev/sda name 2 boot 
parted -s /dev/sda toggle 2 boot 
parted -s /dev/sda mkpart primary linux-swap 131 $swap 
parted -s /dev/sda name 3 swap 
parted -s /dev/sda -- mkpart primary $swap -1 
parted -s /dev/sda name 4 rootfs 
mkfs.ext2 -F /dev/sda2 
mkfs.ext4 -F /dev/sda4 
mkswap /dev/sda3 
swapon /dev/sda3 

#Mount 
mount /dev/sda4 /mnt/gentoo 
mkdir /mnt/gentoo/boot 
mount /dev/sda2 /mnt/gentoo/boot 
cd /mnt/gentoo 
clear 

echo -e "Please change the root password" 
while [ -z "$password3" ] || [ "$password3" != "$password4" ] 
do 
echo -en "New password: " 
read -s  password3 
echo -en "\nRetype new password: " 
read -s password4 

 if [ "$password3" == "$password4" ] && [ -n "$password3" ] 
 then 
   echo -e "\npasswd: password updated successfully\n" 
   break  # Skip entire rest of loop. 
 fi 

#No null string 
 if [ -z "$password3" ] 
 then 
 echo -e "\nNo \e[4;31mnull sting or blank\e[0m passwords allowed!" 
 else 
 echo -e "\nSorry, passwords do not match." 
 fi 

done 

#Setting IP address 

echo -en "Would you like \e[1;36mStatic\e[0m or \e[0;32mDynamic\e[0m address (s,d)? " 
read ipans 
if [[ $ipans == "s" ]]; then 
echo -en "                What is the \e[0;32mStatic\e[0m IP address? " 
read IP_add 
echo -en "                          What is the \e[0;32mNetmask\e[0m? " 
read NetMask 
echo -en "                What is the \e[0;32mBroadcast\e[0m address? " 
read Broadcast 
echo -en "What is the default \e[0;32mGateway\e[0m or \e[0;32mRouter\e[0m address? " 
read Gateway 
fi 
echo "" 
echo -en "What is the \e[0;92mname\e[0m of this computer? " 
read HostName 
echo -en "What is the \e[0;92mRealm\e[0m (i.e. home.com)? " 
read Realm 

#Set Time zone 
clear 
echo -e "What is your Time Zone\nType in number below\n" 
echo -e "1)  Alaska  \n2)  Aleutian  \n3)  Arizona  \n4)  Central  \n5)  East-Indiana  \n6)  Eastern  \n7)  Hawaii  \n8)  Indiana-Starke  \n9)  Michigan  \n10) Mountain  \n11) Pacific  \n12) Pacific-New   \n13) Samoa" 
read -p "Your Zone is? " ans 

re='^[0-9]+$' 
if ! [[ $ans =~ $re ]] && (( ans < 1)) || (( ans > 13)); then 
echo "Since I did not understand your request, I set you time zone to Central Time Zone" 
echo "You can change that later manually if that is not what you would like." 
ans=4 
fi 

echo "" 

#Download tarball 
if [ `uname -m` == 'x86_64' ]; then 
  # 64-bit stuff 
wget --glob=on ftp://gentoo.cites.uiuc.edu/pub/gentoo/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-2*.tar.bz2 
wget --glob=on ftp://gentoo.cites.uiuc.edu/pub/gentoo/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-2*.tar.bz2.D* 

echo -e "Getting \e[1;34mkeys\e[0m and \e[1;34mverify downloaded\e[0m files, will take a few mins." 
#Get & test Keys 
gpg --keyserver subkeys.pgp.net --recv-keys 0xBB572E0E2D182910 &> key 
gpg --verify stage3-amd64-*.tar.bz2.DIGESTS.asc &> ver 
test=`grep $(awk -F'key ID' '{ print $2 }' ver) key` 
   if [[ $test != "" ]]; then 
   echo -e "\n\e[42mThe key has been verifyed\e[0m\n" 
   else 
   echo -e "\n\e[41mThe key can not be verifyed, Need to stop!\e[0m\n" 
   rm -f stage3-*.tar.* 
        exit 1 
        fi 


#Check integrity 
ver_W=$(grep $(openssl dgst -r -whirlpool stage3-amd64-*.tar.bz2 | awk '{print $1}') stage3-amd64-*.tar.bz2.DIGESTS.asc) 
ver_s=$(grep $(openssl dgst -r -sha512 stage3-amd64-*.tar.bz2 | awk '{print $1}') stage3-amd64-*.tar.bz2.DIGESTS.asc) 

        if [[ $ver_W != "" ]] && [[ $ver_s != "" ]] 
        then 

        echo -e "\n\e[42mThe integrity of files have been verifyed\e[0m\n" 
        else 

        echo -e "\n\e[41mThe integrity of files can not be verifyed, Need to stop!\e[0m\n" 
   rm -f stage3-*.tar.* 
        exit 1 
        fi 

else 
  # 32-bit stuff 
wget --glob=on ftp://gentoo.cites.uiuc.edu/pub/gentoo/releases/x86/autobuilds/current-stage3-i686/stage3-i686-2*.tar.bz2 
wget --glob=on ftp://gentoo.cites.uiuc.edu/pub/gentoo/releases/x86/autobuilds/current-stage3-i686/stage3-i686-2*.tar.bz2.D* 
ver_W=$(grep $(openssl dgst -r -whirlpool stage3-i686-*.tar.bz2 | awk '{print $1}') stage3-i686-*.tar.bz2.DIGESTS.asc) 
ver_s=$(grep $(openssl dgst -r -sha512 stage3-i686-*.tar.bz2 | awk '{print $1}') stage3-i686-*.tar.bz2.DIGESTS.asc) 

echo -e "Getting \e[1;34mkeys\e[0m and \e[1;34mverify downloaded\e[0m files, will take a few mins." 
#Get & test Keys 
gpg --keyserver subkeys.pgp.net --recv-keys 0xBB572E0E2D182910 &> key 
gpg --verify stage3-i686-*.tar.bz2.DIGESTS.asc &> ver 
test=`grep $(awk -F'key ID' '{ print $2 }' ver) key` 
   if [[ $test != "" ]]; then 
   echo -e "\n\e[42mThe key has been verifyed\e[0m\n" 
   else 
   echo -e "\n\e[41mThe key can not be verifyed, Need to stop!\e[0m\n" 
        rm -f stage3-*.tar.* 
   exit 1 
        fi 


#Check integrity 
        if [ $ver_W != "" ] && [ $ver_s != "" ] 
        then 

        echo -e "\e[42mThe the integrity of files have been verifyed\e[0m" 
        else 

        echo -e "\e[41mThe the integrity of files can not be verifyed, Need to stop!\e[0m" 
        rm -f stage3-*.tar.* 
   exit 1 
        fi 

fi 

sleep 3 #just to see answers before the roll off the screen 

tar xvjpf stage3-*.tar.bz2 
rm -f stage3-*.tar.bz2 
rm -f stage3-*.tar.bz2.D* 
rm -f key 
rm -f ver 


#Mounting the necessary filesystems 
mount -t proc proc /mnt/gentoo/proc 
mount --make-rprivate --rbind /sys /mnt/gentoo/sys 
mount --make-rprivate --rbind /dev /mnt/gentoo/dev 

mkdir /mnt/gentoo/usr/portage 
sed -i 's/${CFLAGS}\"/${CFLAGS}\"\nMAKEOPTS=\"-j'$NoProc'\"/g' /mnt/gentoo/etc/portage/make.conf 
sed -i 's/-O2 -pipe/-march=native -O2 -pipe/g' /mnt/gentoo/etc/portage/make.conf 

echo -e "\nGetting mirrors for your slection for \e[0;32mDownload\e[0m this \nmay take 1 to 5 min depending on Internet & Hardware\n\nPlease select the closest site to speed up your Downloads\n" 

mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf 
clear 
echo -e "\nGetting mirrors for your slection for \e[0;94mRsync\e[0m this \nmay take 1 to 5 min depending on Internet & Hardware\n\nPlease select the closest site to speed up your Rsync\n" 
mirrorselect -i -r -o >> /mnt/gentoo/etc/portage/make.conf 
clear 

cp -L /etc/resolv.conf /mnt/gentoo/etc/ 
mount --rbind /sys /mnt/gentoo/sys 
mount --make-rslave /mnt/gentoo/sys 
mount --rbind /dev /mnt/gentoo/dev 
mount --make-rslave /mnt/gentoo/dev 

mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm 

#Entering the new environment 
cp /mnt/key/Continue /mnt/gentoo/tmp/Continue 

# ----------------------> Entering chroot environment <------------------------------ 

echo -e "\nEntering chroot environment \n" 
chroot /mnt/gentoo /bin/bash /tmp/./Continue 

# ----------------------> Return from chroot environment <--------------------------- 

#Change Root password 
echo -e "$password3\n$password4\n" | passwd &> /dev/null 
cd / 
rm -fr /tmp 
mkdir tmp 
#returning from Continue 
echo -e "They system will \e[1;31mreboot\e[0m in 15 seconds!" 
rm -f /mnt/gentoo/tmp/Continue 
umount -l /mnt/gentoo/dev{/shm,/pts,} 
umount /mnt/gentoo{/boot,/sys,/proc,} 
fuser -c /dev/sda 
umount /mnt/key 
fuser -c /mnt/key 
sleep 15 
reboot 