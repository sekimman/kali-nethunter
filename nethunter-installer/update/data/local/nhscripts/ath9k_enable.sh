#!/system/bin/sh

##
# Script to proper load atheros ath9k modules via init.d or immediately
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
if [ ! -f /system/lib/modules/mac80211.ko -o ! -f /system/lib/modules/ath9k.ko -o ! -f /system/lib/modules/ath9k_common.ko -o ! -f /system/lib/modules/ath9k_htc.ko -o ! -f /system/lib/modules/ath9k.ko ]; then
    echo "At least one of the needed modules are missing!"
    echo "Modules mac80211.ko, ath9k.ko, ath9k_common.ko, ath9k_htc.ko, ath9k.ko"
    echo "must be present in /system/lib/modules/"
    echo "Be sure that you use a kernel which has atheros ath9k chipset support enabled!"
    exit 1
fi

# use 'now' option to load modules immediately
if [ "$1" == "now" ]; then

    # disable systems wifi
    svc wifi disable
    sleep 2

    # load modules in proper dependency order (mac80211.ko always first)
    busybox insmod /system/lib/modules/mac80211.ko

    # only add ath module if available (newer driver versions have that module)
    if [ -f /system/lib/modules/ath.ko ]; then
	busybox insmod /system/lib/modules/ath.ko
    fi

    # ath9k module sequence
    busybox insmod /system/lib/modules/ath9k_hw.ko
    busybox insmod /system/lib/modules/ath9k_common.ko
    busybox insmod /system/lib/modules/ath9k_htc.ko
    busybox insmod /system/lib/modules/ath9k.ko
    exit 0
fi

# create init script in init folder and reboot
if [ ! -f $INIT_DIR/99_ath9k_init.sh ]; then

    # disable systems wifi (+reboot = important to avoid possible driver clash!)
    svc wifi disable

    # create init script
    mount -o rw,remount /system
    echo "#!/system/bin/sh" > $INIT_DIR/99_ath9k_init.sh
    echo "busybox insmod /system/lib/modules/mac80211.ko" >> $INIT_DIR/99_ath9k_init.sh

    # only add ath.ko module if available (newer driver versions have that module)
    if [ -f /system/lib/modules/ath.ko ]; then
	echo "busybox insmod /system/lib/modules/ath.ko" >> $INIT_DIR/99_ath9k_init.sh
    fi

    # ath9k module sequence
    echo "busybox insmod /system/lib/modules/ath9k_hw.ko" >> $INIT_DIR/99_ath9k_init.sh
    echo "busybox insmod /system/lib/modules/ath9k_common.ko" >> $INIT_DIR/99_ath9k_init.sh
    echo "busybox insmod /system/lib/modules/ath9k_htc.ko" >> $INIT_DIR/99_ath9k_init.sh
    echo "busybox insmod /system/lib/modules/ath9k.ko" >> $INIT_DIR/99_ath9k_init.sh

    # make it executeable
    busybox chmod 775 $INIT_DIR/99_ath9k_init.sh
    busybox sync
    mount -o ro,remount /system

    # finally reboot
    echo 0 > /sys/kernel/dyn_fsync/Dyn_fsync_active
    busybox sync
    sleep 2
    /system/bin/reboot
fi
