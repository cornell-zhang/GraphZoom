import numpy as np
import networkx as nx
import sys
from argparse import ArgumentParser
import json
from networkx.readwrite import json_graph
import time

from embed_methods.deepwalk.deepwalk import *
from embed_methods.node2vec.node2vec import *
from embed_methods.netmf.netmf import *
from embed_methods.graphsage.graphsage import *
from scoring import lr


def main():
    parser = ArgumentParser(description="Original")
    parser.add_argument("-d", "--dataset", type=str, default="cora", help="input dataset")
    parser.add_argument("-e", "--embed_path", type=str, default="embed_results/original_embeddings.npy", help="path of embedding result")
    parser.add_argument("-m", "--embed_method", type=str, default="deepwalk", help="specific embedding method")
    parser.add_argument("-f", "--fusion", default=False, action="store_true", help="whether use graph fusion")
    
    parser.add_argument("-g", "--sage_model", type=str, default="mean", help="aggregation function in graphsage")
    parser.add_argument("-w", "--sage_weighted", type=bool, default=False, help="whether consider weighted reduced graph")

    args = parser.parse_args()

    dataset = args.dataset
    mtx_path = "dataset/{}/{}.mtx".format(dataset, dataset)
    save_dir = args.embed_path
    eval_dataset = "dataset/{}/".format(dataset)
    embed_method = args.embed_method

    print("%%%%%% Starting Graph Embedding %%%%%%")
    if embed_method == "graphsage":
        G_data = json.load(open("dataset/{}/{}-G.json".format(dataset, dataset)))
        G = json_graph.node_link_graph(G_data)
        feature = np.load("dataset/{}/{}-feats.npy".format(dataset, dataset))
        embed_start = time.process_time()
        embeddings = graphsage(G, feature, args.sage_model, args.sage_weighted, 10000)
        embed_end = time.process_time()

    else:
        G = nx.Graph()
        with open(mtx_path) as ff:
            for i,line in enumerate(ff):
                info = line.split()
                if i < 2:
                    continue
                elif i == 2:
                    num_nodes = int(info[0])
                elif int(info[0]) != int(info[1]):
                    G.add_edge(int(info[0])-1, int(info[1])-1, wgt=abs(float(info[2])))
        for i in range(num_nodes):
            G.add_node(i)

        embed_start = time.process_time()
        if embed_method == "deepwalk":
            embeddings = deepwalk(G)
        elif embed_method == "node2vec":
            embeddings = node2vec(G)
        elif embed_method == "netmf":
            embeddings = netmf(G)
        embed_end = time.process_time()
    total_embed_time = embed_end - embed_start

    np.save(save_dir, embeddings)

    lr(eval_dataset, save_dir, dataset)

    print("Total Baseline Embedding Time: {}".format(total_embed_time))


if __name__ == "__main__":
    sys.exit(main())
