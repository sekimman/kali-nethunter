#!/system/bin/sh

##
# Script to remove of realtek rtl8187 modules via init.d or immediately
##

# system device
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
if [ ! -f /system/lib/modules/mac80211.ko -o ! -f /system/lib/modules/rtl8187.ko -o ! -f /system/lib/modules/eeprom_93cx6.ko ]; then
    echo "At least one of the needed modules are missing!"
    echo "Modules mac80211.ko, rtl8187.ko, eeprom_93cx6.ko"
    echo "must be present in /system/lib/modules/"
    echo "Be sure that you use a kernel which has realtek rtl8187 chipset support enabled!"
    exit 1
fi

# use this to unload modules immediately
if [ "$1" == "now" ]; then
    busybox rmmod rtl8187
    busybox rmmod eeprom_93cx6
    busybox rmmod mac80211
    sleep 1
    # enable systems wifi
    svc wifi enable
    exit 0
fi

# but default is to remove init script and do a reboot (lesser problems expected)
if [ -f $INIT_DIR/99_rtl8187_init.sh ]; then
    mount -o rw,remount /system
    rm $INIT_DIR/99_rtl8187_init.sh
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
