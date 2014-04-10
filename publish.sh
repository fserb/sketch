#!/bin/bash

TARGET="../../www/content/games/ugl"

mv project.xml .tmp.xml

for f in src/*; do
  ./select.py "$f"
  D=`cat "$f" | grep -v "//" | grep Game.debug`
  if [ "$D" == "" ]; then
    N=`echo "$f" | cut -c 5- | rev | cut -c 4- | rev`
    echo "$N"
    mkdir -p "$TARGET/$N"
    lime build flash
    if [ $? == 0 ]; then
      cp bin/flash/bin/$N.swf "$TARGET/$N/flash.swf"
    fi
    lime build html5
    if [ $? == 0 ]; then
      cp bin/html5/bin/index.html "$TARGET/$N/"
      uglifyjs bin/html5/bin/$N.js -c -m > "$TARGET/$N/$N.js" 2>/dev/null
      cp bin/html5/bin/howler.min.js "$TARGET/$N/"
    fi
  else
    N=`echo "$f" | cut -c 5- | rev | cut -c 4- | rev`
    echo "$N: skipped because it contains debug info."
  fi
done

rm -f project.xml
mv .tmp.xml project.xml

