#!/bin/bash
# You can add the flag [--resume] to only run the embedding and refinement if you
# already have the coarsened graph information saved.
python main.py -r 2 -m node2vec -d products -o lamg --mcr_dir $1
python mlp.py --use_node_embedding
