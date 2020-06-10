#!/bin/bash

if [ -n "$DISPLAY" ]; then 
  ./nextflow run main.nf -resume "$@" | nf-monitor --open true
else 
  command -v xvfb-run >/dev/null 2>&1 || { echo >&2 "If $DISPLAY not set, need to install 'sudo apt-get install xvfb libxrender1 libxtst6 libxi6 '"; exit 1; }
  xvfb-run ./nextflow run main.nf -resume "$@" | nf-monitor --open false
fi

