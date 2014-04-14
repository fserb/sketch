#!/bin/bash

mv project.xml .tmp.xml

ERROR=0

for f in src/*; do
  echo "$f"
  ./select.py "$f"
  lime build flash
  if [ $? != 0 ]; then ERROR=1; fi
done

rm -f project.xml
mv .tmp.xml project.xml

exit $ERROR

