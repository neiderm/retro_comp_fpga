#!/bin/bash

RGB_BIN="./rgb.bmp"
RGB_OUT="./soc_t80_vga.srcs/sources_1/imports/rams/rgb.bmp.dat"
echo  "$RGB_BIN -> $RGB_OUT"

od -v  -t x1 $RGB_BIN | cut -c 9- | tr '\ ' '\n' > $RGB_OUT
