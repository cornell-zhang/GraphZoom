import argparse
import numpy as np
import networkx as nx

import torch
from torch.utils.data import DataLoader

from torch_geometric.nn import Node2Vec
from torch_geometric.utils import to_undirected


def node2vec(G):
    embedding_dim = 128
    walk_length = 80
    context_size = 20
    walks_per_node = 10
    batch_size = 256
    lr = 0.01
    epochs = 5
    log_steps = 1

    device = f'cuda:{0}' if torch.cuda.is_available() else 'cpu'
    device = torch.device(device)
    torch.manual_seed(1)

    G.remove_edges_from(nx.selfloop_edges(G))
    num_nodes = len(G.nodes())
    num_edges = len(G.edges())
    edge_index = np.zeros((2, num_edges))
    cnt = 0
    for e in G.edges():
        edge_index[0][cnt] = int(e[0])
        edge_index[1][cnt] = int(e[1])
        cnt += 1
    edge_index = torch.from_numpy(edge_index).long().to(device)
    edge_index = to_undirected(edge_index, num_nodes)

    model = Node2Vec(edge_index, embedding_dim, walk_length,
                     context_size, walks_per_node, sparse=True).to(device)

    optimizer = torch.optim.SparseAdam(model.parameters(), lr=lr)
    loader = model.loader(batch_size=batch_size, shuffle=True, num_workers=4)

    model.train()
    for epoch in range(1, epochs + 1):
        for i, (pos_rw, neg_rw) in enumerate(loader):
            optimizer.zero_grad()
            loss = model.loss(pos_rw.to(device), neg_rw.to(device))
            loss.backward()
            optimizer.step()

            if (i + 1) % log_steps == 0:
                print(f'Epoch: {epoch:02d}, Step: {i+1:03d}/{len(loader)}, '
                      f'Loss: {loss:.4f}')

    total_params = sum(p.numel() for p in model.parameters())
    print(f'node2vec total params are {total_params}')
    return model.embedding.weight.data.cpu().numpy()


