echo "Changing to new installs environment..."
arch-chroot /mnt /bin/bash -c `
    echo "Setting time zone..." && ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime
    echo "Generating /etc/adjtime..." && hwclock --systohc
    echo "Generating locale..." && echo "$locale.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
    echo "Setting keyboard layout..." && echo "$keyboard_layout" >> /etc/vconsole.conf
    if [ "$hostname" != "" ]; then echo "Setting hostname..." && echo "$hostname" >> /etc/hostname; fi
    echo "Setting root password..." && echo "$root_password\n$root_password" | passwd

    echo "Installing GRUB..."
    if [ $use_gpt = true ]; then
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    else
        grub-install --target=i386-pc --bootloader-id=GRUB /dev/$disk_to_partition
    echo "Making GRUB config..."
    grub-mkconfig -o /boot/grub/grub.cfg

    echo "Enabling Network Manager..."
    systemctl enable NetworkManager

    echo "Creating '$user' user..."
    if [ "$fullname" != "" ]; then useradd -m -s /bin/bash $user -c "$fullname"; else useradd -m -s /bin/bash $user; fi
    echo "\n\n#Add wheel group to sudoers\n%wheel ALL=(ALL:ALL) ALL" | EDITOR="tee -a" visudo

    echo "Adding multilib repo..."
    echo "\n\n#Add multilib repository\n[multilib]\ninclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

    echo "Installing Yay..."
    pacman -Sy --needed git base-devel go && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
    
    if [ "$nvidia" != "" ]; then
        echo "Installing NVIDIA drivers..."
        pacman -Sy nvidia nvidia-utils nvidia-settings
        echo "NOT FINISHED!!!"
        # TODO: the rest
    fi

    if [ "$plasma" != "" ]; then
        echo "Installing KDE Plasma..."
        sudo pacman -Sy plasma kde-applications
        systemctl enable sddm
    fi
`