from __future__ import print_function

import numpy as np
import random
import json
import sys
import os
import multiprocessing as mp
import networkx as nx
from networkx.readwrite import json_graph
from sklearn.preprocessing import StandardScaler

version_info = list(map(int, nx.__version__.split('.')))
major = version_info[0]
minor = version_info[1]
#assert (major <= 1) and (minor <= 11), "networkx major version > 1.11"

#WALK_LEN=5
#N_WALKS=50

def load_data(G, feats, args):
    walks = []
    ## Remove all nodes that do not have val/test annotations
    ## (necessary because of networkx weirdness with the Reddit data)
    broken_count = 0
    for node in G.nodes():
        if not 'val' in G.node[node] or not 'test' in G.node[node]:
            G.remove_node(node)
            broken_count += 1
    print("Removed {:d} nodes that lacked proper annotations due to networkx versioning issues".format(broken_count))

    ## Make sure the graph has edge train_removed annotations
    ## (some datasets might already have this..)
    print("Loaded data.. now preprocessing..")
    for edge in G.edges():
        if (G.node[edge[0]]['val'] or G.node[edge[1]]['val'] or
            G.node[edge[0]]['test'] or G.node[edge[1]]['test']):
            G[edge[0]][edge[1]]['train_removed'] = True
        else:
            G[edge[0]][edge[1]]['train_removed'] = False

    train_ids = np.array([n for n in G.nodes() if not G.node[n]['val'] and not G.node[n]['test']])
    train_feats = feats[train_ids]
    scaler = StandardScaler()
    scaler.fit(train_feats)
    feats = scaler.transform(feats)
    
    walks = get_random_walks(G, args.sage_weighted, args.sage_workers, args.num_walks, args.walk_length)

    return G, feats, walks

def run_random_walks(G, nodes, num_walks, walk_length, weighted, proc_begin, proc_end, return_dict):
    pairs = []
    for i in range(num_walks):
        print("The {}-th walk".format(i))
        for start_idx in nodes[proc_begin: proc_end]:
            if G.degree(start_idx) == 0:
                continue
            curr_node = start_idx
            for _ in range(walk_length):
                if weighted:
                    wgts = []
                    for x in G.neighbors(curr_node):
                        wgts.append(G[curr_node][x]['wgt'])
                    next_node = np.random.choice(list(G.neighbors(curr_node)), p=np.asarray(wgts)/float(sum(wgts)))
                else:
                    next_node = random.choice(list(G.neighbors(curr_node)))
                # self co-occurrences are useless
                if curr_node != next_node:
                    pairs.append((next_node,curr_node))
                curr_node = next_node
    return_dict[proc_begin] = pairs

def get_random_walks(G, weighted, workers, num_walks, walk_length):
    """ Run random walks """
    print('Whether consider weighted graph??????', weighted)
    nodes = [n for n in G.nodes() if not G.node[n]["val"] and not G.node[n]["test"]]
    G = G.subgraph(nodes)
    manager = mp.Manager()
    return_dict = manager.dict()
    jobs = []
    chunk_size = len(nodes) // workers
    for i in range(workers):
        proc_begin = i * chunk_size
        proc_end = (i + 1) * chunk_size
        if i == workers - 1:
            proc_end = len(nodes)
        p = mp.Process(target=run_random_walks, args=(G, nodes, num_walks, walk_length, weighted, proc_begin, proc_end, return_dict))
        jobs.append(p)
    for p in jobs:
        p.start()
    for proc in jobs:
        proc.join()
    pairs = []
    key_arr = sorted(return_dict.keys())
    for key in key_arr:
        pairs += return_dict[key]
    return pairs
    print("Successfully writing new-walks.txt file!!!!!!")
