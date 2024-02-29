#!/bin/bash
input () {
    #Drive to install too.
    lsblk
    read -p "Drive to install too: " DRIVE
    if [[ $DRIVE =~ ^nvme[0-9]n[1-9]$ ]]; then
        part1=$DRIVE"p1"
        part2=$DRIVE"p2"
        part3=$DRIVE"p3"
        part4=$DRIVE"p4"
    else
        part1=$DRIVE"1"
        part2=$DRIVE"2"
        part3=$DRIVE"3"
        part4=$DRIVE"4"
    fi
    export DRIVE
    export part1
    export part2
    export part3
    export part4
    clear

    #CPU Microcode
    echo "1. AMD"
    echo "2. Intel"
    read -p "CPU Manufacturer (1 or 2): " MICROCODE
    if [[ $MICROCODE == 1 ]]; then
        MICROCODE="amd-ucode"
    else
        MICROCODE="intel-ucode"
    fi
    export MICROCODE
    clear

    #Hostname (password will be prompted for security)
    read -p "Hostname: " HOSTNAME
    export HOSTNAME
    clear

    #Username (password will be prompted for security)
    read -p "Username: " USERNAME
    export USERNAME
    clear

    #System Timezone
    read -p "Timezone: " TIMEZONE
    export TIMEZONE
    clear

    #Keymap 
    read -p "Keymap (insert default to set as console default US ): " KEYMAP
    export KEYMAP
    clear

    #Packages You Want To Install
    read -p "Extra Packages: " PACKAGES
    export PACKAGES
    clear
}

setup() {
    #Allowing 5 downloads simultaneously.
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

    echo "Creating Partitions"
    partition_drive

    echo "Formatting Partition"
    format_partition

    echo "Mounting Filesystem"
    mount_filesystems

    echo "Installing Arch Linux"
    install_base

    echo "Generating Fstab"
    gen_fstab

    echo "Chrooting into installed system to continue setup..."
    cp "$0" /mnt/setup.sh 
    arch-chroot /mnt ./setup.sh chroot

    if [ -f /mnt/setup.sh ]
    then
        echo 'ERROR: Something failed inside the chroot, not unmounting filesystems so you can investigate.'
        echo 'Make sure you unmount everything before you try to run this script again.'
    else
        echo 'Unmounting filesystems'
        exit_chroot
        echo 'Done! Reboot system.'
        exit 0
    fi
}

configure() {
    #Allowing 5 downloads simultaneously.
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

    echo "Installing Packages"
    install_packages

    echo "Setting Timezone"
    set_timezone

    #The locale is hard coded to en_US.UTF-8 UTF-8.
    echo "Generating Locale"
    set_locale

    echo "Setting Keymaps"
    set_keymap

    echo "Setting up Host"
    set_host

    echo "Configuring Network"
    setup_network

    echo "Setting up User Info and Set Sudoer Privileges"
    create_user 

    echo "setting sudoer"
    set_sudoers

    echo "Setting up Bootloader"
    boot_loader

    rm /setup.sh
}

partition_drive() { 
    parted -s "/dev/$DRIVE" \
        mklabel gpt \
        mkpart "EFI" fat32 1MiB 1GiB \
        mkpart "root" ext4 1GiB 21GiB \
        mkpart "swap" linux-swap 21GiB 26GiB \
        mkpart "home" ext4 26GiB 100% \
        set 1 esp on \
        set 3 swap on \
        set 4 linux-home on
}

format_partition() {
    mkfs.fat -F 32 /dev/$part1
    mkfs.ext4 /dev/$part2
    mkswap /dev/$part3
    mkfs.ext4 /dev/$part4
}

mount_filesystems() {
    mount /dev/$part2 /mnt
    mount --mkdir /dev/$part1 /mnt/boot
    swapon /dev/$part3
    mount --mkdir /dev/$part4 /mnt/home
}

install_base() {
    pacstrap -K /mnt base linux linux-firmware base-devel openssh $MICROCODE --noconfirm --needed
}

gen_fstab() {
    genfstab -U /mnt >> /mnt/etc/fstab
}

install_packages() {
    pacman -S $PACKAGES --noconfirm --needed
}

set_timezone() {
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    hwclock --systohc
}

set_locale() {
    sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    echo "LANG=en_US.UTF-8" >> /etc/locale.conf
    locale-gen
}

set_keymap() {
    if [[ $KEYMAP == default ]]; then
        echo "Keymap set to default"
    else
        echo "KEYMAP=$KEYMAP" >> /etc/vconsole.conf
    fi
}

set_host() {
    echo "$HOSTNAME" >> /etc/hostname
    echo "Enter Host Password"
    passwd
}

setup_network() {
    pacman -S networkmanager --noconfirm --needed
    
    cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain   $HOSTNAME
EOF
    
    systemctl start NetworkManager && systemctl enable NetworkManager
}

create_user() {
    useradd -m -G wheel,adm,rfkill,network,video,audio,optical,storage,sys,systemd-journal,http,games,ftp,disk,kvm,input $USERNAME
    passwd $USERNAME
}

set_sudoers() {
    pacman -S sudo --noconfirm --needed
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

}

boot_loader() {
    pacman -S grub efibootmgr dosfstools os-prober mtools --noconfirm --needed
    mkdir -p /boot/efi
    mount /dev/$part1 /boot/efi
    grub-install /dev/$DRIVE
    grub-mkconfig -o /boot/grub/grub.cfg
}

exit_chroot() {
    umount -R /mnt
}

#uncomment to debug
#set -ex

if [[ "$1" == "chroot" ]]; then
    configure
else
    input && setup
fi
