# ogbn-arxiv

This repository includes the following example scripts:

* **[MLP](https://github.com/cornell-zhang/GraphZoom/blob/master/ogb/ogbn-arxiv/mlp.py)**: Full-batch MLP training based on paper features and graph embedding features (`--use_node_embedding`).
* **[Embedding with GraphZoom](https://github.com/cornell-zhang/GraphZoom/blob/master/ogb/ogbn-arxiv/main.py)**: Training embedding with GraphZoom applied. The default embedding method is Node2Vec (implemented in `node2vec.py`).

## Getting Started

Follow the [installation guide](https://github.com/cornell-zhang/GraphZoom/blob/master/README.md#installation) in the root directory.

## Training & Evaluation

```bash
# Generate arxiv dataset
python ogb_parser.py

# Run with default config
bash arxiv.sh YOUR_MCR_ROOT_DIR
```

## Results
GraphZoom-i denotes applying GraphZoom with i-th coarsening level, and the results of Node2Vec baseline are taken from the [OGB Leaderboard](https://ogb.stanford.edu/docs/leader_nodeprop/)
| Method        | Accuracy       | #Params   | 
| :-----------: |:--------------:| :--------:| 
| Node2Vec      | 70.07 ± 0.13   | 21,818,792| 
| GraphZoom-1   | 71.18 ± 0.18   | 8,963,624 | 