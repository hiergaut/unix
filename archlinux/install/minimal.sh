#! /bin/bash -e

bar() {
    tailleBar=$(expr $(tput cols) - 4) || sleep 0

    let "middleBar=$tailleBar/2" || sleep 0

    menu=$1
    lenMenu=${#menu}
    let "moitieLenMenu=$lenMenu/2" || sleep 0
    let "impaire=$lenMenu%2" || sleep 0

    let "bordureInf=$middleBar -$moitieLenMenu" || sleep 0
    let "bordureSup=$middleBar +$moitieLenMenu" || sleep 0

    echo -ne "\\033[1;36m"
    for i in $(seq 1 $bordureInf); do
	echo -n '+'
    done
    echo -en "\\033[0m"

    echo -en "\\033[1;33m"
    echo -n ' '
    echo -n $menu
    echo -n ' '
    echo -en "\\033[0m"

    let "lenSup=$tailleBar -$bordureSup" || sleep 0
    echo -en "\\033[1;36m"
    for i in $(seq 1 $lenSup); do
	echo -n '+'
    done

    if [ $impaire -eq 0 ]; then
	echo -en '+'
    fi

    echo -e "\\033[0m"
}

barStatus() {
    if [ $# -ne 2 ] && [ $# -ne 1 ]; then
	echo "usage :barStatus string color"
	exit 1
    fi

    tailleBar=$(expr $(tput cols) - 4) || sleep 0
    # middleBar=$(expr $tailleBar / 2)

    string="$1"
    couleur=$2
    if [ -z $2 ]; then
	couleur=32
    fi
    lenString=${#string}

    let "bordureInf=$tailleBar -$lenString +3" || sleep 0

    for i in $(seq 1 $bordureInf); do
	echo -n ' '
    done

    # echo -ne "\\033[1;$couleur"m"$string"
    # echo -e "\\033[0m"

    echo -e "\\033[1;$couleur"m"$string\\033[0m"
}

is_efi() {
    if [ -d /sys/firmware/efi/ ]
    then
	return 0
    else
	return 1
    fi
}

born="/mnt"
appTitle="Archlinux Installer"
temp="/tmp/minimal"
efi_rep="$born/boot/efi"

init() {
    mkdir -v /tmp/minimal/
}

keyboard() {
    # items=$(localectl list-keymaps)
    items=$(find /usr/share/kbd/keymaps/ -type f -printf "%f\n" | awk -F. '{print $1}' | sort)
    options=()
    for item in $items; do
	options+=("$item" "")
    done
    key=$(whiptail --backtitle "$appTitle" --title "Keymap Selection" --menu "" 40 40 30 \
	"${options[@]}" \
	3>&1 1>&2 2>&3)

    echo "loadkeys $key"
    loadkeys $key
    echo "$key" > $temp/keyboard
}

timeZone() {
    items=$(ls -l /usr/share/zoneinfo/ | grep '^d' | gawk -F':[0-9]* ' '/:/{print $2}')
    options=()
    for item in $items; do
	options+=("$item" "")
    done
    timezone=$(whiptail --backtitle "$appTitle" --title "Time zone" --menu "" 0 0 0 \
	"${options[@]}" \
	3>&1 1>&2 2>&3)
    if [ ! "$?" = "0" ]; then
	return 1
    fi


    items=$(ls /usr/share/zoneinfo/$timezone/)
    options=()
    for item in $items; do
	options+=("$item" "")
    done
    timezone=$timezone/$(whiptail --backtitle "$appTitle" --title "Time zone" --menu "" 40 30 30 \
	"${options[@]}" \
	3>&1 1>&2 2>&3)


    echo "timedatectl set-ntp true"
    echo "timedatectl set-timezone $timezone"
    echo "$timezone" > $temp/timeZone
}

format() {
    if is_efi
    then
	if (whiptail --backtitle "$appTitle" --title "Format EFI" --yesno "/dev/sda1   512M   EFI System\n/dev/sda2   40G    Linux filesystem\n/dev/sda3   *G     Linux filesystem\n\n\n                                 Commit ?" 0 80)
	then
	    echo -e "\\033[33mparted /dev/sda mklabel gpt\\033[0m"
	    parted /dev/sda mklabel gpt -ms
	    echo -e "\\033[33mparted /dev/sda mkpart ESP fat32 1MiB 513Mib\\033[0m"
	    parted /dev/sda mkpart ESP fat32 1MiB 513Mib -ms
	    echo -e "\\033[33mparted /dev/sda set 1 boot on\\033[0m"
	    parted /dev/sda set 1 boot on -ms
	    echo -e "\\033[33mparted /dev/sda mkpart primary ext4 513Mib 40.5Gib\\033[0m"
	    parted /dev/sda mkpart primary ext4 513Mib 40.5Gib -ms
	    echo -e "\\033[33mparted /dev/sda mkpart primary ext4 40.5Gib 100%\\033[0m"
	    parted /dev/sda mkpart primary ext4 40.5Gib 100% -ms
	    echo

	    echo -e "\\033[33mmkfs.vfat -F32 /dev/sda1\\033[0m"
	    mkfs.vfat -F32 /dev/sda1 <<< y
	    echo -e "\\033[33mmkfs.ext4 /dev/sda2\\033[0m"
	    mkfs.ext4 /dev/sda2 <<< y
	    echo -e "\\033[33mmkfs.ext4 /dev/sda3\\033[0m"
	    mkfs.ext4 /dev/sda3 <<< y
	else
	    return 1
	fi
    else
	if (whiptail --backtitle "$appTitle" --title "Format DOS" --yesno "/dev/sda1   512M   Linux\n/dev/sda2   40G    Linux\n/dev/sda3   *G     Linux\n\n\n                                 Commit ?" 0 80)
	then
	    echo -e "\\033[33mparted /dev/sda mklabel dos\\033[0m"
	    parted /dev/sda mklabel msdos -ms
	    echo -e "\\033[33mparted /dev/sda mkpart ext2 1MiB 513Mib\\033[0m"
	    parted /dev/sda mkpart primary ext2 1MiB 513Mib -ms
	    echo -e "\\033[33mparted /dev/sda set 1 boot on\\033[0m"
	    parted /dev/sda set 1 boot on -ms
	    echo -e "\\033[33mparted /dev/sda mkpart primary ext4 513Mib 40.5Gib\\033[0m"
	    parted /dev/sda mkpart primary ext4 513Mib 40.5Gib -ms
	    echo -e "\\033[33mparted /dev/sda mkpart primary ext4 40.5Gib 100%\\033[0m"
	    parted /dev/sda mkpart primary ext4 40.5Gib 100% -ms
	    echo

	    echo -e "\\033[33mmkfs.ext2 /dev/sda1\\033[0m"
	    mkfs.ext2 /dev/sda1 <<< y
	    echo -e "\\033[33mmkfs.ext4 /dev/sda2\\033[0m"
	    mkfs.ext4 /dev/sda2 <<< y
	    echo -e "\\033[33mmkfs.ext4 /dev/sda3\\033[0m"
	    mkfs.ext4 /dev/sda3 <<< y
	else
	    return 1
	fi
    fi
}

mounting() {
    if is_efi
    then
	mount -v /dev/sda2 $born #root

	mkdir -v $born/home
	mount -v /dev/sda3 $born/home/

	mkdir -pv $efi_rep
	mount -t vfat /dev/sda1 $efi_rep
	# mkdir -v $born/esp
	# mount -v /dev/sda1 $born/esp/
	# mkdir -pv $born/esp/EFI/arch/
	# mount -v --bind $born/esp/EFI/arch/ $born/boot/
    else
	mount -v /dev/sda2 $born
	mkdir -v $born/home
	mkdir -v $born/boot
	mount -v /dev/sda1 $born/boot/
	mount -v /dev/sda3 $born/home/
    fi
}

mirror() {
    file="/etc/pacman.d/mirrorlist"

    if ! [ -f $file.default ]
    then
	cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.default
    fi
    
    items=$(cat /etc/pacman.d/mirrorlist.default | grep '##' | awk '{print $2}' | sort | uniq)
    options=()
    for item in $items; do
	options+=("$item" "")
    done
    country=$(whiptail --backtitle "$appTitle" --title "Select Country Mirror" --menu "" 40 40 30 \
	"${options[@]}" \
	3>&1 1>&2 2>&3)

    head -n 6 $file.default > $file
    # cat $file

    echo "## $country" >> $file
    # cat $file
    cat $file.default | while read line
    do
	if echo $line | grep $country > /dev/null
	then
	    read line
	    echo $line >> $file
	    # echo $line
	fi
    done

    rankmirrors $file -v | tee /tmp/minimal/rank
    mv /tmp/minimal/rank $file
}

base() {
    pacstrap $born base base-devel

    #optional
    pacstrap $born openssh zsh rsync wget dialog vim
}

mirror2() {
    cp -v /etc/pacman.d/mirrorlist.default $born/etc/pacman.d/mirrorlist.default
    # cp -v /etc/pacman.d/mirrorlist $born/etc/pacman.d/mirrorlist
}

hostname() {
    # cp -v $born/etc/hostname $born/etc/hostname.default
    # cat $born/etc/hostname

    host=""
    while [ -z $host ]
    do
	host=$(whiptail --backtitle "$appTitle" --title "Hostname" --inputbox "" 0 40 "" 3>&1 1>&2 2>&3)
    done
    # cp -v $born/etc/hostname $born/etc/hostname.default
    echo $host > $born/etc/hostname
    cat $born/etc/hostname


    # cp -v $born/etc/hosts $born/etc/hosts.default
    # # cat $born/etc/hosts
    #
    # echo -e "127.0.0.1\t$hostname.localdomain\t$hostname" >> $born/etc/hosts
    # cat $born/etc/hosts
}

fstab() {
    # if [ -f $born/etc/fstab.default ]
    # then
	# cp -v $born/etc/fstab.default $born/etc/fstab
    # else
	# cp -v $born/etc/fstab $born/etc/fstab.default
    # fi
    # cat $born/etc/fstab

    # genfstab -U -p $born | head -n +9 >> $born/etc/fstab
    genfstab -U -p $born >> $born/etc/fstab

    # sed -i s/"\/mnt\/"/"\/"/ /mnt/etc/fstab
    # sed -i s/"\/mnt"/"\/ "/ /mnt/etc/fstab

    # if is_efi
    # then
	# echo -e "# /esp/EFI/arch" >> $born/etc/fstab
	# echo -e "/esp/EFI/arch\t/boot\tnone\tdefaults,bind\t0 0" >> $born/etc/fstab
    # fi
    cat $born/etc/fstab
}

efi() {
    if is_efi
    then
	pacstrap $born grub os-prober
	pacstrap $born efibootmgr dosfstools

	mkdir -pv $efi_rep/EFI
	arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck"
	arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"

# 	modprobe efivarfs
# 	pacstrap $born efibootmgr
# 	id=$(blkid | grep sda2 | awk -F\" '{print $2}')
#
#     #     arch-chroot $born /bin/bash << EOF
#     # cp /boot/intel-ucode.img /boot/efi/EFI/arch/intel-ucode.img
#     # efibootmgr -c -g -d /dev/sda -p 1 -L "Arch Linux" -l "\EFI\arch\vmlinuz-arch.efi" -u "root=UUID=$id rootfstype=ext4 initrd=\EFI\arch\intel-ucode.img initrd=\EFI\arch\initramfs-arch.img rw add_efi_memmap"
#     # efibootmgr -T
#     # EOF
#
# 	arch-chroot $born /bin/bash << EOF
# efibootmgr -c -g -d /dev/sda -p 1 -L "Arch Linux" -l "\\EFI\\arch\\vmlinuz-linux" -u "root=UUID=$id rootfstype=ext4 initrd=\\EFI\\arch\\initramfs-linux.img rw add_efi_memmap"
# efibootmgr -T
# EOF

    else
	pacstrap $born syslinux

	arch-chroot $born /bin/bash << EOF
syslinux-install_update -im
sed -i s/"TIMEOUT [0-9][0-9]"/"TIMEOUT 01"/ /boot/syslinux/syslinux.cfg
sed -i s/"APPEND root=\/dev\/sda3 rw"/"APPEND root=\/dev\/sda2 rw"/ /boot/syslinux/syslinux.cfg
EOF
    fi
}

rootPasswd() {
    # while true
    # do
	# passwd $1
	# [ $? -eq 0 ] && break
    # done

    str1="a"
    str2="b"
    while [ $str1 != $str2 ]
    do
	str1=$(whiptail --backtitle "$appTitle" --title "Passwd Root" --passwordbox "" 8 80 "" 3>&1 1>&2 2>&3)
	str2=$(whiptail --backtitle "$appTitle" --title "Repeat Passwd Root" --passwordbox "" 8 80 "" 3>&1 1>&2 2>&3)
    done
    passwd="$str1"

    arch-chroot $born /bin/sh << EOF
echo -e "$passwd\n$passwd" | passwd root
EOF

    echo "$passwd" > $temp/rootPasswd
    # while arch-chroot $born passwd root
}

timeZone2() {
    # cp $born/etc/localtime $born/etc/localtime.default
    ln -vfs /usr/share/zoneinfo/$(cat $temp/timeZone) $born/etc/localtime
#     arch-chroot $born /bin/sh << EOF
# timedatectl set-ntp true
# timedatectl set-timezone $timezone
# EOF
}

locale() {
    # vi $born/etc/locale.gen
    # exit 1
    # cp $born/etc/locale.gen $born/etc/locale.gen.default
    cp /etc/locale.gen $born/etc/locale.gen
    arch-chroot $born locale-gen
}

keyboard2() {
    # cp -v $born/etc/vconsole.conf $born/etc/vconsole.conf.default
    echo KEYMAP=$(cat $temp/keyboard) | tee $born/etc/vconsole.conf
}

mkinit() {
    arch-chroot $born mkinitcpio -p linux
}

addUser() {
    while [ ! $userName ]
    do
	userName=$(whiptail --backtitle "$appTitle" --title "Add User" --inputbox "" 0 40 "" 3>&1 1>&2 2>&3)
    done

    str1="a"
    str2="b"
    comment=""
    while [ $str1 != $str2 ]
    do
	str1=$(whiptail --backtitle "$appTitle" --title "Passwd $userName  $comment" --passwordbox "" 8 80 "" 3>&1 1>&2 2>&3)
	str2=$(whiptail --backtitle "$appTitle" --title "Repeat Passwd $userName" --passwordbox "" 8 80 "" 3>&1 1>&2 2>&3)

	if [ "$str1" == "$(cat $temp/rootPasswd)" ]; then
	    str1="a"
	    comment="(no same passwd as root)"
	fi
    done
    passwd="$str1"

# useradd -g users -G wheel -m -s /bin/sh $userName
    arch-chroot $born /bin/sh << EOF
useradd -g users -G wheel -m $userName
echo -e "$passwd\n$passwd" | passwd $userName
EOF
}

# sudoers() {
#     cp -v $born/etc/sudoers $born/etc/sudoers.default
#     sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' $born/etc/sudoers
#     # sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' $born/etc/sudoers
# }

wifi() {
    if iwconfig 2>&1 | grep ESSID | grep -v off > /dev/null
    then
	# pacstrap $born wireless_tools wpa_supplicant dialog
	pacstrap $born wpa_supplicant dialog
	cp -v /etc/netctl/wlp* $born/etc/netctl/
    fi
}

umounting() {
    umount -vR $born
}

for function in \
    init \
    keyboard \
    timeZone \
    format \
    mounting \
    mirror \
    base \
    mirror2 \
    hostname \
    fstab \
    efi \
    rootPasswd \
    timeZone2 \
    locale \
    keyboard2 \
    mkinit \
    addUser \
    wifi \
    umounting
do
    if ! [ -f "/tmp/minimal/$function" ]
    then
	bar "$function"
	eval "$function"
	barStatus "$function : done" 32
	# sleep 1
	# read
	touch "/tmp/minimal/$function"
    fi
done

# rm -r /tmp/minimal/

if (whiptail --backtitle "$appTitle" --title "Shutdown" --yesno "Please remove the usb key from the live cd before restarting the machine\n\n\n                              Poweroff now ?" 0 80)
then
    poweroff
fi
