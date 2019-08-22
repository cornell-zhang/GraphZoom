===============================
GraphZoom
===============================

GraphZoom is a framework that aims to improve both performance and scalability of graph embedding techniques.

Requirements
------------
* Matlab Compiler Runtime (MCR) 2018a, which is required by graph reduction algorithm
* numpy
* networkx
* scipy
* scikit-learn
* gensim, only required by deepwalk, node2vec
* theano, only required by netmf
* tensorflow, only required by graphsage

Installation
------------
1. `install matlab compiler runtime 2018a` (https://www.mathworks.com/products/compiler/matlab-runtime.html)
2. `pip install -r requirements.txt`

Usage
-----

**Note:** You have to pass the root directory of matlab compiler runtime to the argument "--mcr_dir" when running graphsage.py

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

