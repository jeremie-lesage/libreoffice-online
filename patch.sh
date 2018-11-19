#!/bin/bash

for p in patches/*patch
do
  if [ -f "$p" ]
  then
    echo "-- PATCH $p --"
    patch --batch -p1 -i "$p"
  fi
done
