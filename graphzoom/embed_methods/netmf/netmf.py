from scipy.sparse import csgraph
from theano import tensor as T
import networkx as nx
import numpy as np
import scipy.sparse as sparse
import theano


# For dynamic loading: name of this method should be the same as name of this python FILE.
def netmf(graph):
    '''Use NetMF as the base embedding method. This is a wrapper method and used by MILE.'''
    args = NetMFSetting()
    args.rank = min(args.rank, len(graph) - 1)  # rank cannot be larger than the size of the matrix
    return NetMF_Original(my_graph=graph, rank=args.rank, dim=args.embed_dim, window=args.window_size, negative=args.negative,
                          large=args.large, small=args.small).get_embeddings()


class NetMFSetting:
    '''Configuration parameters for NetMF.'''
    def __init__(self):
        self.rank = 1024
        self.window_size = 10
        self.negative = 1
        self.embed_dim = 128
        self.large = True
        self.small = False

class NetMF_Original(object):
    '''This is the original implementation of NetMF. Code is adapted from https://github.com/xptree/NetMF.'''

    def __init__(self, my_graph, rank, dim, window=10, negative=1.0, large=True, small=False):
        adj = nx.adjacency_matrix(my_graph)
        if large:
            self.netmf_large(adj, rank, dim, window, negative)
        else:
            self.netmf_small(adj, rank, dim, window, negative)

    def netmf_large(self, adj, rank=256, dim=128, window=10, negative=1.0):
        # load adjacency matrix
        A = adj

        vol = float(A.sum())
        # perform eigen-decomposition of D^{-1/2} A D^{-1/2}
        # keep top #rank eigenpairs
        evals, D_rt_invU = self.approximate_normalized_graph_laplacian(A, rank=rank, which="LA")

        # approximate deepwalk matrix
        deepwalk_matrix = self.approximate_deepwalk_matrix(evals, D_rt_invU,
                                                           window=window,
                                                           vol=vol, b=negative)
        # factorize deepwalk matrix with SVD
        deepwalk_embedding = self.svd_deepwalk_matrix(deepwalk_matrix, dim=dim)

        self.vectors = deepwalk_embedding

    def approximate_normalized_graph_laplacian(self, A, rank, which="LA"):
        n = A.shape[0]
        L, d_rt = csgraph.laplacian(A, normed=True, return_diag=True)
        # X = D^{-1/2} W D^{-1/2}
        X = sparse.identity(n) - L
        # evals, evecs = sparse.linalg.eigsh(X, rank,
        #        which=which, tol=1e-3, maxiter=300)
        evals, evecs = sparse.linalg.eigsh(X, rank, which=which)
        D_rt_inv = sparse.diags(d_rt ** -1)
        D_rt_invU = D_rt_inv.dot(evecs)
        return evals, D_rt_invU

    def approximate_deepwalk_matrix(self, evals, D_rt_invU, window, vol, b):
        evals = self.deepwalk_filter(evals, window=window)
        X = sparse.diags(np.sqrt(evals)).dot(D_rt_invU.T).T
        m = T.matrix()
        mmT = T.dot(m, m.T) * (vol / b)
        f = theano.function([m], T.log(T.maximum(mmT, 1)))
        Y = f(X.astype(theano.config.floatX))
        # return sparse.csr_matrix(Y)
        return Y

    def sparse_mul(self, X, thres=0.5):  # X * X^T
        r, c = X.shape  # the output should be (r, r)
        new_row = []
        new_col = []
        new_val = []
        # norms = np.linalg.norm(X, axis=1)
        for i in range(r):
            for j in range(i, r):
                val = np.dot(X[i], X[j])
                if val <= 1.0:
                    continue
                val = np.log(val)
                if val > thres:  # symmetric
                    new_row.append(i)
                    new_row.append(j)
                    new_col.append(j)
                    new_col.append(i)
                    new_val.append(val)
                    new_val.append(val)
        return sparse.coo_matrix((new_val, (new_row, new_col)), shape=(r, r))

    def svd_deepwalk_matrix(self, X, dim):
        u, s, v = sparse.linalg.svds(X, dim, return_singular_vectors="u")
        # return U \Sigma^{1/2}
        return sparse.diags(np.sqrt(s)).dot(u.T).T

    def netmf_small(self, graph, rank=256, dim=128, window=10, negative=1.0):
        # load adjacency matrix
        A = graph
        # directly compute deepwalk matrix
        deepwalk_matrix = self.direct_compute_deepwalk_matrix(A, window=window, b=negative)

        # factorize deepwalk matrix with SVD
        deepwalk_embedding = self.svd_deepwalk_matrix(deepwalk_matrix, dim=dim)
        self.vectors = deepwalk_embedding

    def deepwalk_filter(self, evals, window):
        for i in range(len(evals)):
            x = evals[i]
            evals[i] = 1. if x >= 1 else x * (1 - x ** window) / (1 - x) / window
        evals = np.maximum(evals, 0)
        return evals

    def direct_compute_deepwalk_matrix(self, A, window, b):
        n = A.shape[0]
        vol = float(A.sum())
        L, d_rt = csgraph.laplacian(A, normed=True, return_diag=True)
        # X = D^{-1/2} A D^{-1/2}
        X = sparse.identity(n) - L
        S = np.zeros_like(X)
        X_power = sparse.identity(n)
        for i in range(window):
            X_power = X_power.dot(X)
            S += X_power
        S *= vol / window / b
        D_rt_inv = sparse.diags(d_rt ** -1)
        M = D_rt_inv.dot(D_rt_inv.dot(S).T)
        m = T.matrix()
        f = theano.function([m], T.log(T.maximum(m, 1)))
        Y = f(M.todense().astype(theano.config.floatX))
        return sparse.csr_matrix(Y)

    def get_embeddings(self):
        return self.vectors
