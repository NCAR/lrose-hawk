#!/bin/bash

for f in *.raw

do

  if [ -e $f ]
  then
    perl -i -ne 'print unless 1 .. 27' "$f"
    tac "$f" | tail -n +25 | tac > hold
    mv hold "$f"
  fi

done
