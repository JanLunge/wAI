#!/bin/bash
# ===  to install
# http://ow.ly/pQpl30dMcuJ
checklist=( 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 )
# COLORS {{{
    Bold=$(tput bold)
    Underline=$(tput sgr 0 1)
    Reset=$(tput sgr0)
    # Regular Colors
    Red=$(tput setaf 1)
    Green=$(tput setaf 2)
    Yellow=$(tput setaf 3)
    Blue=$(tput setaf 4)
    Purple=$(tput setaf 5)
    Cyan=$(tput setaf 6)
    White=$(tput setaf 7)
    # Bold
    BRed=${Bold}$(tput setaf 1)
    BGreen=${Bold}$(tput setaf 2)
    BYellow=${Bold}$(tput setaf 3)
    BBlue=${Bold}$(tput setaf 4)
    BPurple=${Bold}$(tput setaf 5)
    BCyan=${Bold}$(tput setaf 6)
    BWhite=${Bold}$(tput setaf 7)
  #}}}
  # PROMPT {{{
    prompt1="Enter your option: "
    prompt2="Enter n° of options (ex: 1 2 3 or 1-3): "
    prompt3="You have to manually enter the following commands, then press ${BYellow}ctrl+d${Reset} or type ${BYellow}exit${Reset}:"
  #}}}
  read_input() { #{{{
    if [[ $AUTOMATIC_MODE -eq 1 ]]; then
      OPTION=$1
    else
      read -p "$prompt1" OPTION
    fi
  } #}}}
  read_input_text() { #{{{
    if [[ $AUTOMATIC_MODE -eq 1 ]]; then
      OPTION=$2
    else
      read -p "$1 [y/N]: " OPTION
      echo ""
    fi
    OPTION=`echo "$OPTION" | tr '[:upper:]' '[:lower:]'`
  } #}}}
  read_input_options() { #{{{
    local line
    local packages
    if [[ $AUTOMATIC_MODE -eq 1 ]]; then
      array=("$1")
    else
      read -p "$prompt2" OPTION
      array=("$OPTION")
    fi
    for line in ${array[@]/,/ }; do
      if [[ ${line/-/} != $line ]]; then
        for ((i=${line%-*}; i<=${line#*-}; i++)); do
          packages+=($i);
        done
      else
        packages+=($line)
      fi
    done
    OPTIONS=("${packages[@]}")
  } #}}}
  pause_function() { #{{{
    print_line
    if [[ $AUTOMATIC_MODE -eq 0 ]]; then
      read -e -sn 1 -p "Press enter to continue..."
    fi
  } #}}}
print_line() { #{{{
  printf "%$(tput cols)s\n"|tr ' ' '-'
} #}}}
print_title() { #{{{
 clear
 print_line
 echo "# ${Bold}$1${Reset}"
 print_line
 echo ""
} #}}}
print_info() { #{{{
  #Console width number
  T_COLS=`tput cols`
  echo "${Bold}$1${Reset}" | fold -sw $(( $T_COLS - 18 ))
} #}}}
print_warning() { #{{{
  T_COLS=`tput cols`
  echo "${BYellow}$1${Reset}" | fold -sw $(( $T_COLS - 1 ))
} #}}}
print_danger() { #{{{
  T_COLS=`tput cols`
  echo "${BRed}$1${Reset}" | fold -sw $(( $T_COLS - 1 ))
} #}}}
contains_element() { #{{{
  #check if an element exist in a string
  for e in "${@:2}"; do [[ $e == $1 ]] && break; done;
} #}}}

checkbox() { #{{{
  #display [X] or [ ]
  [[ "$1" -eq 1 ]] && echo -e "${BBlue}[${Reset}${Bold}X${BBlue}]${Reset}" || echo -e "${BBlue}[ ${BBlue}]${Reset}";
} #}}}
checkbox_package() { #{{{
  #check if [X] or [ ]
  is_package_installed "$1" && checkbox 1 || checkbox 0
} #}}}
menu_item() { #{{{
   #check if the number of arguments is less then 2
   [[ $# -lt 2 ]] && _package_name="$1" || _package_name="$2";
   #list of chars to remove from the package name
   local _chars=("Ttf-" "-bzr" "-hg" "-svn" "-git" "-stable" "-icon-theme" "Gnome-shell-theme-" "Gnome-shell-extension-");
   #remove chars from package name
   for char in ${_chars[@]}; do _package_name=`echo ${_package_name^} | sed 's/'$char'//'`; done
   #display checkbox and package name
   echo -e "$(checkbox_package "$1") ${Bold}${_package_name}${Reset}"
 } #}}}
mainmenu_item() { #{{{
  #if the task is done make sure we get the state
  if [ $1 == 1 -a "$3" != "" ]; then
    state="${BGreen}[${Reset}$3${BGreen}]${Reset}"
  fi
  echo "$(checkbox "$1") ${Bold}$2${Reset} ${state}"
} #}}}

invalid_option() { #{{{
   print_line
   echo "Invalid option. Try another one."
   pause_function
 } #}}}

is_package_installed() { #{{{
  #check if a package is already installed
  for PKG in $1; do
    pacman -Q $PKG &> /dev/null && return 0;
  done
  return 1
} #}}}

package_install() { #{{{
    #install packages using pacman
    if [[ $AUTOMATIC_MODE -eq 1 || $VERBOSE_MODE -eq 0 ]]; then
      for PKG in ${1}; do
        local _pkg_repo=`pacman -Sp --print-format %r ${PKG} | uniq | sed '1!d'`
        case $_pkg_repo in
          "core")
            _pkg_repo="${BRed}${_pkg_repo}${Reset}"
            ;;
          "extra")
            _pkg_repo="${BYellow}${_pkg_repo}${Reset}"
            ;;
          "community")
            _pkg_repo="${BGreen}${_pkg_repo}${Reset}"
            ;;
          "multilib")
            _pkg_repo="${BCyan}${_pkg_repo}${Reset}"
            ;;
        esac
        if ! is_package_installed "${PKG}" ; then
          ncecho " ${BBlue}[${Reset}${Bold}X${BBlue}]${Reset} Installing (${_pkg_repo}) ${Bold}${PKG}${Reset} "
          pacman -S --noconfirm --needed ${PKG} >>"$LOG" 2>&1 &
          pid=$!;progress $pid
        else
          cecho " ${BBlue}[${Reset}${Bold}X${BBlue}]${Reset} Installing (${_pkg_repo}) ${Bold}${PKG}${Reset} exists "
        fi
      done
    else
      pacman -S --needed ${1}
    fi
  } #}}}

#SELECT KEYMAP {{{
select_keymap(){
  print_title "KEYMAP - https://wiki.archlinux.org/index.php/KEYMAP"
  keymap_list=("us" "de" "colemak"  "dvorak");
  PS3="$prompt1"
  print_info "The KEYMAP variable is specified in the /etc/rc.conf file. It defines what keymap the keyboard is in the virtual consoles. Keytable files are provided by the kbd package."
  echo "keymap list in /usr/share/kbd/keymaps"
    select KEYMAP in "${keymap_list[@]}"; do
    if contains_element "$KEYMAP" "${keymap_list[@]}"; then
      loadkeys "$KEYMAP";
      break
    else
      invalid_option
    fi
    done
}
#}}}

#DEFAULT EDITOR {{{
select_editor(){
  print_title "DEFAULT EDITOR"
  editors_list=("nano" "vim" "neovim" "emacs" "vi" "zile");
  PS3="$prompt1"
  echo "Select editor\n"
  select EDITOR in "${editors_list[@]}"; do
    if contains_element "$EDITOR" "${editors_list[@]}"; then
      package_install "$EDITOR"
      break
    else
      invalid_option
    fi
  done
}
#}}}

#MIRRORLIST {{{
configure_mirrorlist(){
  local countries_code=("AU" "AT" "BY" "BE" "BR" "BG" "CA" "CL" "CN" "CO" "CZ" "DK" "EE" "FI" "FR" "DE" "GR" "HK" "HU" "ID" "IN" "IE" "IL" "IT" "JP" "KZ" "KR" "LV" "LU" "MK" "NL" "NC" "NZ" "NO" "PL" "PT" "RO" "RU" "RS" "SG" "SK" "ZA" "ES" "LK" "SE" "CH" "TW" "TR" "UA" "GB" "US" "UZ" "VN")
  local countries_name=("Australia" "Austria" "Belarus" "Belgium" "Brazil" "Bulgaria" "Canada" "Chile" "China" "Colombia" "Czech Republic" "Denmark" "Estonia" "Finland" "France" "Germany" "Greece" "Hong Kong" "Hungary" "Indonesia" "India" "Ireland" "Israel" "Italy" "Japan" "Kazakhstan" "Korea" "Latvia" "Luxembourg" "Macedonia" "Netherlands" "New Caledonia" "New Zealand" "Norway" "Poland" "Portugal" "Romania" "Russia" "Serbia" "Singapore" "Slovakia" "South Africa" "Spain" "Sri Lanka" "Sweden" "Switzerland" "Taiwan" "Turkey" "Ukraine" "United Kingdom" "United States" "Uzbekistan" "Viet Nam")
  country_list(){
    #`reflector --list-countries | sed 's/[0-9]//g' | sed 's/^/"/g' | sed 's/,.*//g' | sed 's/ *$//g'  | sed 's/$/"/g' | sed -e :a -e '$!N; s/\n/ /; ta'`
    PS3="$prompt1"
    echo "Select your country:"
    select country_name in "${countries_name[@]}"; do
      if contains_element "$country_name" "${countries_name[@]}"; then
        country_code=${countries_code[$(( $REPLY - 1 ))]}
        break
      else
        invalid_option
      fi
    done
  }
  print_title "MIRRORLIST - https://wiki.archlinux.org/index.php/Mirrors"
  print_info "This option is a guide to selecting and configuring your mirrors, and a listing of current available mirrors."
  OPTION=n
  while [[ $OPTION != y ]]; do
    country_list
    read_input_text "Confirm country: $country_name"
  done

  url="https://www.archlinux.org/mirrorlist/?country=${country_code}&use_mirror_status=on"

  tmpfile=$(mktemp --suffix=-mirrorlist)

  # Get latest mirror list and save to tmpfile
  curl -so ${tmpfile} ${url}
  sed -i 's/^#Server/Server/g' ${tmpfile}

  # Backup and replace current mirrorlist file (if new file is non-zero)
  if [[ -s ${tmpfile} ]]; then
   { echo " Backing up the original mirrorlist..."
     mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig; } &&
   { echo " Rotating the new list into place..."
     mv -i ${tmpfile} /etc/pacman.d/mirrorlist; }
  else
    echo " Unable to update, could not download list."
  fi
  # better repo should go first
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
  rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
  rm /etc/pacman.d/mirrorlist.tmp
  # allow global read access (required for non-root yaourt execution)
  chmod +r /etc/pacman.d/mirrorlist
  $EDITOR /etc/pacman.d/mirrorlist
}
#}}}

#UMOUNT PARTITIONS {{{
umount_partitions(){
  mounted_partitions=(`lsblk | grep ${MOUNTPOINT} | awk '{print $7}' | sort -r`)
  swapoff -a
  for i in ${mounted_partitions[@]}; do
    umount $i
  done
}
#}}}

#SELECT DEVICE {{{
select_device(){
  devices_list=(`lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme\|mmcblk'`);
  PS3="$prompt1"
  echo -e "Attached Devices:\n"
  lsblk -lnp -I 2,3,8,9,22,34,56,57,58,65,66,67,68,69,70,71,72,91,128,129,130,131,132,133,134,135 | awk '{print $1,$4,$6,$7}'| column -t
  echo -e "\n"
  echo -e "Select device to partition:\n"
  select device in "${devices_list[@]}"; do
    if contains_element "${device}" "${devices_list[@]}"; then
      break
    else
      invalid_option
    fi
  done
  BOOT_MOUNTPOINT=$device
}
#}}}

#CREATE PARTITION SCHEME {{{
create_partition_scheme(){
  LUKS=0
  LVM=0
  print_title "https://wiki.archlinux.org/index.php/Partitioning"
  print_info "Partitioning a hard drive allows one to logically divide the available space into sections that can be accessed independently of one another."
  partition_layouts=("Default" "Maintain Current")
  PS3="$prompt1"
  echo -e "Select partition scheme:"
  select OPT in "${partition_layouts[@]}"; do
    partition_layout=$OPT
    case "$REPLY" in
      1)
        create_partition
        ;;
      2)
        modprobe dm-mod
        vgscan &> /dev/null
        vgchange -ay &> /dev/null
        ;;
      *)
        invalid_option
        ;;
    esac
    [[ -n $OPT ]] && break
  done
}
#}}}

#SETUP PARTITION{{{
create_partition(){
  apps_list=("cfdisk" "cgdisk" "fdisk" "gdisk" "parted");
  print_info "cfdisk -> GPT -> delete any partitions -> create one with linux -> write -> quit"
  PS3="$prompt1"
  echo "Select partition program:"
  select OPT in "${apps_list[@]}"; do
    if contains_element "$OPT" "${apps_list[@]}"; then
      select_device
      case $OPT in
        parted)
          parted -a opt ${device}
          ;;
        *)
          $OPT ${device}
          ;;
      esac
      break
    else
      invalid_option
    fi
  done
}
#}}}

#SELECT|FORMAT PARTITIONS {{{
format_partitions(){
  print_title "https://wiki.archlinux.org/index.php/File_Systems"
  print_info "This step will select and format the selected partition where archlinux will be installed"
  print_danger "All data on the partition will be LOST."

  echo ${device}
  pause_function
  #choose wich partition to format
  #choose variant ext4 or btrfs
  mkfs.btrfs -L "Arch Linux" /dev/sda1

  mkdir /mnt/btrfs-root
  mount -o defaults,relatime,discard,ssd,nodev,nosuid /dev/sda1 /mnt/btrfs-root

  mkdir -p /mnt/btrfs-root/__snapshot
  mkdir -p /mnt/btrfs-root/__current
  btrfs subvolume create /mnt/btrfs-root/__current/root
  btrfs subvolume create /mnt/btrfs-root/__current/host_name

  mkdir -p /mnt/btrfs-current
  mount -o defaults,relatime,discard,ssd,nodev,subvol=__current/root /dev/sda1 /mnt/btrfs-current
  mkdir -p /mnt/btrfs-current/host_name

  mount -o defaults,relatime,discard,ssd,nodev,nosuid,subvol=__current/home /dev/sda1 /mnt/btrfs-current/home



}
#}}}


#FINISH {{{
finish(){
  print_title "INSTALL COMPLETED"
  #COPY AUI TO ROOT FOLDER IN THE NEW SYSTEM
  print_warning "A copy of the wAI will be placed in /root directory of your new system"
  cp -R `pwd` ${MOUNTPOINT}/root
  read_input_text "Reboot system"
  if [[ $OPTION == y ]]; then
    umount_partitions
    reboot
  fi
  exit 0
}
#}}}

print_title "https://wiki.archlinux.org/index.php/Arch_Install_Scripts"
print_info "The Arch Install Scripts are a set of Bash scripts that simplify Arch installation."
while true
do
  print_title "ARCHLINUX ULTIMATE INSTALL - https://github.com/wlard/wAI"
  echo " 1) $(mainmenu_item "${checklist[1]}"  "Select Keymap"            "${KEYMAP}" )"
  echo " 2) $(mainmenu_item "${checklist[2]}"  "Select Editor"            "${EDITOR}" )"
  echo " 3) $(mainmenu_item "${checklist[3]}"  "Configure Mirrorlist"     "${country_name} (${country_code})" )"
  echo " 4) $(mainmenu_item "${checklist[4]}"  "Partition Scheme"         "${partition_layout}: ${partition}(${filesystem}) swap(${swap_type})" )"
  echo " 5) $(mainmenu_item "${checklist[5]}"  "Install Base System")"
  echo " 6) $(mainmenu_item "${checklist[6]}"  "Configure Fstab"          "${fstab}" )"
  echo " 7) $(mainmenu_item "${checklist[7]}"  "Configure Hostname"       "${host_name}" )"
  echo " 8) $(mainmenu_item "${checklist[8]}"  "Configure Timezone"       "${ZONE}/${SUBZONE}" )"
  echo " 9) $(mainmenu_item "${checklist[9]}"  "Configure Hardware Clock" "${hwclock}" )"
  echo "10) $(mainmenu_item "${checklist[10]}" "Configure Locale"         "${LOCALE}" )"
  echo "11) $(mainmenu_item "${checklist[11]}" "Configure Mkinitcpio")"
  echo "12) $(mainmenu_item "${checklist[12]}" "Install Bootloader"       "${bootloader}" )"
  echo "13) $(mainmenu_item "${checklist[13]}" "Root Password")"
  echo ""
  echo " d) Done"
  echo ""
  read_input_options
  for OPT in ${OPTIONS[@]}; do
    case "$OPT" in
      1)
        select_keymap
        checklist[1]=1
        ;;
      2)
        select_editor
        checklist[2]=1
        ;;
      3)
        configure_mirrorlist
        checklist[3]=1
        ;;
      4)
        umount_partitions
        create_partition_scheme
        format_partitions
        checklist[4]=1
        ;;
      5)
        install_base_system
        configure_keymap
        setup_alt_dns
        checklist[5]=1
        ;;
      6)
        configure_fstab
        checklist[6]=1
        ;;
      7)
        configure_hostname
        checklist[7]=1
        ;;
      8)
        configure_timezone
        checklist[8]=1
        ;;
      9)
        configure_hardwareclock
        checklist[9]=1
        ;;
      10)
        configure_locale
        checklist[10]=1
        ;;
      11)
        configure_mkinitcpio
        checklist[11]=1
        ;;
      12)
        install_bootloader
        configure_bootloader
        checklist[12]=1
        ;;
      13)
        root_password
        checklist[13]=1
        ;;
      "d")
        finish
        ;;
      *)
        invalid_option
        ;;
    esac
  done
done
#}}}
