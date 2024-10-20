#!/bin/bash

# Capture the current screen
grim /tmp/screen.png

# Blur the captured screen
convert /tmp/screen.png -blur 0x8 /tmp/blurred-screen.png

# Lock the screen with swaylock, using the blurred image
swaylock -f -i /tmp/blurred-screen.png

