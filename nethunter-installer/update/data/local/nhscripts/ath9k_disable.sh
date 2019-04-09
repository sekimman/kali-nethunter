#!/system/bin/sh

##
# Script to remove of atheros ath9k modules via init.d or immediately
##

SYSTEM_DEVICE="/dev/block/bootdevice/by-name/system"
INIT_DIR=""

# use init.d folder if available
if [ -d /system/etc/init.d ]; then
    INIT_DIR="/system/etc/init.d"
fi

# if Magisk is available use its init folder
if [ -d /sbin/.magisk/img/.core/post-fs-data.d ]; then
    INIT_DIR="/sbin/.magisk/img/.core/post-fs-data.d"
fi

# no init folders found, only manual mode possible
if [ -z "$INIT_DIR" ] && [ ! -z "$1" ]; then
    echo "You need Magisk installed or a kernel which supports /system/etc/init.d folder to use a modules loading init script!"
    echo "You however still can use the command line option 'now' with this script to unload modules immediately."
    echo "Don't forget to reboot afterwards!"
    exit 1
fi

# check if needed modules are available otherwise quit
if [ ! -f /system/lib/modules/mac80211.ko -o ! -f /system/lib/modules/ath9k.ko -o ! -f /system/lib/modules/ath9k_common.ko -o ! -f /system/lib/modules/ath9k_htc.ko -o ! -f /system/lib/modules/ath9k.ko ]; then
    echo "At least one of the needed modules are missing!"
    echo "Modules mac80211.ko, ath9k.ko, ath9k_common.ko, ath9k_htc.ko, ath9k.ko"
    echo "must be present in /system/lib/modules/"
    echo "Be sure that you use a kernel which has atheros ath9k chipset support enabled!"
    exit 1
fi

# use this to unload modules immediately
if [ "$1" == "now" ]; then
    busybox rmmod ath9k_htc
    busybox rmmod ath9k
    busybox rmmod ath9k_common
    busybox rmmod ath9k_hw
    if [ -f /system/lib/modules/ath.ko ]; then
        busybox rmmod ath
    fi
    busybox rmmod mac80211
    sleep 1
    # enable systems wifi
    svc wifi enable
    echo "Modules unloaded, please reboot now!"
    exit 0
fi

# default is to remove init script again and do a reboot (lesser problems expected)
if [ -f $INIT_DIR/99_ath9k_init.sh ]; then
    mount -o rw,remount /system
    rm $INIT_DIR/99_ath9k_init.sh
    busybox sync
    mount -o ro,remount /system
    # enable systems wifi
    svc wifi enable
    # finally reboot
    echo 0 > /sys/kernel/dyn_fsync/Dyn_fsync_active
    busybox sync
    sleep 1
    /system/bin/reboot
fi
