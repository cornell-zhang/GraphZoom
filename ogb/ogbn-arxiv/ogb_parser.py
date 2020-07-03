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

d_name = "ogbn-arxiv"
dataset_str = d_name.replace("ogbn-","")
dataset = NodePropPredDataset(name = d_name)
num_tasks = dataset.num_tasks # obtaining the number of prediction tasks in a dataset

split_idx = dataset.get_idx_split()
train_idx, valid_idx, test_idx = split_idx["train"], split_idx["valid"], split_idx["test"]

graph, label = dataset[0] # graph: library-agnostic graph object
if dataset_str == "arxiv":
    da = PygNodePropPredDataset(name='ogbn-arxiv')
    d = da[0]
    edge_index = d.edge_index
    edge_index = to_undirected(edge_index, d.num_nodes)
    edgelist = (edge_index.data).cpu().numpy()
else:
    edgelist = graph["edge_index"]

num_nodes = graph["num_nodes"]
G = nx.Graph()

os.makedirs(f"dataset/{dataset_str}/", exist_ok=True)
with open("dataset/{}/{}-class_map.json".format(dataset_str, dataset_str), 'w') as f:
    f.write('{')
    for i in range(num_nodes):
        if i > 0:
            f.write(', ')
        f.write('\"'+str(i)+"\": ")
        f.write(str(label[i][0]))
    f.write('}')

pbar = tqdm.tqdm(total=edgelist.shape[1])
pbar.set_description('Adding edges to graph')
for i in range(edgelist.shape[1]):
    G.add_edge(int(edgelist[0][i]), int(edgelist[1][i]))
    pbar.update(1)

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
with open("dataset/{}/{}-G.json".format(dataset_str, dataset_str), 'w') as f:
    f.write(g_data)
np.save("dataset/{}/{}-feats.npy".format(dataset_str, dataset_str), graph["node_feat"])



