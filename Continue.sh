#!/bin/bash 
#    This program Continues installs Gentoo 2014 & Newer . 
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

eth_card=`ifconfig -a | grep MULTICAST |awk '{ print $1 }' | sed 's/:$//'` 

source /etc/profile 
export PS1="(chroot) $PS1" 

#Installing a portage snapshot 
echo -e "\n Installing \e[1;36mPortage SnapShot\e[0m will take a 3 to 7 Mins.\n" 
emerge-webrsync 

#Setting USE varable in etc/portage/make.conf 
sed -i 's/sse2/sse2 acl afs apm berkdb cdr cups curl cxx dbm dvd dvdr git networkmanager nis odbc perl php python readline smp udev udisks usb xattr truetype jpeg png fontconfig/g' etc/portage/make.conf 

#Set Time zone 
case $ans in 
   1) 
echo "US/Alaska" > /etc/timezone 
   ;; 
   2) 
echo "US/Aleutian" > /etc/timezone 
   ;; 
   3) 
echo "US/Arizona" > /etc/timezone 
   ;; 
   4)  
echo "US/Central" > /etc/timezone 
   ;; 
   5)  
echo "US/East-Indiana" > /etc/timezone 
   ;; 
   6)  
echo "US/Eastern" > /etc/timezone 
   ;; 
   7)  
echo "US/Hawaii" > /etc/timezone 
   ;; 
   8)  
echo "US/Indiana-Starke" > /etc/timezone 
   ;; 
   9)  
echo "US/Michigan" > /etc/timezone 
   ;; 
   10)  
echo "US/Mountain" > /etc/timezone 
   ;; 
   11)  
echo "US/Pacific" > /etc/timezone  
   ;; 
   12) 
echo "US/Pacific-New" > /etc/timezone 
   ;; 
   13) 
echo "US/Samoa" > /etc/timezone 
   ;; 
   *) 
echo "Since I did not understand your request, I set you time zone to Central Time Zone" 
echo "You can change that later manually if that is not what you would like." 
echo "US/Central" > /etc/timezone 

esac 

emerge --config sys-libs/timezone-data 

#Configure locales 
sed -i 's/#en_US ISO-8859-1/en_US ISO-8859-1/g' /etc/locale.gen 
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen 
locale-gen 

eselect locale set 3 
. /etc/profile 
env-update && source /etc/profile 

#--------------->Installing the sources<---------------------------- 
if [ `uname -m` == 'x86_64' ]; then 
  # 64-bit stuff 
     emerge sys-kernel/gentoo-sources 
  else 
  # 32-bit stuff 
    emerge gentoo-sources 
fi 

emerge sys-kernel/genkernel 

#Building kernel 
if [[ $genkern == 'a' ]] || [[ $genkern == 'all' ]] 
then 
#Build kernel with all 

genkernel --lvm --mdadm all 
emerge sys-apps/pciutils 

#Modify /etc/fstab 
cp /etc/fstab{,.default} 

else 
   emerge sys-apps/pciutils 

read -p "Do you want to build the kernel Manually (y)es, or Automatically (n)o? " kans 

   if [[ $kans = 'y' ]] || [[ $kans == 'yes' ]] 
   then 
   #Build kernel manually 

   echo -e "\nDo you need LVM and soft RAID (y)es, (n)o" 
   read -p "Not sure press (y)" ians 

    
   cd /usr/src/linux 
   make menuconfig 

   #Compiling 
   make && make modules_install 
   make install 
   genkernel --menuconfig --install initramfs 
   mkdir -p /boot/efi/boot 
   cp /boot/vmlinuz /boot/efi/boot/bootx64.efi 
    
      if [ $ians == "y" ] || [ $ians == "Y" ] 
      then 
      echo -e "\nWill build with LVM and soft RAID" 
      sleep 3 
      genkernel --menuconfig --lvm --mdadm --install initramfs 
       
      else 
      genkernel --menuconfig --install initramfs 
      #mkdir -p /boot/efi/boot 
      #cp /boot/vmlinuz /boot/efi/boot/bootx64.efi 
      fi 

   else 
   #Build kernel with all 

   genkernel --lvm --mdadm all 
      emerge sys-apps/pciutils 
   #Modify /etc/fstab 

   clear 

   fi 

fi 

cp /etc/fstab{,.default} 

sed -i 's/\/dev\/BOOT/\/dev\/sda2/g' /etc/fstab # Boot 
sed -i 's/\/dev\/ROOT/\/dev\/sda4/g' /etc/fstab # Root partion 
sed -i 's/ext3/ext4/g' /etc/fstab               # Root format 
sed -i 's/\/dev\/SWAP/\/dev\/sda3/g' /etc/fstab # Swap 



sed -i 's/localhost/'$HostName'/g' /etc/conf.d/hostname 
echo -e "dns_domain_lo=\"$Realm\"" > /etc/conf.d/net 

#Configuring the network 
emerge --noreplace net-misc/netifrc 

if [[ $ipans == 's' ]]; then 
echo " 
config_$eth_card=\"$IP_add netmask $NetMask brd $Broadcast\" 
routes_$eth_card=\"default via $Gateway\"" >> /etc/conf.d/net 

echo " 
#Ip address for local hosts 
$IP_add       $HostName.$Realm   $HostName" >> /etc/hosts 

else 
echo " 
config_$eth_card=\"dhcp\"" >> /etc/conf.d/net 
fi 

sed -i 's/localhost/'$HostName.$Realm $HostName localhost'/g' /etc/hosts 


#Updating root password 
echo -e "$password3\n$password4\n" | passwd &> /dev/null 

cd /etc/init.d 
ln -s net.lo net.$eth_card 
rc-update add net.$eth_card default 

#------> Change Root password <--------------------- 
echo -e "password3\npassword4\n" | passwd &> /dev/null 

#------> Install Logging <-------------------------- 
emerge app-admin/syslog-ng 
rc-update add syslog-ng default 

#------> Install Cron daemon <---------------------- 
emerge sys-process/cronie 
rc-update add cronie default 

#------> Install File indexing <-------------------- 
emerge sys-apps/mlocate 

#------> Setup Remote access <-------------------- 
rc-update add sshd default 

if [[ $ipans == "d" ]]; then 
#------> Install DHCP client <---------------------- 
emerge net-misc/dhcpcd 
fi 

#------> Install GRUB2 <---------------------------- 
emerge sys-boot/grub 
mkdir /boot/grub/ 
grub2-install /dev/sda 
grub2-mkconfig -o /boot/grub/grub.cfg 

#------> finish Installing software & return <------ 
#emerge --autounmask-write =net-dns/dnssec-tools-2.1 =app-admin/webmin-1.690 =dev-perl/Authen-Libwrap-0.220.0-r1 =dev-perl/Getopt-GUI-Long-0.930.0-r1 
#dispatch-conf u 
#emerge webmin 
clear 
exit 
