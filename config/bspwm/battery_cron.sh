#! /bin/bash

alert="󱃍"
low="󰁺"

low_limit=15
alert_limit=8

battery=BAT0

state=$(cat /sys/class/power_supply/$battery/status)
current=$(cat /sys/class/power_supply/$battery/charge_now)
full=$(cat /sys/class/power_supply/$battery/charge_full)

pct=$((current * 100 / full))

notify() {
    notify-send -t 15000 -u "$1" "$2"
    play /usr/share/sounds/freedesktop/stereo/dialog-error.oga 2> /dev/null
}

if [[ $state != "Discharging" ]]; then
    exit 0
fi

if [[ $pct -le $alert_limit ]]; then
    notify critical "$alert Battery extremely low! (< $alert_limit)"
elif [[ $pct -le $low_limit ]]; then
    notify normal "$low Battery < $low_limit!"
fi
