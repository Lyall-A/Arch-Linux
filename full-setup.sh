#!/bin/bash
# Complete Arch Linux setup script


# TODO: i was trying to make a good and configurable script but got lazy, ends at arch-chroot


# Define variables
SWAP_SIZE="16G" # REQUIRED!!!!!
KEYBOARD_LAYOUT="uk" # REQUIRED TO NOT GET PROMPTED
WIFI_SSID=false # REQUIRED TO NOT GET PROMPTED
USE_GPT=false # REQUIRED IF YOU DON'T WANT TO USE GPT WITH UEFI
PACSTRAP_ADDITIONAL="nano base-devel networkmanager grub efibootmgr" # REQUIRED TO NOT GET PROMPTED

echo "This is a automated script to install Arch!"
echo "Starting in 5 seconds..."
sleep 5

if [ "$KEYBOARD_LAYOUT" = "" ]; then
    localectl list-keymaps
    echo "Set a keyboard layout to use:"
    read $KEYBOARD_LAYOUT
fi
if [ "$KEYBOARD_LAYOUT" == "" ]; then
    echo "No keyboard layout set!"
    exit 1
fi

# Set keyboard layout for this console
echo "Setting keyboard layout to $KEYBOARD_LAYOUT for this console"
loadkeys $KEYBOARD_LAYOUT

# Check boot mode
if [ -f /sys/firmware/efi/fw_platform_size ]; then
    if [ "$USE_GPT" = "" ]; then USE_GPT=true; fi
    echo "Boot mode is $(cat /sys/firmware/efi/fw_platform_size)-bit UEFI"
else
    if [ "$USE_GPT" = "" ]; then USE_GPT=false; fi
    echo "Boot mode is BIOS"
fi

# Wi-Fi
if [[ "$WIFI_SSID" = "" && "$WIFI_SSID" != false ]]; then
    echo "Enter Wi-Fi SSID or press enter to skip:"
    read WIFI_SSID
fi
if [[ "$WIFI_SSID" != "" && "$WIFI_SSID" != false ]]; then
    iwctl device list
    # Ask for device, default to wlan0
    if [ "$WIFI_DEVICE" = "" ]; then
        echo "Enter device to use for Wi-Fi, defaults to wlan0:"
        read WIFI_DEVICE
    fi
    if [ "$WIFI_DEVICE" = "" ]; then WIFI_DEVICE="wlan0"; fi # Set default Wi-Fi device
    if [ "$WIFI_PASSPHRASE" = "" ]; then
        echo "Enter passphrase for $WIFI_SSID, leave blank for none:"
        read WIFI_PASSPHRASE
    fi

    # Connect to Wi-Fi
    iwctl device $WIFI_DEVICE set-property Powered on
    iwctl station $WIFI_DEVICE scan
    iwctl station $WIFI_DEVICE get-networks
    if [ "$WIFI_PASSPHRASE" = ""]; then
        iwctl station $WIFI_DEVICE connect $WIFI_SSID
    else
        iwctl --passphrase=$WIFI_PASSPHRASE station $WIFI_DEVICE connect $WIFI_SSID
    fi
fi

# Ping test
ping google.com -c 4

# timedatectl
timedatectl

# Partition
lsblk
if [ "$DISK_TO_PARTITION" = "" ]; then
    echo "Enter disk name to partition:"
    read DISK_TO_PARTITION
fi
if [ "$DISK_TO_PARTITION" = "" ]; then
    echo "No disk name was entered!"
    exit 1
fi
if [ $USE_GPT = true ]; then
    echo "Partitioning with GPT layout in 5 seconds..."
    sleep 5
    {
        echo "g"
        echo "n"
        echo ""
        echo ""
        echo ""
        echo "+1G"
        echo "t"
        echo "EFI System"
        echo "n"
        echo ""
        echo ""
        echo ""
        echo "+$SWAP_SIZE"
        echo "t"
        echo ""
        echo "Linux swap"
        echo "n"
        echo ""
        echo ""
        echo ""
        echo ""
        echo "t"
        echo ""
        echo "Linux root (x86-64)"
        echo "w"
    } | fdisk /dev/$DISK_TO_PARTITION -W always

    echo "Formatting partitions..."
    mkfs.ext4 /dev/${DISK_TO_PARTITION}3
    mkswap /dev/${DISK_TO_PARTITION}2
    mkfs.fat -F 32 /dev/${DISK_TO_PARTITION}1

    echo "Mounting partitions..."
    mount /dev/${DISK_TO_PARTITION}3 /mnt
    mount --mkdir /dev/${DISK_TO_PARTITION}1 /mnt/boot
    swapon /dev/${DISK_TO_PARTITION}2
else
    echo "Partitioning with MBR layout in 5 seconds..."
    sleep 5
    {
        echo "o"
        echo "n"
        echo ""
        echo ""
        echo ""
        echo "+$SWAP_SIZE"
        echo "t"
        echo "swap"
        echo "n"
        echo ""
        echo ""
        echo ""
        echo ""
        echo "t"
        echo ""
        echo "linux"
        echo "w"
    } | fdisk /dev/$DISK_TO_PARTITION -W always

    echo "Formatting partitions..."
    mkfs.ext4 /dev/${DISK_TO_PARTITION}2
    mkswap /dev/${DISK_TO_PARTITION}1

    echo "Mounting partitions..."
    mount /dev/${DISK_TO_PARTITION}2 /mnt
    swapon /dev/${DISK_TO_PARTITION}1
fi

echo "Partitioned disks, no going back now!"

pacstrap -K /mnt $PACSTRAP_ADDITIONAL
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt