#!/bin/bash

## [ Parameters ] ##############################################################
gpio_pin_light=17
path_table_date_dawnDuskTime=$(dirname $0)/table_date_dawnDuskTime.csv


## [ Logic ] ##################################################################
# Disable GPIO when exiting
function exit_trap {
    echo "${gpio_pin_light}" > /sys/class/gpio/unexport
    echo "GPIO ${gpio_pin_light} disabled"
    systemd-cat --identifier ${0} --priority info echo "GPIO ${gpio_pin_light} disabled"
}
trap exit_trap EXIT

# Enable GPIO and set it as output
if [ ! -d /sys/class/gpio/gpio${gpio_pin_light} ];then
    echo "${gpio_pin_light}" > /sys/class/gpio/export
    sleep 1
    echo "GPIO ${gpio_pin_light} enabled"
    systemd-cat --identifier ${0} --priority info echo "GPIO ${gpio_pin_light} enabled"
else
    echo "GPIO ${gpio_pin_light} already enabled"
    systemd-cat --identifier ${0} --priority info echo "GPIO ${gpio_pin_light} already enabled"
fi

if [ "$(cat /sys/class/gpio/gpio${gpio_pin_light}/direction)" != "out" ]; then
    echo "out" > /sys/class/gpio/gpio${gpio_pin_light}/direction
    echo "GPIO ${gpio_pin_light} configured as output"
    systemd-cat --identifier ${0} --priority info echo "GPIO ${gpio_pin_light} configured as output"
else
    echo "GPIO ${gpio_pin_light} already configured as output"
    systemd-cat --identifier ${0} --priority info echo "GPIO ${gpio_pin_light} already configured as output"
fi
echo

while true; do
    _date=$(date "+%m%d")
    _time=$(date "+%H%M")
    _dawn=$(grep "${_date}" "${path_table_date_dawnDuskTime}" | cut -d',' -f2 || { echo "Date \"${_date}\" not found in ${path_table_date_dawnDuskTime}"; exit 1; })
    _dusk=$(grep "${_date}" "${path_table_date_dawnDuskTime}" | cut -d',' -f3 || { echo "Date \"${_date}\" not found in ${path_table_date_dawnDuskTime}"; exit 1; })

    if [ "${_time}" -ge "${_dusk}" ] || [ "${_time}" -le "${_dawn}" ]; then
        echo "1" > /sys/class/gpio/gpio${gpio_pin_light}/value
        if [ ${toggle:=0} -eq 0 ]; then
            echo "Switch fairy light on"
            systemd-cat --identifier ${0} --priority info echo "Switch fairy light on"
        fi
        toggle=1
    else
        echo "0" > /sys/class/gpio/gpio${gpio_pin_light}/value
        if [ ${toggle:=0} -eq 1 ]; then
            echo "Switch fairy light off"
            systemd-cat --identifier ${0} --priority info echo "Switch fairy light off"
        fi
        toggle=0
    fi

    sleep 1m
done
