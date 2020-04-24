#!/bin/sh
# Script for downloading and installing the latest Hyperion.NG release on LibreElec

#Mensaje de Bienvenida
echo '*******************************************************************************' 
echo 'Este script instala Hyperion.NG en Batocera Raspberry Pi 4'
echo 'Creado por brindosch y Modificado por aka.kuro - hyperion-project.org - the official Hyperion source.' 
echo '*******************************************************************************'

# Find out if we are on Batocera
OS_BATOCERA=`grep -m1 -c "PLAY AGAIN" /etc/issue`
# Check that
if [ $OS_BATOCERA -ne 1 ]; then
	echo '---> Error Critico: No es SO Batocera -> Saliendo'
	exit 1
fi

# Find out if we are on an Raspberry Pi
CPU_RPI=`grep -m1 -c 'BCM2708\|BCM2709\|BCM2710\|BCM2835\|BCM2836\|BCM2837\|BCM2711' /proc/cpuinfo`
# Check that
if [ $CPU_RPI -ne 1 ]; then
	echo '---> Eroor Critico: No esta funcionando el script en una Raspberry Pi -> Saliendo'
	exit 1
fi

#Check which RPi we are one (in case)
RPI_1=`grep -m1 -c 'BCM2708\|BCM2835' /proc/cpuinfo`
RPI_2_3_4=`grep -m1 -c 'BCM2709\|BCM2710\|BCM2836\|BCM2837\|BCM2711' /proc/cpuinfo`

# check which init script we should use
USE_SYSTEMD=`grep -m1 -c systemd /proc/1/comm`

# Make sure that the boblight daemon is no longer running
BOBLIGHT_PROCNR=$(pidof boblightd | wc -l)
if [ $BOBLIGHT_PROCNR -eq 1 ]; then
	echo '---> Critical Error: Found running instance of boblight. Please stop boblight via Kodi menu before installing Hyperion.NG -> abort'
	exit 1
fi

#Check, if dtparam=spi=on is in place
SPIOK=`grep '^\dtparam=spi=on' /boot/config.txt | wc -l`
if [ $SPIOK -ne 1 ]; then
	mount -o remount,rw /boot
	echo '---> RPi with LibreELEC found, but SPI is not set, we write "dtparam=spi=on" to /flash/config.txt'
	sed -i '$a dtparam=spi=on' /boot/config.txt
	mount -o remount,ro /boot
	REBOOTMESSAGE="echo Please reboot LibreELEC, we inserted dtparam=spi=on to /flash/config.txt"
fi
 
# Select the appropriate download path
HYPERION_DOWNLOAD_URL="https://github.com/hyperion-project/hyperion.ng/releases/download"
HYPERION_RELEASES_URL="https://api.github.com/repos/hyperion-project/hyperion.ng/releases"

# Get the latest version
HYPERION_LATEST_VERSION=$(curl -sL "$HYPERION_RELEASES_URL" | grep "tag_name" | head -1 | cut -d '"' -f 4)

# Select the appropriate release
if [ $RPI_1 -eq 1 ]; then
	HYPERION_RELEASE=$HYPERION_DOWNLOAD_URL/$HYPERION_LATEST_VERSION/Hyperion-$HYPERION_LATEST_VERSION-Linux-armv6hf-rpi.tar.gz
elif [ $RPI_2_3_4 -eq 1 ]; then
	HYPERION_RELEASE=$HYPERION_DOWNLOAD_URL/$HYPERION_LATEST_VERSION/Hyperion-$HYPERION_LATEST_VERSION-Linux-armv7hf-rpi.tar.gz
else
	echo "---> Critical Error: Target platform unknown -> abort"
	exit 1
fi

# Get and extract Hyperion.NG
echo '---> Downloading latest release'
mkdir /userdata/hyperion
curl -# -L --get $HYPERION_RELEASE | tar --strip-components=1 
-C /userdata/hyperion -x
#set the executen bit (failsave)
chmod +x -R /userdata/hyperion/bin
