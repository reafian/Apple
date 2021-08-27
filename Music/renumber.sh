#!/bin/bash

file_ext=aif

echo In $PWD
ls *.${file_ext} > /dev/null 2>&1 || { echo "No files found"; exit; }
count=$(ls *.${file_ext} | wc -l | awk '{print $1}')
echo "Working on $count files"
counter=0
ls *.${file_ext} | while read list
do
  counter=$(($counter+1))
  oldfile=$list
  value=$(printf "%02d" $counter)
  newfile=$(echo $value $(echo $list | cut -d" " -f2-))
  echo Moving "$oldfile" to "$newfile"
  mv "$oldfile" "$newfile"
  if [[ $counter == $count ]]
  then
    echo "Finished"
    exit
  fi
done
