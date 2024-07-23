#!/bin/bash
# Complete Arch Linux setup script


# TODO: i was trying to make a good and configurable script but got lazy, ends at arch-chroot


# Define variables
# keyboard_layout="uk"
# use_gpt=false
# wifi_ssid=false
# disk_to_partition="sda"
# swap_size="16G"
# pacstrap_additional="nano base-devel networkmanager grub efibootmgr"

echo "This is a automated script to install Arch!"

# Get all inputs
if [ "$keyboard_layout" = "" ]; then
    localectl list-keymaps
    echo "Enter a keyboard layout to use:"
    read keyboard_layout
    if [ "$keyboard_layout" = "" ]; then echo "No keyboard layout set!" && exit 1; fi
fi

if [[ "$wifi_ssid" = "" && "$wifi_ssid" != "false" ]]; then
    echo "Enter Wi-Fi SSID or press enter to skip:"
    read wifi_ssid
fi
if [[ "$wifi_ssid" != "" ]]; then
    if [ "$wifi_device" = "" ]; then
        iwctl device list
        echo "Enter Wi-Fi device to use, defaults to wlan0:"
        read wifi_device
        if [ "$wifi_device" = "" ]; then wifi_device="wlan0"; fi
    fi
    if [ "$wifi_passphrase" = "" ]; then
        echo "Enter Wi-Fi passphrase or press enter for none:"
        read wifi_passphrase
    fi
fi

if [ "$disk_to_partition" = "" ]; then
    lsblk
    echo "Enter disk name to partition:"
    read disk_to_partition
    if [ "$disk_to_partition" = "" ]; then echo "No disk name to partition set!" && exit 1; fi
fi

if [ "$swap_size" = "" ]; then
    echo "Enter swap size, eg: 16G:"
    read swap_size
    if [ "$swap_size" = "" ]; then echo "No swap size set!" && exit 1; fi
fi

if [ "$pacstrap_additional" = "" ]; then
    echo "Enter any additional packages to be installed with pacstrap:"
    read pacstrap_additional
fi

echo "Starting in 10 seconds..."
sleep 10

# Set keyboard layout for this console
echo "Setting keyboard layout to $keyboard_layout for this console"
loadkeys $keyboard_layout

# Check boot mode
if [ -f /sys/firmware/efi/fw_platform_size ]; then
    if [ "$use_gpt" = "" ]; then use_gpt=true; fi
    echo "Boot mode is $(cat /sys/firmware/efi/fw_platform_size)-bit UEFI"
else
    if [ "$use_gpt" = "" ]; then use_gpt=false; fi
    echo "Boot mode is BIOS"
fi

# Wi-Fi
if [[ "$wifi_ssid" != "" && "$wifi_ssid" != "false" ]]; then
    # Connect to Wi-Fi
    iwctl device $wifi_device set-property Powered on
    iwctl station $wifi_device scan
    iwctl station $wifi_device get-networks
    if [ "$wifi_passphrase" = ""]; then
        iwctl station $wifi_device connect $wifi_ssid
    else
        iwctl --passphrase=$wifi_passphrase station $wifi_device connect $wifi_ssid
    fi
fi

# Ping test
ping google.com -c 4

# timedatectl
timedatectl

# Partition
if [ $use_gpt = true ]; then
    echo "Partitioning with GPT layout in 5 seconds..."
    sleep 5

    {
        echo "g" # New GPT partition table
        echo "n" # New partition
        echo "" # Default partition number
        echo "" # Default first sector
        echo "+1G" # Size
        echo "t" # Change partition type
        echo "EFI System" # New partition type
        echo "n" # New partition
        echo "" # Default partition number
        echo "" # Default first sector
        echo "+$swap_size" # Size
        echo "t" # Change partition type
        echo "" # Default partition number
        echo "Linux swap" # New partition type
        echo "n" # New partition
        echo "" # Default partition number
        echo "" # Default first sector
        echo "" # Size
        echo "t" # Change partition type
        echo "Linux root (x86-64)" # New partition type
        echo "w" # Write changes
    } | fdisk /dev/$disk_to_partition -W always
    echo "Partitioned disks, no going back now!"

    echo "Formatting partitions..."
    mkfs.ext4 /dev/${disk_to_partition}3
    mkswap /dev/${disk_to_partition}2
    mkfs.fat -F 32 /dev/${disk_to_partition}1

    echo "Mounting partitions..."
    mount /dev/${disk_to_partition}3 /mnt
    mount --mkdir /dev/${disk_to_partition}1 /mnt/boot
    swapon /dev/${disk_to_partition}2
else
    echo "Partitioning with MBR layout in 5 seconds..."
    sleep 5

    {
        echo "o" # New MBR partition table
        echo "n" # New partition
        echo "" # Default partition type
        echo "" # Default partition number
        echo "" # Default first sector
        echo "+$swap_size" # Size
        echo "t" # Change partition type
        echo "swap" # New partition type
        echo "n" # New partition
        echo "" # Default partition type
        echo "" # Default partition number
        echo "" # Default first sector
        echo "" # Size
        echo "t" # Change partition type
        echo "" # Default partition number
        echo "linux" # New partition type
        echo "w" # Write changes
    } | fdisk /dev/$disk_to_partition -W always
    echo "Partitioned disks, no going back now!"

    echo "Formatting partitions..."
    mkfs.ext4 /dev/${disk_to_partition}2
    mkswap /dev/${disk_to_partition}1

    echo "Mounting partitions..."
    mount /dev/${disk_to_partition}2 /mnt
    swapon /dev/${disk_to_partition}1
fi

echo "Installing packages in 5 seconds..."
sleep 5
pacstrap -K /mnt base linux linux-firmware nano base-devel grub efibootmgr $pacstrap_additional

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "Changing to new installs environment..."
arch-chroot /mnt /bin/bash -c "
    echo TODO
"