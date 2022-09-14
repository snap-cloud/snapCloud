#!/bin/bash
if [[ `pwd | sed 's/.*\///'` == 'bin' ]]; then
    dir='..'
else
    dir='.'
fi
wget https://check.torproject.org/torbulkexitlist -O $dir/lib/torbulkexitlist
