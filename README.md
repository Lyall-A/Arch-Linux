# Installing Arch Linux :D

## Sources
https://wiki.archlinux.org/title/installation_guide

https://wiki.archlinux.org/title/Iwd#iwctl

https://wiki.archlinux.org/title/GRUB

https://wiki.archlinux.org/title/NVIDIA

https://wiki.archlinux.org/title/Kernel_module#Setting_module_options


## Set keyboard layout (skippable)
* `localectl list-keymaps` to view keymaps
* `loadkeys <layout>` to set keyboard layout temporary (eg: `loadkeys uk`)

## Verify boot mode (skippable)
* `cat /sys/firmware/efi/fw_platform_size` to verify boot mode (should be 64)
    * `64`: 64-bit UEFI mode
    * `32`: 32-bit UEFI mode
    * `No such file or directory`: booted in BIOS or CSM mode

## Connect to internet (can be skipped if using ethernet)
* `ip link` to list network interfaces
* `rfkill` if using wireless/WWAN network interface to make sure that it is not blocked
* `iwctl` if using Wi-Fi
    * `device list` to view devices
    * `device <name> set-property Powered on` or `adapter <adapter> set-property Powered on` if device shows as powered off
    * `station <name> scan`
    * `station <name> get-networks`
    * `station <name> connect <SSID>` (Enter password if asked)
* ~~`mmcli` if using modem~~
* `ping google.com` to verify network connection

## Check system clock (skippable)
* `timedatectl`

## Partition disks
* `lsblk` or `fdisk -l` to view all devices
* `fdisk <disk to partition>` to modify partitions of disk (eg: `fdisk /dev/sda`)
    * `g` to create new GPT partition table OR `o` to create a new MBR partition table (deletes all partitions)
    * repeat each partition to be created:
        * `n` to create a new partition
        * default partition number
        * default first sector
        * size/last sector (eg: +1G for 1 GiB. blank to use remainder of disk. `y` to any warnings)
        * `t` to change partition type
        * default partition number for latest partition
        * partition type (eg: EFI System)
    * `w` to write changes and exit
    * UEFI with GPT layout:
        * `/boot` `/dev/efi_partition` `EFI System` `1 GiB`
        * `[SWAP]` `/dev/swap_partition` `Linux swap` `At least 4 GiB`
        * `/` `/dev/root_partition` `Linux root (x86-64)` `Remainder of disk`
    * BIOS with MBR layout:
        * `[SWAP]` `/dev/swap_partition` `swap/82` `At least 4 GiB`
        * `/` `/dev/root_partiton` `Linux/83` `Remainder of disk`

## Format partitions
* `mkfs.ext4 /dev/root_partition` to create Ext4 file system on root partition
* `mkswap /dev/swap_partition` to initialise swap
* `mkfs.fat -F 32 /dev/efi_partition` to format the EFI partition (if using GPT layout)

## Mount file systems
* `mount /dev/root_partition /mnt` to mount root volume
* `mount --mkdir /dev/efi_partition /mnt/boot` to mount EFI partition (if using GPT layout)
* `swapon /dev/swap_partition` to enable the swap volume

## Installation and configuration
* `pacstrap -K /mnt base linux linux-firmware nano base-devel networkmanager grub efibootmgr` to install packages
    * `xorg`, `xorg-xinit`, `openssh`, `git` and more can also be added
* `genfstab -U /mnt >> /mnt/etc/fstab` to create fstab
* `arch-chroot /mnt` to root into the new system
* `ln -sf /usr/share/zoneinfo/<region>/<city> /etc/localtime` to set time zone (eg. `ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime`)
* `hwclock --systohc` to generate /etc/adjtime
* `nano /etc/locale.gen` then uncomment `en_US.UTF-8 UTF-8` with anything else
* `locale-gen` to generate locale
* `nano /etc/vconsole.conf` and add `KEYMAP=<layout>` if you set a keyboard layout permanently
* `nano /etc/hostname` and set to what you want
* `passwd` to set root password

## Install GRUB
* `grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB` to install GRUB with GPT or `grub-install --target=i386-pc --bootloader-id=GRUB /dev/<disk>` to install GRUB with MBR
* `grub-mkconfig -o /boot/grub/grub.cfg` to generate GRUB config

## Reboot into installation
* `exit` to exit chroot
* `umount -R /mnt` to unmount all partitions
* `reboot`

## Extra
* `systemctl enable NetworkManager && systemctl start NetworkManager` then setup network
* `useradd -m -s /bin/bash <name>` to create a user
* `passwd <name>` to give user a password
* `usermod -aG wheel <name>` to make user root
* `EDITOR=nano visudo` and uncomment lines to allow wheel and optionally the sudo group
* `nano /etc/pacman.conf` and uncomment 2 lines for multilib for 32-bit software

## NVIDIA
* `sudo pacman -S nvidia nvidia-utils nvidia-settings` to install NVIDIA drivers
* `sudo nano /etc/default/grub` and add `nvidia-drm.modeset=1` to `GRUB_CMDLINE_LINUX_DEFAULT`
* `sudo grub-mkconfig -o /boot/grub/grub.cfg` to update GRUB configuration
* `sudo nano /etc/mkinitcpio.conf` and add `nvidia nvidia_modeset nvidia_uvm nvidia_drm` to `MODULES` then remove `kms` from `HOOKS` for early loading
* `sudo mkinitcpio -P` to regenerate initramfs
* `sudo curl https://raw.githubusercontent.com/Lyall-A/Arch-Linux/main/nvidia.hook --create-dirs -o /etc/pacman.d/hooks/nvidia.hook` to create Pacman hook that will automatically regenerate initramfs when NVIDIA gets updated, edit file if using other NVIDIA drivers

## Plasma
* `sudo pacman -S plasma kde-applications`
* `systemctl enable sddm && systemctl start sddm`
* Set keyboard layout in settings

## Yay
* `sudo pacman -S --needed git base-devel go && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si`

## AUR/official packages
* `brave-bin`
* `vesktop-bin`
* `spicetify-cli`
* `spotify`
* `visual-studio-code-bin`
* `steam`
* `multimc-bin`

## GPU Passthrough (TODO)
* `sudo pacman -S qemu libvirt virt-manager ovmf dnsmasq`
* `sudo systemctl enable libvirtd && sudo systemctl start libvirtd`
* `sudo nano /etc/default/grub`, add `intel_iommu=on` and `iommu=pt` to `GRUB_CMDLINE_LINUX_DEFAULT`
* `sudo grub-mkconfig -o /boot/grub/grub.cfg`
* Reboot
* `virt-manager`
* Create VM with UEFI `OVMF_CODE.fd`
* Install Windows 10