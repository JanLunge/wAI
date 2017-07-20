#!/bin/bash
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
  echo "${Bold}$1${Reset}\n" | fold -sw $(( $T_COLS - 18 ))
} #}}}
print_warning() { #{{{
  T_COLS=`tput cols`
  echo "${BYellow}$1${Reset}\n" | fold -sw $(( $T_COLS - 1 ))
} #}}}
print_danger() { #{{{
  T_COLS=`tput cols`
  echo "${BRed}$1${Reset}\n" | fold -sw $(( $T_COLS - 1 ))
} #}}}
contains_element() { #{{{
  #check if an element exist in a string
  for e in "${@:2}"; do [[ $e == $1 ]] && break; done;
} #}}}
is_package_installed() { #{{{
  #check if a package is already installed
  for PKG in $1; do
    pacman -Q $PKG &> /dev/null && return 0;
  done
  return 1
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

print_title "https://wiki.archlinux.org/index.php/Arch_Install_Scripts"
print_info "The Arch Install Scripts are a set of Bash scripts that simplify Arch installation."
while true
do
  print_title "ARCHLINUX ULTIMATE INSTALL - https://github.com/helmuthdu/aui"
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
