#!/bin/bash

TARGET="../../www/content/games/ugl"

mv project.xml .tmp.xml

for f in src/*; do
  ./select.py "$f"
  lime build flash
  if [ $? == 0 ]; then
    N=`echo "$f" | cut -c 5- | rev | cut -c 4- | rev`
    echo "$N"
    cp bin/flash/bin/$N.swf "$TARGET"
  fi
done

rm -f project.xml
mv .tmp.xml project.xml

