#!/bin/bash

TARGET="../../www/content/games/ugl"

mv project.xml .tmp.xml

for f in src/*; do
  ./select.py "$f"
  D=`cat "$f" | grep -v "//" | grep Game.debug`
  if [ "$D" == "" ]; then
    lime build flash
    if [ $? == 0 ]; then
      N=`echo "$f" | cut -c 5- | rev | cut -c 4- | rev`
      echo "$N"
      cp bin/flash/bin/$N.swf "$TARGET"
    fi
  else
    N=`echo "$f" | cut -c 5- | rev | cut -c 4- | rev`
    echo "$N: skipped because it contains debug info."
  fi
done

rm -f project.xml
mv .tmp.xml project.xml

