#!/bin/bash

for f in src/*; do
  NAME=`echo "$f" | cut -c5- | rev | cut -c4- | rev`
  ./select.py $NAME
  lime build flash
done
