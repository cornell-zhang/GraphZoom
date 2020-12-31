import torch
from torch_geometric.nn import Node2Vec

from ogb.nodeproppred import PygNodePropPredDataset


def node2vec(edge_index):
    embedding_dim = 128
    walk_length = 40
    context_size = 20
    walks_per_node = 10
    batch_size = 256
    lr = 0.01
    epochs = 1
    log_steps = 1

    device = f'cuda:{0}' if torch.cuda.is_available() else 'cpu'
    device = torch.device(device)

    model = Node2Vec(edge_index, embedding_dim, walk_length,
                     context_size, walks_per_node,
                     sparse=True).to(device)

    loader = model.loader(batch_size=batch_size, shuffle=True,
                          num_workers=4)
    optimizer = torch.optim.SparseAdam(list(model.parameters()), lr=lr)

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
    return model.embedding.weight.data.cpu().numpy(), total_params
