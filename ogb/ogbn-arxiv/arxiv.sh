#!/bin/bash
python main.py -r 2 -m node2vec -d arxiv -o lamg -f --mcr_dir $1
python mlp.py --use_node_embedding
