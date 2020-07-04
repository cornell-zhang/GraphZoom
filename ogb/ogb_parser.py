from ogb.nodeproppred import NodePropPredDataset
import networkx as nx
from networkx.readwrite import json_graph
import json
import sys
import numpy as np
from ogb.nodeproppred import PygNodePropPredDataset
from torch_geometric.utils import to_undirected
import tqdm
import os
from argparse import ArgumentParser

parser = ArgumentParser(description="OGB Dataset Parser")
parser.add_argument("-f", "--save_feature", default=False, action="store_true",
        help="save graph feature")
parser.add_argument("-l", "--save_label", default=False, action="store_true",
        help="save dataset labels")
parser.add_argument("-d", "--dataset", type=str, default="ogbn-arxiv", 
        help="input dataset name")

args = parser.parse_args()

d_name = args.dataset
dataset_str = d_name.split("-")[1]

if dataset_str == "arxiv":
    dataset = PygNodePropPredDataset(name=d_name, root=f"{d_name}/dataset")
    d = dataset[0]
    edge_index = d.edge_index
    edge_index = to_undirected(edge_index, d.num_nodes)
    edgelist = (edge_index.data).cpu().numpy()
    num_nodes = d.num_nodes
else:
    raise NotImplementedError

split_idx = dataset.get_idx_split()
train_idx, valid_idx, test_idx = split_idx["train"], split_idx["valid"], split_idx["test"]

G = nx.Graph()
os.makedirs(f"{d_name}/dataset/{dataset_str}/", exist_ok=True)

pbar = tqdm.tqdm(total=edgelist.shape[1])
pbar.set_description('Adding edges to graph')
for i in range(edgelist.shape[1]):
    G.add_edge(int(edgelist[0][i]), int(edgelist[1][i]))
    pbar.update(1)

if args.save_label or args.save_feature:
    if dataset_str == "arxiv":
        graph, label = NodePropPredDataset(name = d_name, root=f"{d_name}/dataset")[0] # graph: library-agnostic graph object
    else:
        raise NotImplementedError
    os.makedirs(f"{d_name}/dataset/{dataset_str}/", exist_ok=True)

if args.save_label:
    with open("{}/dataset/{}/{}-class_map.json".format(d_name, dataset_str, dataset_str), 'w') as f:
        f.write('{')
        for i in range(num_nodes):
            if i > 0:
                f.write(', ')
            f.write('\"'+str(i)+"\": ")
            f.write(str(label[i][0]))
        f.write('}')

    test = {}
    valid = {}
    train = {}
    pbar = tqdm.tqdm(total=num_nodes)
    pbar.set_description('Splitting train, val, test nodes on the graph')
    for i in range(num_nodes):
        test[i] = (i in test_idx.tolist())
        valid[i] = (i in valid_idx.tolist())
        train[i] = (i in train_idx.tolist())
        pbar.update(1)
    nx.set_node_attributes(G, test, 'test')
    nx.set_node_attributes(G, train, 'train')
    nx.set_node_attributes(G, valid, 'val')


g_data = json.dumps(json_graph.node_link_data(G))
with open("{}/dataset/{}/{}-G.json".format(d_name, dataset_str, dataset_str), 'w') as f:
    f.write(g_data)

if args.save_feature:
    np.save("{}/dataset/{}/{}-feats.npy".format(d_name, dataset_str, dataset_str), graph["node_feat"])
