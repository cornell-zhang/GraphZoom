# ogbn-products

This repository includes the following example scripts:

* **[MLP](https://github.com/cornell-zhang/GraphZoom/blob/master/ogb/ogbn-products/mlp.py)**: Full-batch MLP training based on paper features and graph embedding features (`--use_node_embedding`).
* **[Embedding with GraphZoom](https://github.com/cornell-zhang/GraphZoom/blob/master/ogb/ogbn-products/main.py)**: Training embedding with GraphZoom applied. The default embedding method is Node2Vec (implemented in `node2vec.py`).

## Getting Started

Follow the [installation guide](https://github.com/cornell-zhang/GraphZoom/blob/master/README.md#installation) in the root directory.

## Training & Evaluation

```bash
# Run with default config
bash products.sh YOUR_MCR_ROOT_DIR
```

## Results
GraphZoom-i denotes applying GraphZoom with i-th coarsening level, and the results of Node2vec baseline are taken from the [OGB Leaderboard](https://ogb.stanford.edu/docs/leader_nodeprop/)
| Method        | Accuracy       | #Params     | 
| :-----------: |:--------------:| :----------:| 
| Node2vec      | 72.49 ± 0.10   | 313,612,207 | 
| GraphZoom-1   | 74.06 ± 0.26   | 120,251,183 |