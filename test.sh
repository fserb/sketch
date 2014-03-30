#!/bin/bash

for f in src/*; do
  ./select.py "$f"
  lime build flash
done
