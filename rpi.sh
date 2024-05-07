#!/bin/bash

###
# Helper scripts for setting various parameters and config for 
# Raspberry Pi units running Raspberry Pi OS.
###

display_help() {
    echo "Raspberry Pi Dash additional install helpers Version 0.3"
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -arb, --addrulebrightness        Add udev rules for brightness"
    echo "   -adi, --adddesktopicon           Add desktop icon"
    echo "   -asd, --autostartdaemon          Add autostart daemon"
    echo "   -axi, --addxinit                 Add xinit autostart"
    echo "   -mem, --memorysplit              Set memory split"
    echo "   -gl,  --gldriver                 Set GL driver"
    echo "   -krn, --krnbt                    Set krnbt flag"
    echo "   -h, --help                       Show help of script"
    echo
    echo
    echo "Example: Setup udev rule for controlling brightness of an official 7inch Touch screen"
    echo "   rpi -arb"
    echo
    echo "Example: Add an desktop icon on your RPI."
    echo "   rpi -adi"
    echo
    echo "Example: Add autostart daemon on your RPI."
    echo "   rpi -asd"
    echo
    echo "Example: Set memory split on your RPI."
    echo "   rpi -mem 128"
    echo
    echo "Example: Set GL driver on your RPI."
    echo "   rpi -gl [G2|G1]"
    echo "   KMS (G2) / Fake KMS (G1)"
    echo
    echo "Example: Set krnbt flag on your RPI."
    echo "   rpi -krn"
    echo
    exit 1
}

add_brightness_udev_rule() {
  FILE=/etc/udev/rules.d/52-dashbrightness.rules
  if [[ ! -f "$FILE" ]]; then
     # udev rules to allow write access to all users for Raspberry Pi 7" Touch Screen
     echo "SUBSYSTEM==\"backlight\", RUN+=\"/bin/chmod 666 /sys/class/backlight/%k/brightness\"" | sudo tee $FILE
     if [[ $? -eq 0 ]]; then
         echo -e "Permissions created\n"
     else
         echo -e "Unable to create permissions\n"
     fi
  else
     echo -e "Rules exists\n"
  fi
}

add_desktop_icon () {
  # Remove existing opendash desktop
  rm $HOME/Desktop/opendash.desktop

    
  # Copy icon to pixmaps folder
  sudo cp assets/icons/opendash.xpm /usr/share/pixmaps/opendash.xpm

  # Create shortcut on dashboard
  bash -c "echo '[Desktop Entry]
Name=OpenDash
Comment=Open OpenDash
Icon=/usr/share/pixmaps/opendash.xpm
Exec=$HOME/dash/bin/dash
Type=Application
Encoding=UTF-8
Terminal=true
Categories=None;
  ' > $HOME/Desktop/opendash.desktop"
}

create_autostart_daemon() {
  WorkingDirectory="$HOME/dash"
  if [[ $2 != "" ]]
  then
     WorkingDirectory="$HOME/$2/dash"
  fi
  echo ${WorkingDirectory}

  # Stop and disable dash service
  sudo systemctl stop dash.service || true
  sudo systemctl disable dash.service || true

  # Remove existing dash service
  sudo systemctl unmask dash.service || true

  # Write dash service unit
  sudo bash -c "echo '[Unit]
Description=Dash
After=graphical.target

[Service]
Type=idle
User=$USER
StandardOutput=inherit
StandardError=inherit
Environment=DISPLAY=:0
Environment=XAUTHORITY=${HOME}/.Xauthority
WorkingDirectory=${WorkingDirectory}
ExecStart=${WorkingDirectory}/bin/dash
Restart=on-failure
RestartSec=5s
KillMode=process
TimeoutSec=infinity

[Install]
WantedBy=graphical.target
  ' > /etc/systemd/system/dash.service"

  # Activate and start dash ervice
  sudo systemctl daemon-reload
  sudo systemctl enable dash.service
  sudo systemctl start dash.service
  sudo systemctl status dash.service
}

add_xinit_autostart () {
  # Install dependencies
  sudo apt install -y xserver-xorg xinit

  # Create .xinitrc
  cat <<EOT > $HOME/.xinitrc
#!/usr/bin/env sh
xset -dpms
xset s off
xset s noblank

while [ true ]; do
  sh $HOME/run_dash.sh
done
EOT

  # Create runner
  cat <<EOT > $HOME/run_dash.sh
#!/usr/bin/env sh
$HOME/dash/bin/dash >> $HOME/dash/bin/dash.log 2>&1
sleep 1
EOT

  # Append to .bashrc
  cat <<EOT >> $HOME/.bashrc
if [ "$(tty)" = "/dev/tty1" ]; then
  startx
fi
EOT

  # Enable autologin
  sudo raspi-config nonint do_boot_behaviour B2
}

set_memory_split() {
  sudo raspi-config nonint do_memory_split $2
  if [[ $? -eq 0 ]]; then
     echo -e "Memory set to 128mb\n"
  else
     echo "Setting memory failed with error code $? please set manually"
     exit 1
  fi
}

set_opengl() {
  sudo raspi-config nonint do_gldriver $2
  if [[ $? -eq 0 ]]; then
     echo -e "OpenGL set ok\n"
  else
     echo "Setting openGL failed with error code $? please set manually"
     exit 1
  fi
}

enable_krnbt() {
  echo "enabling krnbt to speed up boot and improve stability"
  echo "dtparam=krnbt" >> /boot/config.txt
}

# Check if Raspberry Pi OS is active, otherwise kill script
if [ ! -f /etc/rpi-issue ]
then
 echo "This script works only for Raspberry Pi OS"
 exit 1;
fi

# Main Menu
while :
do
    #echo "$1"
    case "$1" in
        -arb | --addrulebrightness)
            add_brightness_udev_rule
            exit 0
          ;;
        -adi | --adddesktopicon)
            add_desktop_icon
            exit 0
          ;;
        -asd | --autostartdaemon)
            if [ $# -ne 0 ]; then
              create_autostart_daemon $2
              exit 0
            fi
          ;;
        -axi | --addxinit)
            if [ $# -ne 0 ]; then
              add_xinit_autostart
              exit 0
            fi
          ;;
        -mem | --memorysplit)
            if [ $# -ne 0 ]; then
              set_memory_split $2
              exit 0
            fi
          ;;
        -gl | --gldriver)
            if [ $# -ne 0 ]; then
              set_opengl $2
              exit 0
            fi
          ;;
        -krn | --krnbt)
            enable_krnbt
            exit 0
          ;;          
        -h | --help)
            display_help  # Call your function
            exit 0
          ;;
        "")  # If $1 is blank, run display_help
            display_help
            exit 0
          ;;
        --) # End of all options
            shift
            break
          ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            ## or call function display_help
            exit 1
          ;;
        *)  # No more options
            break
          ;;
    esac
done