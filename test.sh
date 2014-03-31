#!/bin/bash

mv project.xml .tmp.xml

for f in src/*; do
  ./select.py "$f"
  lime build flash
done

rm -f project.xml
mv .tmp.xml project.xml
