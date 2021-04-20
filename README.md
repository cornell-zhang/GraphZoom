GraphZoom
===============================

GraphZoom is a framework that aims to improve both performance and scalability of graph embedding techniques. As shown in the following figure, GraphZoom consists of 4 kernels: Graph Fusion, Spectral Coarsening, Graph Embedding, and Embedding Refinement. GraphZoom More details are available in our paper: https://openreview.net/forum?id=r1lGO0EKDH

![Overview of the GraphZoom framework](/GraphZoom.png)

Citation
------------
If you use GraphZoom in your research, please cite our preliminary work
published in ICLR'20.

```
@inproceedings{deng2020graphzoom,
title={GraphZoom: A Multi-level Spectral Approach for Accurate and Scalable Graph Embedding},
author={Chenhui Deng and Zhiqiang Zhao and Yongyu Wang and Zhiru Zhang and Zhuo Feng},
booktitle={International Conference on Learning Representations},
year={2020},
url={https://openreview.net/forum?id=r1lGO0EKDH}
}
```

Spectral Coarsening Options
------------
* lamg-based coarsening: This is the spectral coarsening algorithm used in the original paper, but it requires you to download Matlab Compiler Runtime (MCR).
* simple coarsening: This is a simpler spectral coarsening implemented via python and you do not need to download MCR. This algorithm adopts a similar idea to coarsen the graph (spectrum-preserving), while it may compromise the performance compared to lamg-based coarsening (especially for run-time speedup).

Requirements
------------
* Matlab Compiler Runtime (MCR) 2018a(Linux), which is a standalone set of shared libraries that enables the execution of compiled MATLAB applications and does not require license to install (only required if you run lamg-based coarsening).
* python 3.5/3.6/3.7 (We suggest [Conda](https://docs.conda.io/projects/conda/en/latest/index.html) to manage package dependencies.)
* numpy
* networkx
* scipy
* scikit-learn
* gensim, only required by deepwalk, node2vec
* tensorflow, only required by graphsage
* torch, ogb, pytorch_geometric, only required by [Open Graph Benchmark (OGB)](https://ogb.stanford.edu/) examples

Installation
------------
* install [matlab compiler runtime 2018a(Linux)](https://www.mathworks.com/products/compiler/matlab-runtime.html) (only required if you run lamg-based coarsening)
```
wget https://ssd.mathworks.com/supportfiles/downloads/R2018a/deployment_files/R2018a/installers/glnxa64/MCR_R2018a_glnxa64_installer.zip`
```
```
unzip MCR_R2018a_glnxa64_installer.zip -d YOUR_SAVE_PATH
```
```
cd YOUR_SAVE_PATH
```
```
./install -mode silent -agreeToLicense yes -destinationFolder YOUR_MCR_PATH
```
* install [PyTorch Geometric](https://pytorch-geometric.readthedocs.io/en/latest/notes/installation.html) (only required if you run OGB examples)
* create virtual environment (skip if you do not want)
```
conda create -n graphzoom python=3.6
conda activate graphzoom
```
* install packages for graphzoom 
```
pip install -r requirements.txt
```

Directory Stucture
------------
```
GraphZoom/
│   README.md
│   requirements.txt
│   ... 
│
└───graphzoom/
│   │   graphzoom.py
│   │   cora.sh
│   │   ...  
│   │ 
│   └───dataset/
│   │   │    cora
│   │   │    citeseer
│   │   │    pubmed
│   │  
│   └───embed_methods/
│       │    DeepWalk
│       │    node2vec
│       │    GraphSAGE
│ 
└───mat_coarsen/
│   │   make.m
│   │   LamgSetup.m
│   │   ...  
│
└───ogb/
│   │   ...
│   └───ogbn-arxiv/ 
│   │    │   main.py
│   │    │   mlp.py
│   │    │   arxiv.sh   
│   │    │   ...  
│   │    
│   └───ogbn-products/ 
│        │   main.py
│        │   mlp.py
│        │   products.sh  
│        │   ...
│
```


Usage
-----

**Note:** If you run lamg-based coarsening, you have to pass the root directory of matlab compiler runtime to the argument`--mcr_dir` when running graphzoom.py

**Example Usage**

1. `cd graphzoom`

2. `python graphzoom.py --mcr_dir YOUR_MCR_PATH --dataset citeseer --search_ratio 12 --num_neighs 10 --embed_method deepwalk --coarse lamg`

**--coarse**:  *choose a specific algorithm for coarsening, [lamg, simple]*

**--reduce_ratio**:  *the reduction ratio when choosing lamg-based coarsening method*

**--level**:  *the coarsening level when choosing simple coarsening method*

**--mcr_dir**:  *root directory of matlab compiler runtime*

**--dataset**: *input dataset, currently supports "json" format*

**--embed_method**: *choose a specific basic embedding algorithm*

**--search_ratio**: *control the search space of graph fusion*

**--num_neighs**: *control number of edges in feature graph*


**Full Command List**
The full list of command line options is available with ``python graphzoom.py --help``

Highlight in Flexibility
-------

You can easily plug a new unsupervised graph embedding model into GraphZoom, just implement a new function, which takes a graph as input and outputs an embedding matrix, in `graphzoom/embed_methods`.

The current version of GraphZoom can support the following basic models:

* DeepWalk
* node2vec
* GraphSAGE

Dataset
-------
* Cora
* Citeseer
* Pubmed

You can add your own dataset following the json format in `graphzoom/dataset`

Experimental Results
-------

Here we evaluate GraphZoom on Cora dataset with DeepWalk as basic embedding model, with lamg-based coarsening method. GraphZoom-i denotes applying GraphZoom with i-th coarsening level.

| Method        | Accuracy      | Speedup  | Graph_Size  |
| :-----------: |:-------------:| :-------:| :----------:|
| DeepWalk      | 71.4          | 1x       | 2708        |
| GraphZoom-1   | 76.9          | 2.5x     | 1169        |
| GraphZoom-2   | 77.3          | 6.3x     | 519         |
| GraphZoom-3   | 75.1          | 40.8x    | 218         |

We also evaluate Graphzoom on [ogbn-arxiv](https://ogb.stanford.edu/docs/nodeprop/#ogbn-arxiv) and [ogbn-products](https://ogb.stanford.edu/docs/nodeprop/#ogbn-products) dataset with lamg-based coarsening method, and GraphZoom-1 has better performance and much fewer parameters than the Node2vec baseline.

**ogbn-arxiv**

| Method        | Accuracy       | #Params   | 
| :-----------: |:--------------:| :--------:| 
| Node2vec      | 70.07 ± 0.13   | 21,818,792| 
| GraphZoom-1   | 71.18 ± 0.18   | 8,963,624 | 

**ogbn-products**
| Method        | Accuracy       | #Params     | 
| :-----------: |:--------------:| :----------:| 
| Node2vec      | 72.49 ± 0.10   | 313,612,207 | 
| GraphZoom-1   | 74.06 ± 0.26   | 120,251,183 |

LAMG Coarsening Code
---------------
The matlab version of lamg-based spectral coarsening code is available in `graphzoom/mat_coarsen/`
