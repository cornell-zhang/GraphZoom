#!/bin/bash
for i in `seq 1 4`    ## coarsening level
    do
        ratio=$(case "$i" in
            (1)  echo 2;;
            (2)  echo 5;;
            (3)  echo 9;;
            (4)  echo 19;;
        esac)
        python graphzoom.py -r ${ratio} -m deepwalk
done
