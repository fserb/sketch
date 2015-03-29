#!/bin/bash

mv project.xml .tmp.xml

ERROR=0

for f in src/*; do
  echo "$f"
  ./select.py "$f"
  haxelib run lime build html5
  if [ $? != 0 ]; then ERROR=1; fi
done

rm -f project.xml
mv .tmp.xml project.xml

exit $ERROR

