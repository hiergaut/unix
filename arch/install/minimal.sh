#! /bin/bash -e


#TODO play song at each user input 

bar() {
	tailleBar=$(tput cols)
	part=$(expr $tailleBar / 4)

	# let "middleBar=$tailleBar/2"
	# middleBar=$(expr $tailleBar / 2) || sleep 0

	str=$1
	lenStr=${#str}
	# let "moitieLenMenu=$lenMenu/2"
	# moitieLenMenu=$(expr $lenStr / 2) || sleep 0
	# let "impaire=$lenStr%2"
	# impaire=$(expr $lenStr % 2) || sleep 0

	# let "bordureInf=$middleBar -$moitieLenMenu"
	bordureInf=$(expr $part - $lenStr) || sleep 0
	# let "bordureSup=$middleBar +$moitieLenMenu"
	# bordureSup=$(expr $middleBar + $moitieLenMenu) || sleep 0

	echo -ne "\\033[1;44m"
	for i in $(seq 1 $bordureInf); do
		echo -n ' '
	done
	# echo -en "\\033[0m"


	# echo -en "\\033[1;33m"
	# echo -n ' '
	echo -n "$str  "
	# echo -n ' '
	# echo -en "\\033[0m"

	# let "lenSup=$tailleBar -$bordureSup"
	# lenSup=$(expr $tailleBar - $bordureSup) || sleep 0
	cmd=$(cat /proc/loadavg)
	lenDate=${#cmd}

	echo -en "\\033[0m"
	bordureSup=$(expr $tailleBar - $part - 2 - $lenDate)
	for i in $(seq 1 $bordureSup); do
		echo -n ' '
	done

	# if [ $impaire -eq 0 ]; then
	#     echo -en '+'
	# fi
	#
	echo -en "\\033[1;34m"
	echo $cmd
	echo -e "\\033[0m"
}

barStatus() {
	tailleBar=$(tput cols)
	middle=$(expr $tailleBar / 2)

	# let "middleBar=$tailleBar/2"
	# middleBar=$(expr $tailleBar / 2) || sleep 0

	str=$1
	lenStr=${#str}
	# let "moitieLenMenu=$lenMenu/2"
	# moitieLenMenu=$(expr $lenStr / 2) || sleep 0
	# let "impaire=$lenStr%2"
	# impaire=$(expr $lenStr % 2) || sleep 0

	# let "bordureInf=$middleBar -$moitieLenMenu"
	bordureInf=$(expr $middle - $lenStr / 2 - 2) || sleep 0
	# let "bordureSup=$middleBar +$moitieLenMenu"
	# bordureSup=$(expr $middleBar + $moitieLenMenu) || sleep 0

	# echo -ne "\\033[1;7;32m"
	for i in $(seq 1 $bordureInf); do
		echo -n ' '
	done
	# echo -en "\\033[0m"


	# echo -n ' '
	echo -en "\\033[1;44m"
	echo -n " $str "
	# echo -n ' '
	echo -e "\\033[0m"
}

print_color() {
	echo -e "\\033[$2"m"$1\\033[0m"
}

is_efi() {
	if [ -d /sys/firmware/efi/ ]
	then
		print_color "EFI DETECTED" "1;32"
		return 0
	else
		print_color "BIOS DETECTED" "1;32"
		return 1
	fi
}

born="/mnt"
appTitle="Archlinux Installer"
temp="/tmp/minimal"
efi_rep="$born/boot/efi"
# DIALOG=${DIALOG=dialog}
DIALOG=dialog

mkdir -pv $temp
if [ ! -e $temp/start ]; then
	echo $(date +%s) > $temp/start
fi

# umount -R /mnt && sleep 0

00_keyboard() {
	# items=$(localectl list-keymaps)
	#TODO auto select with the current keymap
	# can't find with localctl current keymap :(
	# exit
	pacman -Sy --noconfirm dialog

	items=$(find /usr/share/kbd/keymaps/ -type f -printf "%f\n" | awk -F. '{print $1}' | sort)
	options=()
	for item in $items; do
		options+=("$item" "")
	done
	# key=$($DIALOG --backtitle "$appTitle" --title "Keymap Selection" --menu "" 40 40 30 \
	key=$($DIALOG --backtitle "$appTitle" --title "Keymap Selection" --default-item "dvorak-programmer" --menu "" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)

	print_color "loadkeys $key" 33
	loadkeys $key
	echo "$key" > $temp/keyboard
}

05_timeZone() {
	if [ -e $temp/yourCountry ]; then
		yourCountry=$(cat $temp/yourCountry)
	else
		# yourCountry=$(curl -s https://whatismycountry.com/ | grep 'your country is' | sed 's/.*your country is \([A-Z][a-z]*\).*/\1/')
		yourCountry=$(curl ipconfig.io/country)
		echo $yourCountry > $temp/yourCountry
	fi

	# allCap="$temp/allCapital"
	# if [ ! -e $allCap ]; then
	#     curl https://en.wikipedia.org/wiki/List_of_national_capitals_in_alphabetical_order > $temp/allCapital
	# fi
	# #TODO only capital but not others :(
	# items=$(cat $allCap | grep -A 2 "$yourCountry\">$yourCountry" | sed 's/.*title=\"\([A-Za-z ]*\)\".*/\1/' | grep '^[A-Z].*' | grep -v "$yourCountry")
	#
	# # items=$(ls -l /usr/share/zoneinfo/ | grep '^d' | gawk -F':[0-9]* ' '/:/{print $2}')
	# options=()
	# # for item in $items; do
	#     # options+=("$item" "")
	# # done
	# # echo $items | while read item; do
	#     # options+=("$item" "")
	# # done
	# items=$(echo "$items" | tr '\n' '$' | sed 's/\$/ \$ /g')
	#
	# str=""
	# for item in $items; do
	#     if [ "$item" = "\$" ]; then
	#         options+=("$str" "")
	#         str=""
	#     else
	#         if [ "$str" ]; then
	#             str="$str $item"
	#         else
	#             str="$item"
	#         fi
	#     fi
	# done
	#
	# # timezone=$($DIALOG --backtitle "$appTitle" --title "Time zone" --default-item "$yourContry" --menu "" 0 0 0 \
	# timezone=$($DIALOG --backtitle "$appTitle" --title "Select your timezone" --menu "$yourCountry" 0 0 0 \
	#     "${options[@]}" \
	#     3>&1 1>&2 2>&3)
	#
	# if [ ! "$?" = "0" ]; then
	#     return 1
	# fi
	#
	# cd /usr/share/zoneinfo/
	# timezone=$(find . -name "$timezone" | egrep -v 'posix|right' | cut --complement -c1-2)
	# if [ -z $timezone ]; then
	#     echo "get timezone failed"
	#     exit 3
	# fi
	# cd -

	# items=$(ls /usr/share/zoneinfo/$timezone/)
	# options=()
	# for item in $items; do
	# options+=("$item" "")
	# done
	# # timezone=$timezone/$($DIALOG --backtitle "$appTitle" --title "Time zone" --menu "" 40 30 30 \
	# timezone=$timezone/$($DIALOG --backtitle "$appTitle" --title "Time zone" --menu "" 0 0 0 \
	# "${options[@]}" \
	# 3>&1 1>&2 2>&3)

	# capital=$(curl https://raw.githubusercontent.com/samayo/country-json/master/src/country-by-capital-city.json | grep -A 1 "\"$yourCountry\"" | tail -n1 | awk '{print $2}')

	capital=$(python << END
import urllib.request, json 

with urllib.request.urlopen("https://raw.githubusercontent.com/samayo/country-json/master/src/country-by-capital-city.json") as url:
	data = json.loads(url.read().decode())
	for i in data:
		if i['country'] == '$yourCountry':
			print(i['city'])
			break
END
)

cd /usr/share/zoneinfo/
timezone=$(find . -name "$capital" | egrep -v 'posix|right' | cut --complement -c1-2)

print_color "timedatectl set-ntp true" 33
timedatectl set-ntp true

print_color "timedatectl set-timezone $timezone" 33
timedatectl set-timezone $timezone

echo "$timezone" > $temp/timeZone
}

10_format() {
	#TODO select device horrible
	items=$(lsblk | grep disk | awk '{print $1}' | sort)
	options=()
	for item in $items; do
		options+=("$item" "")
	done

	# key=$($DIALOG --backtitle "$appTitle" --title "Keymap Selection" --menu "" 40 40 30



	# device=$($DIALOG --backtitle "$appTitle" --title "Select device to install" --menu "$(echo && lsblk -S -e 11 && echo)" 0 0 0 \
	# device=$($DIALOG --backtitle "$appTitle" --title "Select device to install" --menu "$(echo && lsblk -d && echo)" 0 0 0 \
	# device=$($DIALOG --backtitle "$appTitle" --title "Select device to install" --menu "$(echo && lsblk -S && echo)" 0 80 0 "${options[@]}" 3>&1 1>&2 2>&3)
	device=$($DIALOG --backtitle "$appTitle" --title "Select device to install" --menu "$(echo && lsblk -f && echo)" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)

	if [ $device = "nvme0n1" ]; then
		post="p"
	fi
	device="/dev/$device"

	#TODO maybe 50G for root filesystem


	if is_efi
	then
		# if ($DIALOG --backtitle "$appTitle" --title "Format EFI" --yesno ""$device"1   512M   EFI System\n"$device"2   40G    Linux filesystem\n"$device"3   *G     Linux filesystem\n\n\n                                 Commit ?" 0 80)
		if ($DIALOG --backtitle "$appTitle" --title "Format EFI" --yesno "\n"$device$post"1    512M    EFI System\n"$device$post"2  512M-100G  Linux filesystem /\n"$device$post"3  100G-100%  Linux filesystem /home\n\n\n                Commit ?" 0 0)
		# if ($DIALOG --backtitle "$appTitle" --title "Format EFI" --yesno "\n"$device$post"1    512M    EFI System\n"$device$post"2  512M-50%  Linux filesystem /\n"$device$post"3  50%-100%  Linux filesystem /home\n\n\n                Commit ?" 0 0)
		then
			echo -e "\\033[33mparted $device mklabel gpt\\033[0m"
			parted $device mklabel gpt -ms
			echo -e "\\033[33mparted $device mkpart ESP fat32 1MiB 513Mib\\033[0m"
			parted $device mkpart ESP fat32 1MiB 513Mib -ms
			echo -e "\\033[33mparted $device set 1 boot on\\033[0m"
			parted $device set 1 boot on -ms
			echo

			rootSize=100.5
			echo -e "\\033[33mparted $device mkpart primary ext4 513Mib "$rootSize"Gib\\033[0m"
			# echo -e "\\033[33mparted $device mkpart primary ext4 513Mib 50%\\033[0m"
			#TODO maybe 50Gb for root part
			parted $device mkpart primary ext4 513Mib "$rootSize"Gib -ms
			# parted $device mkpart primary ext4 513Mib 50% -ms

			echo -e "\\033[33mparted $device mkpart primary ext4 "$rootSize"Gib 100%\\033[0m"
			# echo -e "\\033[33mparted $device mkpart primary ext4 50% 100%\\033[0m"
			parted $device mkpart primary ext4 "$rootSize"Gib 100% -ms
			# parted $device mkpart primary ext4 50% 100% -ms
			echo

			#TODO bad device number p1 p2 p3 not 11 22 33, find device name
			echo -e "\\033[33mmkfs.vfat -F32 "$device$post"1\\033[0m"
			mkfs.vfat -F32 "$device$post"1 <<< y
			echo -e "\\033[33mmkfs.ext4 "$device$post"2\\033[0m"
			mkfs.ext4 "$device$post"2 <<< y
			echo -e "\\033[33mmkfs.ext4 "$device$post"3\\033[0m"
			mkfs.ext4 "$device$post"3 <<< y
		else
			return 1
		fi
	else
		if ($DIALOG --backtitle "$appTitle" --title "Format DOS" --yesno "\n"$device$post"1   512M   Linux filesystem /boot\n"$device$post"2   40G    Linux Filesystem /\n"$device$post"3   *G     Linux filesystem /home\n\n\n             Commit ?" 0 0)
		then
			echo -e "\\033[33mparted $device mklabel dos\\033[0m"
			parted $device mklabel msdos -ms
			# parted $device mklabel gpt -ms
			echo -e "\\033[33mparted $device mkpart ext2 1MiB 513Mib\\033[0m"
			parted $device mkpart primary ext2 1MiB 513Mib -ms
			echo -e "\\033[33mparted $device set 1 boot on\\033[0m"
			parted $device set 1 boot on -ms
			# parted $device set 1 bios-grub on -ms

			echo -e "\\033[33mparted $device mkpart primary ext4 513Mib 40.5Gib\\033[0m"
			parted $device mkpart primary ext4 513Mib 40.5Gib -ms
			echo -e "\\033[33mparted $device mkpart primary ext4 40.5Gib 100%\\033[0m"
			parted $device mkpart primary ext4 40.5Gib 100% -ms
			echo

			echo -e "\\033[33mmkfs.ext2 "$device$post"1\\033[0m"
			mkfs.ext2 "$device$post"1 <<< y
			echo -e "\\033[33mmkfs.ext4 "$device"2\\033[0m"
			mkfs.ext4 "$device"2 <<< y
			echo -e "\\033[33mmkfs.ext4 "$device"3\\033[0m"
			mkfs.ext4 "$device"3 <<< y
		else
			return 1
		fi
	fi

	print_color "fdisk -l $device" 33
	fdisk -l $device
	echo "$device" > $temp/format
	echo "$post" > $temp/post
}

15_mounting() {
	device=$(cat $temp/format)
	post=$(cat $temp/post)

	# umount -R /mnt && sleep 0

	if is_efi
	then
		#TODO bad device number p1 p2 p3 not 11 22 33, find device name
# born="/mnt"
		mount -v "$device$post"2 $born #root

		mkdir -v $born/home
		mount -v "$device$post"3 $born/home/

# efi_rep="$born/boot/efi"
		mkdir -pv $efi_rep
		# mount -t vfat "$device$post"1 $efi_rep
		mount "$device$post"1 $efi_rep
		# mkdir -v $born/esp
		# mount -v "$device"1 $born/esp/
		# mkdir -pv $born/esp/EFI/arch/
		# mount -v --bind $born/esp/EFI/arch/ $born/boot/
	else
		mount -v "$device$post"2 $born
		mkdir -v $born/home
		mkdir -v $born/boot
		mount -v "$device$post"1 $born/boot/
		mount -v "$device$post"3 $born/home/
	fi

	print_color "df" 33
	df | grep -E "$|$device"
}

20_mirror() {
	yourCountry=$(cat $temp/yourCountry)

	file="/etc/pacman.d/mirrorlist"

	if ! [ -f $file.default ]
	then
		cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.default
	fi



	# items=$(cat /etc/pacman.d/mirrorlist.default | grep '##' | awk '{print $2}' | sort | uniq)
	# options=()
	# for item in $items; do
	#     options+=("$item" "")
	# done
	# # country=$($DIALOG --backtitle "$appTitle" --title "Select Country Mirror" --menu "" 40 40 30 \
	#     country=$($DIALOG --backtitle "$appTitle" --title "Select Country Mirror" --default-item "$yourCountry" --menu "" 0 0 0 \
	#     "${options[@]}" \
	#     3>&1 1>&2 2>&3)



#     head -n 6 $file.default > $file
#     # cat $file
#
#     echo "## $yourCountry" >> $file
#     # cat $file
#
#     cat $file.default | while read line
# do
#     if echo $line | grep $yourCountry > /dev/null
#     then
#         read line
#         echo $line >> $file
#         # echo $line
#     fi
# done
#
	# # pacman-mirrors -g
	# if ! rankmirrors > /dev/null 2>&1; then
	#     mount -o remount,size=4G /run/archiso/cowspace
	#     pacman -Sy --noconfirm pacman-contrib
	# fi
    #
	# print_color "create new file '/etc/pacman.d/mirrorlist' by rankmirrors" 33
	# rankmirrors $file -v | tee /tmp/minimal/rank
	# mv /tmp/minimal/rank $file

	mount -o remount,size=4G /run/archiso/cowspace
	pacman -Sy --noconfirm reflector pacman-contrib
	reflector -c "$yourCountry" -f 12 -l 10 -n 12 --save /etc/pacman.d/reflector.txt
	# cat $file
	rankmirrors -n 12 /etc/pacman.d/reflector.txt > $file
	# fi
}

25_base() {
	start=$(date +%s)


	print_color "install base base-devel" 33
	# time pacstrap $born base base-devel
	# pacstrap $born base base-devel linux linux-firmware
	pacstrap $born base linux linux-firmware
	# pacstrap $born linux #for mkinitcpio
	pacstrap $born dhcpcd #wifi wpa

	pacstrap $born net-tools  #command hostname not found

	#optional
	# pacstrap $born openssh zsh rsync wget dialog vim
	print_color "install wget to post possible download script"
	pacstrap $born wget openssh rsync neovim

	# to download post script installation
	pacstrap $born unison

	# resolve TSC_DATA error before bootloader update
	pacstrap $born intel-ucode  

	pacstrap $born vi



end=$(date +%s)
diff=$(echo $end - $start | bc)
min=$(echo "$diff / 60" | bc)
sec=$(echo "$diff % 60" | bc)
print_color "total base install time : $min min and $sec sec" "1;33"
}

30_mirror2() {
	cp -v /etc/pacman.d/mirrorlist.default $born/etc/pacman.d/mirrorlist.default
	# cp -v /etc/pacman.d/mirrorlist $born/etc/pacman.d/mirrorlist
}

40_hostname() {
	# cp -v $born/etc/hostname $born/etc/hostname.default
	# cat $born/etc/hostname

	vendor=$(cat /sys/devices/virtual/dmi/id/sys_vendor | awk '{print $1}' | tr '[A-Z]' '[a-z]')
	host=""
	while [ -z $host ]
	do
		# host=$($DIALOG --backtitle "$appTitle" --title "Hostname" --inputbox "" 0 40 "" 3>&1 1>&2 2>&3)
		host=$($DIALOG --backtitle "$appTitle" --title "Hostname" --inputbox "" 0 0 "$vendor" 3>&1 1>&2 2>&3)
	done
	# cp -v $born/etc/hostname $born/etc/hostname.default
	echo $host > $born/etc/hostname
	# cat $born/etc/hostname


	cp -v $born/etc/hosts $born/etc/hosts.default
	# # cat $born/etc/hosts
	#TODO hostnamectl set-hostname <machine>
	#
	# echo -e "127.0.0.1\t$host.localdomain\t$hostname" >> $born/etc/hosts

	echo -e "127.0.0.1\t$host" >> $born/etc/hosts
	# cat $born/etc/hosts
}


50_bootLoader() {
	device=$(cat $temp/format)

	if is_efi
	then

		#grub efi
		# pacstrap $born grub os-prober
		# pacstrap $born efibootmgr dosfstools
		pacstrap $born grub efibootmgr
		#TODO pacstrap failed install package on chroot /mnt

		grub_file="/etc/default/grub"

# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck
# grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi $device
		# mkdir -pv $efi_rep/EFI
		arch-chroot $born /bin/bash << EOF
grub-install --target=x86_64-efi --bootloader-id=arch_grub --efi-directory=/boot/efi $device
cp -v $grub_file $grub_file.default
sed -i s/"GRUB_TIMEOUT=5"/"GRUB_TIMEOUT=0"/ $grub_file
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi

#syslinux efi
# 	pacstrap $born syslinux dosfstools efibootmgr
# 	mkdir -p $efi_rep/EFI/syslinux
# 	cp -r $born/usr/lib/syslinux/efi64/* $efi_rep/EFI/syslinux/
# 	cp $born/boot/syslinux/* $efi_rep/EFI/syslinux/
#
# 	arch-chroot $born /bin/bash << EOF
# mount -t efivarfs efivarfs /sys/firmware/efi/efivarfs
# efibootmgr -c -d "$device" -p 1 -l /EFI/syslinux/syslinux.efi -L "Syslinux"
# sed -i s/"TIMEOUT [0-9][0-9]"/"TIMEOUT 01"/ /boot/syslinux/syslinux.cfg
# EOF

# 	modprobe efivarfs
# 	pacstrap $born efibootmgr
# 	id=$(blkid | "$device"2 | awk -F\" '{print $2}')
# #
# # cp /boot/intel-ucode.img /boot/efi/EFI/arch/intel-ucode.img
#         arch-chroot $born /bin/bash << EOF
# efibootmgr -c -g -d "$device" -p 1 -L "Arch Linux" -l "\EFI\arch\vmlinuz-arch.efi" -u "root=UUID=$id rootfstype=ext4 initrd=\EFI\arch\initramfs-arch.img rw"
# efibootmgr -T
# EOF

# 	arch-chroot $born /bin/bash << EOF
# efibootmgr -c -g -d "$device" -p 1 -L "Arch Linux" -l "\\EFI\\arch\\vmlinuz-linux" -u "root=UUID=$id rootfstype=ext4 initrd=\\EFI\\arch\\initramfs-linux.img rw add_efi_memmap"
# efibootmgr -T
# EOF

else
	exit 5
	#grub efi
	pacstrap $born grub os-prober
	pacstrap $born dosfstools

	grub_file="/etc/default/grub"

	mkdir -pv $efi_rep/EFI
	arch-chroot $born /bin/bash << EOF
grub-install --target=i386-pc --no-floppy --recheck $device
cp -v $grub_file $grub_file.default
sed -i s/"GRUB_TIMEOUT=5"/"GRUB_TIMEOUT=0"/ $grub_file
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# 	pacstrap $born syslinux
#
# 	arch-chroot $born /bin/bash << EOF
# syslinux-install_update -im
# sed -i s/"TIMEOUT [0-9][0-9]"/"TIMEOUT 01"/ /boot/syslinux/syslinux.cfg
# sed -i s/"APPEND root=\/"$device"3 rw"/"APPEND root=\/"$device"2 rw"/ /boot/syslinux/syslinux.cfg
# EOF
fi
}

# 55_rootPasswd() {
#     # while true
#     # do
# 	# passwd $1
# 	# [ $? -eq 0 ] && break
#     # done
#
#     str1="a"
#     str2="b"
#     while [ $str1 != $str2 ]
#     do
# 	str1=$($DIALOG --backtitle "$appTitle" --title "Passwd Root" --clear --insecure --passwordbox "" 0 0 "" 3>&1 1>&2 2>&3)
# 	str2=$($DIALOG --backtitle "$appTitle" --title "Repeat Passwd Root" --clear --insecure --passwordbox "" 0 0 "" 3>&1 1>&2 2>&3)
#     done
#     passwd="$str1"
#
#     arch-chroot $born /bin/sh << EOF
# echo -e "$passwd\n$passwd" | passwd root
# EOF
#
#     echo "$passwd" > $temp/rootPasswd
#     # while arch-chroot $born passwd root
# }

60_timeZone2() {
	# cp $born/etc/localtime $born/etc/localtime.default

	print_color "ln -vfs /usr/share/zoneinfo/$(cat $temp/timeZone) $born/etc/localtime" 33
	ln -vfs /usr/share/zoneinfo/$(cat $temp/timeZone) $born/etc/localtime

	# failed to create bus connection timedatectl in chroot
	#     arch-chroot $born /bin/bash << EOF
	# timedatectl set-ntp true
	# timedatectl set-timezone $(cat $temp/timeZone)
	# EOF
}

65_locale() {
	# vi $born/etc/locale.gen
	# exit 1
	cp $born/etc/locale.gen $born/etc/locale.gen.default
	cp /etc/locale.gen $born/etc/locale.gen
	sed -i 's/#en_US ISO-8859-1/en_US ISO-8859-1/' $born/etc/locale.gen

	#     echo 'LANG="en-US.UTF-8"
	# LANGUAGE="en_US"
	# LC_COLLATE=C' > $born/etc/locale.conf

	arch-chroot $born locale-gen

	#TODO bad locale set
	#     arch-chroot $born /bin/bash << EOF
	# set-locale LANG="en_US.UTF-8"
	# EOF

	# cd /tmp
	# curl -o locale-check.sh http://ix.io/ksS
	# bash locale-check.sh
	# EOF

}

70_keyboard2() {
	# cp -v $born/etc/vconsole.conf $born/etc/vconsole.conf.default
	str="KEYMAP=$(cat $temp/keyboard)"

	[ -e $born/etc/vconsole.conf ] && exit 1
	echo "$str" > $born/etc/vconsole.conf
	print_color "echo '$str' > $born/etc/vconsole.conf" 33
}

75_mkinit() {
	print_color "mkinitcpio -p linux" 33
	pacstrap $born mkinitcpio
	arch-chroot $born mkinitcpio -p linux
}

80_addUser() {
	#TODO test empty user get in by dialog
	while [ -z "$userName" ]
	do
		userName=$($DIALOG --backtitle "$appTitle" --title "Add User" --inputbox "" 0 0 "" 3>&1 1>&2 2>&3)
	done

	str1="a"
	str2="b"
	comment=""
	while [ "$str1" != "$str2" ]
	do
		str1=$($DIALOG --backtitle "$appTitle" --title "Passwd $userName  $comment" --clear --insecure --passwordbox "" 0 0 "" 3>&1 1>&2 2>&3)
		str2=$($DIALOG --backtitle "$appTitle" --title "Repeat Passwd $userName" --clear --insecure --passwordbox "" 0 0 "" 3>&1 1>&2 2>&3)

		# if [ "$str1" == "$(cat $temp/rootPasswd)" ]; then
		#     str1="a"
		#     comment="(no same passwd as root)"
		# fi
	done
	passwd="$str1"

	# useradd -g users -G wheel -m -s /bin/sh $userName
	arch-chroot $born /bin/sh << EOF
useradd -g users -G wheel -m $userName -s /bin/zsh
echo -e "$passwd\n$passwd" | passwd $userName
EOF

echo "$userName" > $temp/addUser
}


82_fstab() {
	# if [ -f $born/etc/fstab.default ]
	# then
	# cp -v $born/etc/fstab.default $born/etc/fstab
	# else
	# cp -v $born/etc/fstab $born/etc/fstab.default
	# fi
	# cat $born/etc/fstab

	# genfstab -U -p $born | head -n +9 >> $born/etc/fstab
	print_color "genfstab -U -p $born >> $born/etc/fstab" 33
	genfstab -U $born >> $born/etc/fstab

	echo -e "tmpfs\t/home/$(cat $temp/addUser)/.cache\ttmpfs\tnoatime,nodev,nosuid,size=2G\t0\t0" >> $born/etc/fstab

	# sed -i s/"\/mnt\/"/"\/"/ /mnt/etc/fstab
	# sed -i s/"\/mnt"/"\/ "/ /mnt/etc/fstab

	# if is_efi
	# then
	# echo -e "# /esp/EFI/arch" >> $born/etc/fstab
	# echo -e "/esp/EFI/arch\t/boot\tnone\tdefaults,bind\t0 0" >> $born/etc/fstab
	# fi
	cat $born/etc/fstab
}

85_zsh() {
	print_color "pacstrap $born zsh" 33
	pacstrap $born zsh

	print_color "arch-chroot $born /bin/sh << EOF
	chsh -s /bin/zsh
	EOF
	" 33

	arch-chroot $born /bin/bash << EOF
chsh -s /bin/zsh
EOF

zsh_file="/etc/zsh/zshrc"
cp -v $zsh_file $born/root/.zshrc

user_file="home/$(cat $temp/addUser)/.zshrc"
cp -v $zsh_file $born/$user_file
touch -m -t 0001010000 $born/$user_file #for post sync, to avoid erase your personal .zshrc 
arch-chroot $born /bin/bash << EOF
chown gauthier:users /$user_file
EOF
}

90_sudoers() {
	pacstrap /mnt sudo
	cp -v $born/etc/sudoers $born/etc/sudoers.default

	sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' $born/etc/sudoers
	# sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' $born/etc/sudoers
}

95_wifi() {
	if iwconfig 2>&1 | grep ESSID | grep -v off > /dev/null
	then
		print_color "WIFI DECTECED ON THIS MACHINE" "1;32"
		print_color "install wifi package for a post install" 33
		# pacstrap $born wireless_tools wpa_supplicant dialog
		# pacstrap $born wpa_supplicant dialog #for wifi-menu
		pacstrap $born wpa_supplicant
		# cp -v /etc/netctl/wlp* $born/etc/netctl/
		# f=$(ls /etc/netctl/wl*)
		f=$(ls /var/lib/iwd/*.psk)
		#TODO bad wlan0 to wlo1 msi
		[ "$f" ]

		# interface=$(cat $f | grep Interface | awk -F= '{print $2}')
		interface="wlo1" #msi
		# interface=$(basename /sys/class/net/wl*)
		[ $interface ]
		# essid=$(cat $f | grep ESSID | awk -F= '{print $2}')
		essid=$(basename $f | awk -F. '{print $1}')
		[ $essid ]
		# psk=$(cat $f | grep Key | awk -F= '{print $2}' | tr -d '\\')
		psk=$(cat $f | grep Passphrase | awk -F= '{print $2}')
		[ $psk ]

		#TODO bad interface null
		file="$born/etc/wpa_supplicant/wpa_supplicant-$interface.conf"

		#TODO bad \ on string psk
		echo "ctrl_interface=/var/run/wpa_supplicant
		update_config=1
		" > $file

		#TODO bad passphrase
		wpa_passphrase "$essid" "$psk" | grep '#psk=' -v >> $file


		# network={
		#     ssid=\"$essid\"
		#     password=hash:$(echo -n $psk | iconv -t utf16le | openssl md4 | cut -c1-9 --complement)\"
		# }" > "$born/etc/wpa_supplicant/wpa_supplicant-$interface.conf"

		chmod 600 $file



		print_color "arch-chroot $born /bin/bash << EOF
		systemctl enable wpa_supplicant@$interface
		EOF
		" 33

		arch-chroot $born /bin/bash << EOF
systemctl enable wpa_supplicant@$interface
EOF

fi

print_color "enable dhcpcd" 33
arch-chroot $born /bin/bash << EOF
systemctl enable dhcpcd
EOF
}

99_umounting() {
	umount -vR $born
	print_color "df" 33
	df
}



case $1 in
	"-d")
		print_color "enable debug mode" 33
		debug="enable"
		;;

	"")
		;;

	*)
		print_color "unknow option" 31
		exit 1
		;;
esac


for function in $(declare -F | awk '{print $3}' | grep '^[0-9][0-9]_.*$')
	# for function in \
	# keyboard \
	# timeZone \
	# format \
	# mounting \
	# mirror \
	# base \
	# mirror2 \
	# hostname \
	# fstab \
	# bootLoader \
	# timeZone2 \
	# locale \
	# keyboard2 \
	# mkinit \
	# addUser \
	# zsh \
	# sudoers \
	# wifi \
	# umounting
do
	# echo "$function"
	# continue

	if ! [ -f "/tmp/minimal/$function" ]
	then
		bar "$function"
		eval "$function"
		barStatus "$function : done" 32
		# sleep 1
		if [ $debug ]; then
			read -r
		fi
		# optional
		touch "/tmp/minimal/$function"
		#TODO disable read to fast mode (read for debug mode)
		# read
	fi
done

# rm -r /tmp/minimal/
#TODO failed negative date
end=$(date +%s)
diff=$(echo $end - $(cat $temp/start) | bc)
min=$(echo "$diff / 60" | bc)
sec=$(echo "$diff % 60" | bc)

if ($DIALOG --backtitle "$appTitle" --title "Shutdown (install duration : $min min and $sec sec)" --yesno "\nPlease remove the usb key from the live cd before restarting the machine\n\n\n                   Poweroff now ?" 0 0)
then
	poweroff
fi


#TODO wifi bad config after reboot
