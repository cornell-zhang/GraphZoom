import numpy as np
import networkx as nx
import os
from scipy.sparse import csr_matrix, triu, tril, diags, identity
from scipy.io import mmwrite, mmread
from itertools import permutations
from numpy import linalg as LA
import sys
from argparse import ArgumentParser
from sklearn.preprocessing import normalize
import time

from embed_methods.deepwalk.deepwalk import *
from embed_methods.node2vec.node2vec import *
from utils import *
from scoring import lr

def graph_fusion(laplacian, feature, num_neighs, mcr_dir, coarse, fusion_input_path, \
                 search_ratio, fusion_output_dir, mapping_path, dataset):

    # obtain mapping operator
    if coarse == "simple":
        mapping = sim_coarse_fusion(laplacian)
    elif coarse == "lamg":
        os.system('./run_coarsening.sh {} {} {} f {}'.format(mcr_dir, \
                fusion_input_path, search_ratio, fusion_output_dir))
        mapping = mtx2matrix(mapping_path)
    else:
        raise NotImplementedError

    # construct feature graph
    feats_laplacian = feats2graph(feature, num_neighs, mapping)

    # fusion
    fused_laplacian = laplacian + feats_laplacian   # fuses adj_graph and feat_graph, beta=1

    if coarse == "lamg":
        file = open("dataset/{}/fused_{}.mtx".format(dataset, dataset), "wb")
        mmwrite("dataset/{}/fused_{}.mtx".format(dataset, dataset), fused_laplacian)
        file.close()
        print("Successfully Writing Fused Graph.mtx file!!!!!!")

    return fused_laplacian

def refinement(levels, projections, coarse_laplacian, embeddings, lda, power):
    for i in reversed(range(levels)):
        embeddings = projections[i] @ embeddings
        filter_    = smooth_filter(coarse_laplacian[i], lda)
        if power or i == 0:   # power controls whether smooth intermediate embeddings
            embeddings = filter_ @ (filter_ @ embeddings)
    return embeddings

def main():
    parser = ArgumentParser(description="GraphZoom")
    parser.add_argument("-d", "--dataset", type=str, default="cora", \
            help="input dataset")
    parser.add_argument("-o", "--coarse", type=str, default="simple", \
            help="choose either simple_coarse or lamg_coarse, [simple, lamg]")
    parser.add_argument("-c", "--mcr_dir", type=str, default="/opt/matlab/R2018A/", \
            help="directory of matlab compiler runtime (only required by lamg_coarsen)")
    parser.add_argument("-s", "--search_ratio", type=int, default=12, \
            help="control the search space in graph fusion process (only required by lamg_coarsen)")
    parser.add_argument("-r", "--reduce_ratio", type=int, default=2, \
            help="control graph coarsening levels (only required by lamg_coarsen)")
    parser.add_argument("-v", "--level", type=int, default=1, \
            help="number of coarsening levels (only required by simple_coarsen)")
    parser.add_argument("-n", "--num_neighs", type=int, default=2, \
            help="control k-nearest neighbors in graph fusion process")
    parser.add_argument("-l", "--lda", type=float, default=0.1, \
            help="control self loop in adjacency matrix")
    parser.add_argument("-e", "--embed_path", type=str, default="embed_results/embeddings.npy", \
            help="path of embedding result")
    parser.add_argument("-m", "--embed_method", type=str, default="deepwalk", \
            help="[deepwalk, node2vec, graphsage]")
    parser.add_argument("-f", "--fusion", default=True, action="store_false", \
            help="whether use graph fusion")
    parser.add_argument("-p", "--power", default=False, action="store_true", \
            help="Strong power of graph filter, set True to enhance filter power")
    parser.add_argument("-g", "--sage_model", type=str, default="mean", \
            help="aggregation function in graphsage")
    parser.add_argument("-w", "--sage_weighted", default=True, action="store_false", \
            help="whether consider weighted reduced graph")

    args = parser.parse_args()

    dataset = args.dataset
    feature_path = "dataset/{}/{}-feats.npy".format(dataset, dataset)
    fusion_input_path = "dataset/{}/{}.mtx".format(dataset, dataset)
    reduce_results = "reduction_results/"
    mapping_path = "{}Mapping.mtx".format(reduce_results)

    if args.fusion:
        coarsen_input_path = "dataset/{}/fused_{}.mtx".format(dataset, dataset)
    else:
        coarsen_input_path = "dataset/{}/{}.mtx".format(dataset, dataset)

######Load Data######
    print("%%%%%% Loading Graph Data %%%%%%")
    laplacian = json2mtx(dataset)
    if args.fusion or args.embed_method == "graphsage":    ##whether feature is needed
        feature   = np.load(feature_path)

######Graph Fusion######
    if args.fusion:
        print("%%%%%% Starting Graph Fusion %%%%%%")
        fusion_start = time.process_time()
        laplacian    = graph_fusion(laplacian, feature, args.num_neighs, args.mcr_dir, args.coarse,\
                       fusion_input_path, args.search_ratio, reduce_results, mapping_path, dataset)
        fusion_time  = time.process_time() - fusion_start

######Graph Reduction######
    print("%%%%%% Starting Graph Reduction %%%%%%")
    reduce_start = time.process_time()

    if args.coarse == "simple":
        G, projections, laplacians, level = sim_coarse(laplacian, args.level)
        reduce_time = time.process_time() - reduce_start

    elif args.coarse == "lamg":
        os.system('./run_coarsening.sh {} {} {} n {}'.format(args.mcr_dir, \
                coarsen_input_path, args.reduce_ratio, reduce_results))
        reduce_time = read_time("{}CPUtime.txt".format(reduce_results))
        G = mtx2graph("{}Gs.mtx".format(reduce_results))
        level = read_levels("{}NumLevels.txt".format(reduce_results))
        projections, laplacians = construct_proj_laplacian(laplacian, level, reduce_results)

    else:
        raise NotImplementedError


######Embed Reduced Graph######
    print("%%%%%% Starting Graph Embedding %%%%%%")
    if args.embed_method == "deepwalk":
        embed_start = time.process_time()
        embeddings  = deepwalk(G)

    elif args.embed_method == "node2vec":
        embed_start = time.process_time()
        embeddings  = node2vec(G)

    elif args.embed_method == "graphsage":
        from embed_methods.graphsage.graphsage import graphsage
        nx.set_node_attributes(G, False, "test")
        nx.set_node_attributes(G, False, "val")

        # obtain mapping operator
        if args.coarse == "lamg":
            mapping = normalize(mtx2matrix(mapping_path), norm='l1', axis=1)
        else:
            mapping = identity(feature.shape[0])
            for p in projections:
                mapping = mapping @ p
            mapping = normalize(mapping, norm='l1', axis=1).transpose()

        # control iterations for training
        coarse_ratio = mapping.shape[1]/mapping.shape[0]

        # map node feats to the coarse graph
        feats = mapping @ feature

        embed_start = time.process_time()
        embeddings  = graphsage(G, feats, args.sage_model, args.sage_weighted, int(1000/coarse_ratio))

    embed_time = time.process_time() - embed_start


######Refinement######
    print("%%%%%% Starting Graph Refinement %%%%%%")
    refine_start = time.process_time()
    embeddings   = refinement(level, projections, laplacians, embeddings, args.lda, args.power)
    refine_time  = time.process_time() - refine_start


######Save Embeddings######
    np.save(args.embed_path, embeddings)


######Evaluation######
    lr("dataset/{}/".format(dataset), args.embed_path, dataset)

######Report timing information######
    print("%%%%%% CPU time %%%%%%")
    if args.fusion:
        total_time = fusion_time + reduce_time + embed_time + refine_time
        print("Graph Fusion     Time: {}".format(fusion_time))
    else:
        total_time = reduce_time + embed_time + refine_time
        print("Graph Fusion     Time: 0")
    print("Graph Reduction  Time: {}".format(reduce_time))
    print("Graph Embedding  Time: {}".format(embed_time))
    print("Graph Refinement Time: {}".format(refine_time))
    print("Total Time = Fusion_time + Reduction_time + Embedding_time + Refinement_time = {}".format(total_time))


if __name__ == "__main__":
    sys.exit(main())

