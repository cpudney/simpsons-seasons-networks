#/bin/sh
# Usage: makeimage season_number

# SVG to PNG
inkscape z -e graph.png -b \#ffffff -h 4096 graph.svg

# Label images
convert -fill black -pointsize 120 -font Purisa-Bold label:"Season $1" miff:- | composite -gravity northwest -geometry +30+30 - graph.png tmp.png
mv tmp.png graph.png
