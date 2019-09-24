#!/bin/bash
for i in `seq 1 5`    ## coarsening level
    do
        ratio=$(case "$i" in
            (1)  echo 2;; 
            (2)  echo 5;;
            (3)  echo 9;;
            (4)  echo 27;;
            (5)  echo 60;;
        esac)
        python graphzoom.py -m deepwalk -d pubmed -r ${ratio}
    done
