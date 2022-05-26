#!/usr/bin/env bash

dir=$1
# dir should be one of east,west,north,south

window=$(yabai -m query --windows --window | jq -r '.id') 

# Stack this window onto existing stack if possible
yabai -m window $dir --stack $window 
if [[ $? -ne 0 ]]; then
    # otherwise, float and un-float this window to reinsert it into 
    # the bsp tree as a new window
    yabai -m window --insert $dir
    yabai -m window $window --toggle float 
    yabai -m window $window --toggle float
fi
