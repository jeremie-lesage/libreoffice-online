#!/bin/bash
for p in `ls patches/*patch`; do
  echo "-- PATCH $p --"
  patch --batch -p1 -i "$p"
done
