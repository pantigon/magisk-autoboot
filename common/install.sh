. $MODPATH/common/util_functions.sh

ui_print "- Find boot.img"

find_boot_image

[ -z $BOOTIMAGE ] && abort "! Unable to detect target image"

ui_print "- Target image: $BOOTIMAGE"

ui_print "- Patching boot image"
if [ -c "$BOOTIMAGE" ]; then
  nanddump -f boot.img "$BOOTIMAGE"
  BOOTNAND="$BOOTIMAGE"
  BOOTIMAGE=boot.img
fi
/data/adb/magisk/magiskboot unpack boot.img
/data/adb/magisk/magiskboot cpio ramdisk.cpio \
"mkdir 0700 overlay.d" \
"add 0700 overlay.d/init.custom.rc $MODPATH/files/init.custom.rc" \
"mkdir 0700 overlay.d/sbin" \
"add 0700 overlay.d/sbin/custom.sh $MODPATH/files/init.custom.sh"
/data/adb/magisk/magiskboot repack boot.img boot_patched_autoboot.img
/data/adb/magisk/magiskboot cleanup
ui_print "- Generated $(pwd) boot_patched_autoboot.img"


ui_print "- Flashing new boot image"
flash_image boot_patched_autoboot.img "$BOOTIMAGE"
case $? in
  1)
    abort "! Insufficient partition size"
    ;;
  2)
    abort "! $BOOTIMAGE is read only"
    ;;
esac

rm -f boot_patched_autoboot.img
run_migrations