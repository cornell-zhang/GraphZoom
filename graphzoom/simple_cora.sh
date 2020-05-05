#!/bin/bash
for i in `seq 1 5`    ## coarsening level
    do
        python graphzoom.py -m deepwalk -d cora -v $i -o simple
    done
