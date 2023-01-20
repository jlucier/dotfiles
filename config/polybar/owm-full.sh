#!/bin/sh
#
#   weather script, ~/.config/i3/openweathermap-smart.sh
#   usage: ./<path to>/openweathermap-smart.sh [options]
#           -f   exclude the forecast for changing weather
#           -s   exclude sunset and sunrise
#           -m   exclude the visible moon

#   adapted from https://github.com/polybar/polybar-scripts
#   created: 2022, December

#   integrate in …/polybar/config.ini
#	[[bar/polybar]]
#	type= custom/script
#	exec= ~/polybar-scripts/openweathermap-smart.sh
#	interval= 600

#	integrate in …/i3/config.toml:
#	[[block]]
#	block= "custom"
#	interval= 600
#	command= "~/.config/i3/openweathermap-smart.sh -s -f"
#	on_click= "xdg-open https://www.yr.no/en/forecast/graph/2-2940132"      # adapt your city-code


#   ─────────────────────── user provded prarameters ───────────────────────
KEY=$(cat ~/.config/polybar/.owm.key)
UNITS="imperial"
SYMBOL="°"          # example: °F, °C
API="https://api.openweathermap.org/data/2.5"


#   ─────────────────────── functions ───────────────────────
round() {           # round $1 to $2 decimal places
    printf "%.${2:-0}f" "$1"
}

get_icon() {
    case $1 in
        # Icons for weather-icons
        01d) icon="盛";;
        01n) icon="";;
        02d) icon="";;
        02n) icon="";;
        03*) icon="";;
        04*) icon="";;
        09d) icon="";;
        09n) icon="";;
        10d) icon="";;
        10n) icon="";;
        11d) icon="";;
        11n) icon="";;
        13*) icon="";;
        50*) icon="";;
        *) icon="";
    esac
    echo "%{F#c76bd3}$icon%{F-}"
}

#   ─────────────────────── script ───────────────────────
#   read the flags given
sun=true   # default to display sunrise and sunset
fc=true    # default to display the forecast
moon=true  # defalut to display the moon
while getopts sfm option; do
    case $option in
        s)  sun=false;;       # do not display sunrise and sunset if option ‘-s‘ is set.
        f)  fc=false;;        # do not display forecast if option ‘-f’ is set.
        m)  moon=false;;      # do not display the moon if the flag ‘-m’ is set.
    esac
done

#	grab the position
if [ ! -n "$LATITUDE" ] || [ ! -n "$LONGITUDE" ]; then
    location=$(curl -sf "https://location.services.mozilla.com/v1/geolocate?key=geoclue")
    if [ -n "$location" ]; then
        LATITUDE="$(echo "$location" | jq '.location.lat')"
        LONGITUDE="$(echo "$location" | jq '.location.lng')"
fi; fi

#	grab the weather data from API at openweatermap.com
current=$(curl -sf "$API/weather?appid=$KEY&lat=$LATITUDE&lon=$LONGITUDE&units=$UNITS")
forecast=$(curl -sf "$API/forecast?appid=$KEY&lat=$LATITUDE&lon=$LONGITUDE&units=$UNITS&cnt=1")

#	process the weather
if [ -n "$current" ] && [ -n "$forecast" ]; then
    current_id=$(echo "$current" | jq -r ".weather[0].id")               # weather id
    current_desc=$(echo "$current" | jq -r ".weather[0].main")           # weather description
    current_icon=$(echo "$current" | jq -r ".weather[0].icon")           # forecast icon
    current_temp=$(round $(echo "$current" | jq ".main.temp"))           # forecast temperature

    now=$(date +%s)		# ‘now’ used as a global variable
#	simple weather text
    STRING="$(get_icon "$current_icon") $current_desc $current_temp$SYMBOL"

#	forecast for changing weather conditions, if desired
    if [ "$fc" = true ]; then
        forecast_id=$(echo "$forecast" | jq -r ".list[].weather[0].id")      # forecast id
        forecast_icon=$(echo "$forecast" | jq -r ".list[].weather[0].icon")  # forecast icon
        forecast_temp=$(round $(echo "$forecast" | jq ".list[].main.temp"))  # forecast temperature
        forecast_pop=$(echo "$forecast" | jq ".list[].pop")                  # probability %
        forecast_pop=$(echo "scale=0; (100* $forecast_pop+ 0.5)/ 1" | bc)
        if ( [ $current_id -ge 700 ] && [ $forecast_id -lt 700 ] ) || ( [ $current_id -le 700 ] && [ $forecast_id -gt 700 ] ) || ( [ $current_temp -gt 0 ] && [ $forecast_temp -le 0 ] ) ; then
            if [ $forecast_pop -gt 0 ]; then
                probability=$(echo " ("$forecast_pop"%)")
            fi
            STRING="$(get_icon "$forecast_icon" "$forecast_pop") $forecast_temp$SYMBOL expected$probability"
    fi; fi

#	append sunset and sunrise, if desired
    if [ "$sun" = true ]; then
        sun_rise=$(echo "$current" | jq ".sys.sunrise")
        sun_set=$(echo "$current" | jq ".sys.sunset")
        if [ $sun_rise -gt 0 ] && [ $sun_set -gt 0 ]; then
            if [ $(date --date="22:05" +%s) -lt $now ] || [ $(($now+570)) -lt $sun_rise ]; then   # sunrise
               	tmp=$(echo $(date --date="@$sun_rise" +%k:%M))		# this removes padding blanks
                STRING="$STRING 🌄 $tmp"
            elif [ $now -lt $sun_set ] && [ $(($now+5000)) -gt $sun_set ]; then
                STRING="$STRING 🌇 $(date --date="@$sun_set" +%k:%M)"
    fi; fi; fi
    echo "$STRING"
else            # possibly no internet connection
    echo ""
fi
