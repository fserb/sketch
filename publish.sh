#!/bin/bash

TARGET="../../www/content/games/ugl"

mv project.xml .tmp.xml

SOURCE="src/*"

if [ "$1" != "" ]; then
  SOURCE="$1"
fi

for f in $SOURCE; do
  ./select.py "$f" "prod"
  N=`echo "$f" | cut -c 5- | rev | cut -c 4- | rev`
  D=`cat "$f" | grep "//@ *ugl.skip"`
  if [ "$D" == "" ]; then
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
      cp bin/html5/bin/soundjs.min.js "$TARGET/$N/"
    fi
  else
    echo "$N: skipped."
  fi
done

rm -f project.xml
mv .tmp.xml project.xml

