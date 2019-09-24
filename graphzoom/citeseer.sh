#!/bin/bash
for i in `seq 1 5`    ## coarsening level
    do
        ratio=$(case "$i" in
            (1)  echo 2;; 
            (2)  echo 5;;
            (3)  echo 12;;
            (4)  echo 25;;
            (5)  echo 50;;
        esac)
        python graphzoom.py -m deepwalk -d citeseer -r ${ratio} -n 10
done
