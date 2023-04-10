#!/usr/bin/env bash

cd $(dirname "$0") || exit

bubblewrapdate=$(git log -1 --format="%at")
curdate=$(date +%s)
((curdate-=86400))
echo $bubblewrapdate $curdate
if [[ $curdate -lt $bubblewrapdate ]]; then
  exit 0
fi
exit 1
