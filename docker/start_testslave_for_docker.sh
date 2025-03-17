#! /bin/bash

#############################################################
#####This script is used to create the docker container######
#####      Notice:  Must run under root account        ######
#############################################################


################Step 1 Copy rules to /usr/bin################

[ ! -f /usr/bin/add_dut ] && cp ./add_dut /usr/bin/add_dut
[ ! -f /usr/bin/docker-enter ] && cp ./add_dut /usr/bin/docker-enter
[ ! -f /usr/bin/nsenter ] && cp ./add_dut /usr/bin/nsenter
[ ! -f /usr/bin/remove_dut ] && cp ./add_dut /usr/bin/remove_dut
[ ! -f /usr/bin/show-device ] && cp ./add_dut /usr/bin/show-device


###############Step 2 Provide all info as request#############

tip_host_name="pls input your host name like <shsispre888l>: "
tip_port="pls input your prot number for docker container like <5001:22>: "
tip_container_name="pls input your container name <shsispre888l>: "
tip_id_board="pls input your USB device ID for board like </dev/bus/usb/002/003>: "
tip_id_debug_card="pls input your USB device ID for debug card like </dev/bus/usb/002/004>: "
tip_id_relay_card="pls input your USB device ID for relay card like </dev/bus/usb/002/005>: "
tip_relay_card_drivername="pls input driver name about your relay card like </dev/ttyUSB0>: "
tip_debug_card_drivername="pls input driver name about your debug card like </dev/ttyUSB1>: "
tip_docker_image="pls input your docker image like <ubuntu:14.04>: "

echo "#############NOTICE#############"
echo "Press ENTER if without debug card"
#press ENTER if without debug card
read -p "$tip_host_name" hostname
read -p "$tip_container_name" container_name
read -p "$tip_port" port
read -p "$tip_id_board" board_id
read -p "$tip_id_debug_card" debug_card_id
read -p "$tip_id_relay_card" relay_card_id
read -p "$tip_relay_card_drivername" relay_card_drivername
read -p "$tip_debug_card_drivername" debug_card_drivername
read -p "$tip_docker_image" docker_image

#################Step 3 Define the device rule################

[ ! -f /etc/udev/rules.d/100-persistent-net.rules ] && touch /etc/udev/rules.d/100-persistent-net.rules
line=`show-device | wc -l`

for((i=2;i<=$line;i++));  
do 
device_Name=`show-device | sed -n "${i}p" | awk '{print $1}'`
device_PCI=`show-device | sed -n "${i}p" | awk '{print $2}'` 
device_ID=`show-device | sed -n "${i}p" | awk '{print $3}'`
available_device_rule=false
if [[ $device_Name =~ "/dev/ttyUSB" ]];
then 
    echo "This is not board target, skip it"
    continue
elif [  `grep -c "${device_PCI} " /etc/udev/rules.d/100-persistent-net.rules` -eq '0' ];
then 
    if [ $board_id == $device_ID ];
    then 
        echo "#Rule for device $device_Name" >> /etc/udev/rules.d/100-persistent-net.rules
        echo "ACTION==\"add\", SUBSYSTEM==\"usb\", DEVPATH==\"$device_PCI\", RUN+=\"/usr/bin/add_dut \$attr{busnum} \$attr{devnum} \$major \$minor \$devpath '$hostname'\"" >> /etc/udev/rules.d/100-persistent-net.rules
        echo "ACTION==\"remove\", SUBSYSTEM==\"usb\", DEVPATH==\"$device_PCI\", RUN+=\"/usr/bin/remove_dut '$device_PCI'\"" >> /etc/udev/rules.d/100-persistent-net.rules
        echo -e "\n" >> /etc/udev/rules.d/100-persistent-net.rules
        available_device_rule=true
        break
    else
        echo "The device ID is different with the one you provide, skip it"
    fi
else
    echo "This device is already added to device rule, skip it"
    available_device_rule=true
    break
fi
done

################Step 3 Start docker container#################
#GUIDELINE FOR START CONTAINER:
#docker run -h <HOSTNAME> -dit -p <PORT> --name=<CONTAINRE NAME> --device=<USB ID FOR BOARD> --device=<USB ID FOR DEBUG CARD> 
#--device=<USB ID FOR RELAY CARD> --device=<DRIVER FOR RELAY>:/dev/ttyRelayCard --device=<DRIVER FOR DEBUG CARD>:/dev/ttySerial2 <DOCKER IMAGE> /bin/bash

#Example:
#docker run -h "shsispre227l" -dit -p 5001:22 --name=shsisore227l --device=/dev/bus/usb/001/023 --device=/dev/bus/usb/001/024 --device=/dev/bus/usb/001/025 --device=/dev/ttyUSB0:/dev/ttyRelayCard --device=/dev/ttyUSB2:/dev/ttySerial2 slavesetup:latest /bin/bash

if [ "$available_device_rule" = "true" ];
then
    if [ ! $debug_card_id ];
    then 
        echo "start docker container without debug card"
        docker run -h $hostname -dit -p "$port" --name $container_name --device="$board_id" --device="$relay_card_id" --device="$relay_card_drivername:/dev/ttyRelayCard" $docker_image /bin/bash
    else
        echo "start docker container with debug card"
        docker run -h $hostname -dit -p "$port" --name $container_name --device="$board_id" --device="$debug_card_id" --device="$relay_card_id" --device="$relay_card_drivername:/dev/ttyRelayCard" --device="$debug_card_drivername:/dev/ttySerial2" $docker_image /bin/bash
    fi
else
    echo "Could not start docker container!! Because,the device rule is not ready for this device, Pls Double check"
fi

