import numpy as np
import networkx as nx
import os
from scipy.sparse import csr_matrix, triu, tril, diags
from scipy.io import mmwrite, mmread
from itertools import permutations
from numpy import linalg as LA
import sys
from argparse import ArgumentParser
from sklearn.preprocessing import normalize
import time
import os.path

from embed_methods.deepwalk.deepwalk import *
from embed_methods.node2vec.node2vec import *
from utils import *
from scoring import lr

def cosine_similarity(x, y):
    dot_xy = np.dot(x, y)
    norm_x = LA.norm(x)
    norm_y = LA.norm(y)
    if norm_x == 0 or norm_y == 0:
        if norm_x == 0 and norm_y == 0:
            similarity = 1
        else:
            similarity = 0
    else:
        similarity = dot_xy/(norm_x * norm_y)
    return similarity

def maximum (A, B):
    BisBigger = A-B
    BisBigger.data = np.where(BisBigger.data < 0, 1, 0)
    return A - A.multiply(BisBigger) + B.multiply(BisBigger)

def feats2graph(feature, num_neighs, mapping):
    dim = mapping.shape[1]
    agg_dim = mapping.shape[0]
    all_rows = []
    all_cols = []
    all_data = []
    for i in range(agg_dim):
        row = []
        col = []
        data = []
        node_list = ((mapping[i,:].nonzero())[1]).tolist()
        if len(node_list)-1 > num_neighs:
            for j in node_list:
                col_ = []
                data_ = []
                dist = []
                x = feature[j, :]
                for k in node_list:
                    if j != k:
                        y = feature[k, :]
                        dist.append(LA.norm(x-y))
                        col_.append(k)
                ids_sort = np.argsort(np.asarray(dist))
                col_ind = (np.asarray(col_)[ids_sort]).tolist()[:num_neighs]
                for ind in col_ind:
                    y = feature[ind, :]
                    wgt = cosine_similarity(x, y)
                    data_.append(wgt)
                row += (np.repeat(j, num_neighs)).tolist()
                col += col_ind
                data += data_
        else:
            for pair in permutations(node_list, 2):
                x = feature[pair[0], :]
                y = feature[pair[1], :]
                wgt = cosine_similarity(x, y)
                row.append(pair[0])
                col.append(pair[1])
                data.append(wgt)
        all_rows += row
        all_cols += col
        all_data += data
    adj = csr_matrix((all_data, (all_rows, all_cols)), shape=(dim, dim))
    adj_upper = triu(adj)
    adj_lower = tril(adj)
    adj_max = maximum(adj_upper, adj_lower.transpose())
    adj_matrix = adj_max + adj_max.transpose()
    degree_vec = np.squeeze(np.asarray(adj_matrix.sum(axis=1)))
    degree_matrix = diags(degree_vec, 0)
    laplacian_matrix = degree_matrix - adj_matrix
    return laplacian_matrix


def graph_fusion(laplacian, feature, num_neighs, mcr_dir, fusion_input_path, search_ratio, fusion_output_dir, mapping_path, dataset):
    os.system('./run_coarsening.sh {} {} {} f {}'.format(mcr_dir, fusion_input_path, search_ratio, fusion_output_dir))
    mapping = mtx2matrix(mapping_path)
    feats_laplacian = feats2graph(feature, num_neighs, mapping)
    fused_laplacian = laplacian + feats_laplacian
    file = open("dataset/{}/fused_{}.mtx".format(dataset, dataset), "wb")
    mmwrite("dataset/{}/fused_{}.mtx".format(dataset, dataset), fused_laplacian)
    file.close()
    print("Successfully Writing Fused Graph.mtx file!!!!!!")
    return fused_laplacian

def smooth_filter(laplacian_matrix, lda):
    dim = laplacian_matrix.shape[0]
    degree_matrix_vec = laplacian_matrix.diagonal()
    self_loop_vec = degree_matrix_vec * lda
    degree_matrix = diags(degree_matrix_vec, 0)
    self_loop = diags(self_loop_vec, 0)
    adj_matrix = degree_matrix - laplacian_matrix + self_loop
    degree_vec = adj_matrix.sum(axis=1)
    with np.errstate(divide='ignore'):
        d_inv_sqrt = np.squeeze(np.asarray(np.power(degree_vec, -0.5)))
    d_inv_sqrt[np.isinf(d_inv_sqrt)|np.isnan(d_inv_sqrt)] = 0
    degree = diags(d_inv_sqrt, 0)
    norm_adj = degree @ adj_matrix @ degree
    return norm_adj

def refinement(levels, projections, coarse_laplacian, embeddings, lda, power):
    for i in reversed(range(levels)):
        embeddings = (projections[i].transpose()) @ embeddings
        filter_ = smooth_filter(coarse_laplacian[i], lda)
        if power or i == 0:
            embeddings = filter_ @ (filter_ @ embeddings)
    return embeddings

def main():
    parser = ArgumentParser(description="GraphZoom")
    parser.add_argument("-d", "--dataset", type=str, default="cora", help="input dataset")
    parser.add_argument("-c", "--mcr_dir", type=str, default="/opt/matlab/R2018A/", help="directory of matlab compiler runtime")
    parser.add_argument("-s", "--search_ratio", type=int, default=12, help="control the search space in graph fusion process")
    parser.add_argument("-r", "--reduce_ratio", type=int, default=2, help="control graph coarsening levels")
    parser.add_argument("-n", "--num_neighs", type=int, default=2, help="control k-nearest neighbors in graph fusion process")
    parser.add_argument("-l", "--lda", type=float, default=0.1, help="control self loop in adjacency matrix")
    parser.add_argument("-e", "--embed_path", type=str, default="embed_results/embeddings.npy", help="path of embedding result")
    parser.add_argument("-m", "--embed_method", type=str, default="deepwalk", help="[deepwalk, node2vec, graphsage]")
    parser.add_argument("-f", "--fusion", default=True, action="store_false", help="whether use graph fusion")
    parser.add_argument("-p", "--power", default=False, action="store_true", help="Strong power of graph filter, set True to enhance filter power")

    parser.add_argument("-g", "--sage_model", type=str, default="mean", help="aggregation function in graphsage")
    parser.add_argument("-w", "--sage_weighted", default=True, action="store_false", help="whether consider weighted reduced graph")

    args = parser.parse_args()

    dataset = args.dataset
    mcr_dir = args.mcr_dir
    search_ratio = args.search_ratio
    num_neighs = args.num_neighs
    ratio = args.reduce_ratio
    lda = args.lda
    mapping_path = "reduction_results/Mapping.mtx"
    feature_path = "dataset/{}/{}-feats.npy".format(dataset, dataset)
    fusion_input_path = "dataset/{}/{}.mtx".format(dataset, dataset)
    fusion_output_dir = "reduction_results/"
    output_dir = "reduction_results/"
    mtx_path = "reduction_results/Gs.mtx"
    level_path = "reduction_results/NumLevels.txt"
    proj_dir = "reduction_results"
    save_dir = args.embed_path
    eval_dataset = "dataset/{}/".format(dataset)
    reduce_method = "graphzoom"
    cputime_path = "reduction_results/CPUtime.txt"

    if args.fusion:
        input_path = "dataset/{}/fused_{}.mtx".format(dataset, dataset)
    else:
        input_path = "dataset/{}/{}.mtx".format(dataset, dataset)

######Load Data######
    print("%%%%%% Loading Graph Data %%%%%%")
    if os.path.exists(fusion_input_path):
        laplacian = mmread(fusion_input_path)
    else:
        laplacian = json2mtx(dataset)

    if args.fusion or args.embed_method == "graphsage":    ##whether feature is needed
        feature = np.load(feature_path)


######Graph Fusion######
    if args.fusion:
        print("%%%%%% Starting Graph Fusion %%%%%%")
        fusion_start = time.process_time()
        laplacian = graph_fusion(laplacian, feature, num_neighs, mcr_dir, fusion_input_path, search_ratio, fusion_output_dir, mapping_path, dataset)
        fusion_end = time.process_time()
        fusion_time = fusion_end - fusion_start

######Graph Reduction######
    print("%%%%%% Starting Graph Reduction %%%%%%")
    os.system('./run_coarsening.sh {} {} {} n {}'.format(mcr_dir, input_path, ratio, output_dir))
    reduce_time = read_time(cputime_path)


######Embed Reduced Graph######
    G = mtx2graph(mtx_path)

    print("%%%%%% Starting Graph Embedding %%%%%%")
    if args.embed_method == "deepwalk":
        embed_start = time.process_time()
        embeddings = deepwalk(G)
        embed_end = time.process_time()

    elif args.embed_method == "node2vec":
        embed_start = time.process_time()
        embeddings = node2vec(G)
        embed_end = time.process_time()

    elif args.embed_method == "graphsage":
        from embed_methods.graphsage.graphsage import graphsage
        nx.set_node_attributes(G, False, "test")
        nx.set_node_attributes(G, False, "val")
        mapping = normalize(mtx2matrix(mapping_path), norm='l1', axis=1)
        feats = mapping @ feature

        embed_start = time.process_time()
        embeddings = graphsage(G, feats, args.sage_model, args.sage_weighted, int(10000/args.reduce_ratio))
        embed_end = time.process_time()

    embed_time = embed_end - embed_start

######Load Refinement Data######
    levels = read_levels(level_path)
    projections, coarse_laplacian = construct_proj_laplacian(laplacian, levels, proj_dir)

######Refinement######
    print("%%%%%% Starting Graph Refinement %%%%%%")
    refine_start = time.process_time()
    embeddings = refinement(levels, projections, coarse_laplacian, embeddings, lda, args.power)
    refine_end = time.process_time()
    refine_time = refine_end - refine_start


######Save Embeddings######
    np.save(save_dir, embeddings)


######Evaluation######
    lr(eval_dataset, save_dir, dataset)

######Report timing information######
    print("%%%%%% Single CPU time %%%%%%")
    if args.fusion:
        total_time = fusion_time + reduce_time + embed_time + refine_time
        time_info = [fusion_time, reduce_time, embed_time, refine_time, total_time]
        print("Graph Fusion     Time: {}".format(fusion_time))
    else:
        total_time = reduce_time + embed_time + refine_time
        time_info = [reduce_time, embed_time, refine_time, total_time]
    print("Graph Reduction  Time: {}".format(reduce_time))
    print("Graph Embedding  Time: {}".format(embed_time))
    print("Graph Refinement Time: {}".format(refine_time))
    print("Total Time = Fusion_time + Reduction_time + Embedding_time + Refinement_time = {}".format(total_time))


if __name__ == "__main__":
    sys.exit(main())

