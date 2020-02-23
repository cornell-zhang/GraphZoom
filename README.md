GraphZoom
===============================

GraphZoom is a framework that aims to improve both performance and scalability of graph embedding techniques.

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

Requirements
------------
* Matlab Compiler Runtime (MCR) 2018a(Linux), which is a standalone set of shared libraries that enables the execution of compiled MATLAB applications and does not require license to install.
* numpy
* networkx
* scipy
* scikit-learn
* gensim, only required by deepwalk, node2vec
* tensorflow, only required by graphsage

Installation
------------
1. `install matlab compiler runtime 2018a(Linux)` (https://www.mathworks.com/products/compiler/matlab-runtime.html)
2. `pip install -r requirements.txt`

Usage
-----

**Note:** You have to pass the root directory of matlab compiler runtime to the argument "--mcr\_dir" when running graphzoom.py

**Example Usage**
    ``cd graphzoom``

    ``python graphzoom.py --mcr_dir YOUR_MCR_ROOT_DIR --dataset citeseer --search_ratio 12 --num_neighs 10 --embed_method deepwalk``

**--mcr_dir**:  *root directory of matlab compiler runtime*

**--dataset**: *input dataset, currently supports "json" format*

**--embed_method**: *choose a specific basic embedding algorithm*

**--search_ratio**: *control the search space of graph fusion*

**--num_neighs**: *control number of edges in feature graph*


**Full Command List**
    The full list of command line options is available with ``python graphzoom.py --help``

**Coarsening Code**
    The matlab version of spectral coarsening code is available in mat_coarsen/

