/*=================================================================
 * aggregationsweep.c
 *
 * Sweep over graph nodes and aggregate them.
 *
 * MATLAB calling syntax:
 * [x, x2, stat, aggregateSize, numAggregates] = aggregationSweep
 * (bins, x, x2, stat, aggregateSize, numAggregates, C, D, W,
 * ratioMax, maxCoarseningRatio)
 *=================================================================*/
#include "mex.h"
#include <math.h>

/* 
 * stat array coding schema:
 -1: undecided
  0: seed
 >0: index of seed
 */

/* Input arguments */
#define BINS_IN                     prhs[0]
#define X_IN                        prhs[1]
#define X2_IN                       prhs[2]
#define STAT_IN                     prhs[3]
#define AGGREGATESIZE_IN            prhs[4]
#define NUMAGGREGATES_IN            prhs[5]
#define C_IN                        prhs[6]
#define D_IN                        prhs[7]
#define W_IN                        prhs[8]
#define RATIOMAX_IN                 prhs[9]
#define MAXCOARSENINGRATIO_IN       prhs[10]

/* Output arguments */
#define X_OUT                       plhs[0]
#define X2_OUT                      plhs[1]
#define STAT_OUT                    plhs[2]
#define AGGREGATESIZE_OUT           plhs[3]
#define NUMAGGREGATES_OUT           plhs[4]

/* Function declarations */
static unsigned int     get_as_uint32(const mxArray *x);
static double           get_as_double(const mxArray *x);
static void             checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
static void             processBin(double *bin, mwSize binSize, double *x, double *x2, 
                            double *stat, double *aggregateSize, unsigned int *numAggregates,
                            const mxArray *prhs[]);

/*
 * Main gateway function called by MATLAB.
 */
void
        mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    unsigned int *numAggregates, *numAggregatesData;
    mwSize  n, numBins, binSize;
    mwIndex i;
    mxArray *cellBin;
    double  *x, *x2, *stat, *aggregateSize, maxCoarseningRatio, *bin;
        
    /* Read and validate input, output arguments */
    checkArguments(nlhs, plhs, nrhs, prhs);
    n                       = mxGetM(X_IN);
    maxCoarseningRatio      = get_as_double(MAXCOARSENINGRATIO_IN);
    numAggregates           = (unsigned int*)mxCalloc(1, sizeof(unsigned int));
    *numAggregates          = get_as_uint32(NUMAGGREGATES_IN);
            
    /* Duplicate input arrays into an output arrays, to be changed in-place */
    X_OUT                   = mxDuplicateArray(X_IN);
    X2_OUT                  = mxDuplicateArray(X2_IN);
    STAT_OUT                = mxDuplicateArray(STAT_IN);
    AGGREGATESIZE_OUT       = mxDuplicateArray(AGGREGATESIZE_IN);
// NUMAGGREGATES_OUT       = mxDuplicateArray(NUMAGGREGATES_IN);
    
    x                       = mxGetPr(X_OUT);
    x2                      = mxGetPr(X2_OUT);
    stat                    = mxGetPr(STAT_OUT);
    aggregateSize           = mxGetPr(AGGREGATESIZE_OUT);
//    numAggregates           = mxGetPr(NUMAGGREGATES_OUT);
    
    /* Main loop over bins of undecided nodes in descending connection strength order */
    // mexPrintf("original numAggregates = %d\n", *numAggregates);
    numBins = mxGetNumberOfElements(BINS_IN);
    for (i = numBins-1; (int)i >= 0; i--) {
        cellBin = mxGetCell(BINS_IN, i);
        bin = mxGetPr(cellBin);
        binSize = mxGetN(cellBin);
        processBin(bin, binSize, x, x2, stat, aggregateSize, numAggregates, prhs);
        // mexPrintf("after bin %d numAggregates = %d\n", i, *numAggregates);

        /* Stop if reached target coarsening ratio. Checking only
         * after an entire bin for easier future parallelization.
         * Also less expensive. */
         if (*numAggregates <= n*maxCoarseningRatio) {
            break;
         }
    } // for bin in bins

    NUMAGGREGATES_OUT = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
    numAggregatesData = (unsigned int*)mxGetPr(NUMAGGREGATES_OUT);
    *numAggregatesData = *numAggregates;
    mxFree(numAggregates);
}

/* Perform an aggregation sweep on a bin of undecided nodes. */
static void
        processBin(double *bin, mwSize binSize, double *x, double *x2, 
            double *stat, double *aggregateSize, unsigned int *numAggregates,
            const mxArray *prhs[])
{
    // *_index refer to indices into a sparse matrix's non-zero array, e.g., j_index.
    // i, j correspond to nodes, i.e., indices in the X array
    
    mwIndex *C_jcol, *C_irow, *C_colIndex, *W_jcol, *W_irow;
    mwSize  n, K;
    mwIndex b, i, j, j_index, x_index, xi_index, xs_index, p, k, C_colStart, C_colEnd, W_colStart, W_colEnd, W_colSize;
    double ratioMax, ratioMax2, newAggregateSize;
    int s;                              // Seed for current node. If -1, indicates no seed was found.
    UINT32_T *Ci;                        // index array into C(i,:) of potential seeds for node i
    double *r, *q, *E;                  // Hold fine nodal energy terms
    double *C, *C_colData, *D, *W, d, d2, y, Cij, Cij_max, xj, Ec, mu, maxMu, mu2;
    double rr, qq;                      // Double-letter variables are temporary placeholder of single values in the corresponding single-letter array.
    unsigned int Ci_size, C_colSize, smallRatio;

    // mexPrintf("processBin(size=%d)\n", binSize);
    n           = mxGetM(X_IN);
    K           = mxGetN(X_IN);
    C_irow      = mxGetIr(C_IN);
    C_jcol      = mxGetJc(C_IN);        // Points to start of col N(:,j)
    C           = mxGetPr(C_IN);
    W_irow      = mxGetIr(W_IN);
    W_jcol      = mxGetJc(W_IN);        // Points to start of col N(:,j)
    W           = mxGetPr(W_IN);
    D           = mxGetPr(D_IN);
    ratioMax    = get_as_double(RATIOMAX_IN);
    ratioMax2   = K*ratioMax*ratioMax;
    
    /* Main loop over undecided nodes */
    for (b = 0; b < binSize; b++, bin++) {
        i = (int)(*bin)-1;   // Convert to 0-based index
       
        // Check that i was not made a seed during previous node visitation
        if (stat[i] >= 0) {
            continue;
        }
        // mexPrintf("##############################################\n");
        // mexPrintf("%d/%d i=%d \n", b, binSize, i);

        // Find i's undecided & seed delta-affinitive neighbor set Ci
        // Equivalent MATLAB calls:
        // [Ci, ~, Ni] = find(C(:,i));
        // smallAgg = stat(Ci) <= 0;        % Only undecided & seed neighbors
        // Ci = Ci(smallAgg);
        // Ni = Ni(smallAgg);
        C_colStart  = C_jcol[i];
        C_colEnd    = C_jcol[i+1];
        Ci_size     = 0;
        C_colSize   = C_colEnd-C_colStart;
        Ci          = (UINT32_T*)mxCalloc(C_colSize, sizeof(UINT32_T));   // initialized to 0. We will mark relevant neighbors of each i as 1.
        C_colIndex  = C_irow + C_colStart;                  // Points to beginning of C(:,i) - irow index
        C_colData   = C + C_colStart;                       // Points to beginning of C(:,i) - data
        for (p = 0; p < C_colSize; p++) {
            j = C_colIndex[p];
            if (stat[j] <= 0) {
                Ci[Ci_size++] = p;
            }
        }
        if (Ci_size == 0) {
            // No delta-neighbors
            mxFree(Ci);
            continue;
        }

        /*
        // // mexPrintf("Ci [alloc=%d, size=%d]\n", C_colSize, Ci_size);
        for (p = 0; p < Ci_size; p++) {
            // // mexPrintf("  p=%d   Ci[p]=%d  j=%d  affinity=%f\n", p, Ci[p], 
                    C_colIndex[Ci[p]], C_colData[Ci[p]]);
        }
         */

            // Allocate arrays for energy terms that involve i and its W-neighbors
        // Equivalent MATLAB calls:
        // [k, ~, w]   = find(W(:,i));
        // w           = w';
        W_colStart  = W_jcol[i];
        W_colEnd    = W_jcol[i+1];
        W_colSize   = W_colEnd-W_colStart;
        d           = D[i];
        d2          = 0.5*D[i];
        
        // Compute fine nodal energy min_y Ei(x;y) : depends on i and TV
        r       = (double*)mxCalloc(K, sizeof(double));
        q       = (double*)mxCalloc(K, sizeof(double));
        E       = (double*)mxCalloc(K, sizeof(double));
        for (k = 0; k < K; k++) {
            // Equivalent MATLAB calls:
            // r           = w*x(k,:);
            // q           = w*x2(k,:);
            rr = 0.0;
            qq = 0.0;
            // mexPrintf("Energy terms, TV k=%d\n", k);
            for (j_index = W_colStart, p = 0; j_index < W_colEnd; j_index++, p++) {
                j       = W_irow[j_index];          // W-neighbor of i
                x_index = j+n*k;                    // Index of x(j,k)
//                // mexPrintf("  j=%d  W=%f  x[%d]=%f\n", j, W[j_index], x_index, x[x_index]);
                rr += W[j_index] * x[x_index];
                qq += W[j_index] * x2[x_index];
            }
            // Equivalent MATLAB calls:
            // y           = r/d;
            // E           = (d2*y - r).*y + q;
            r[k] = rr;
            q[k] = qq;
            y    = rr/d;                            // Minimizer of E(x;y)
            E[k] = (d2*y - rr)*y + qq;              // min_y E(x;y), evaluated using Horner's rule
        }
        /*
        // mexPrintf("Nodal energy terms:\n");
        for (k = 0; k < K; k++) {
           // mexPrintf("  k=%d   r=%+f  q=%+f  y=%+f  E=%+f\n", k, r[k], q[k], r[k]/d, E[k]);
        }
*/
        
        // - Compute Ei(x;xj), the prospective coarse nodal energy upon
        //   aggregating i with each j in Ci, assuming that y=xj is then a good-
        //   enough approximation to the minimizer of Ei(x;y). Depends on i,j and TV.
        // - Compute the energy ratio mu = Ec/E for all W-neighbors and TVs.
        // - Find the best seed s to aggregate i with:
        //   s = argmax_S [C_{ij}], S = {j: delta-nbhr of i s.t. Ec/E <= mu}
        
        // mexPrintf("Look for seed\n");
        // Loop over potential seeds
        s = -1; // Best admissible seed encountered so far. -1 indicates not found.
        Cij_max = -1.0;
        for (p = 0; p < Ci_size; p++) {
            j_index = Ci[p];                // index of neighbor j of i in C_colData=C(i,:)
            j       = C_colIndex[j_index];  // Neighbor of i
            x_index = j;                    // Beginning index of x(j,:)
            // mexPrintf("  Ci-neighbor  p=%d  j_index=%d  j=%d\n", p, j_index, j);
            
            // Loop over TVs and compute mu=Ec/E. If it exceeds maxRatio
            // for a TV, no need to compute it for subsequent TVs.
            maxMu       = -1.0;
            smallRatio  = 1;
            // mu2       = 0.0;
            for (k = 0; k < K; k++) {
                // Equivalent MATLAB calls:
                // rows    = ones(numel(Ci),1);
                // r       = r(rows,:);
                // q       = q(rows,:);
                // E       = E(rows,:);
                // xj      = x(Ci,:);
                // xJoint  = xj;
                // Ec      = (d2*xJoint - r).*xJoint + q;
                xj  = x[x_index];                   // Index of x(j,k)
                Ec   = (d2*xj - r[k])*xj + q[k];    // E(x;xj), evaluated using Horner's rule
                
                // Equivalent MATLAB calls:
                // mu = max(Ec./E, [], 2);
                // smallRatio = find(mu <= ratioMax);
                mu = Ec/(E[k]+1e-15);
                // mexPrintf("    Ec=%.2f  E=%.2f  mu=%.2f\n", Ec, E, mu);

                // mu2 += mu*mu;
                if (mu > maxMu) {
                    maxMu = mu;
                }
                if (maxMu > ratioMax) {
                    smallRatio = 0;
                    break;
                }
                
                // Go to next TV column
                x_index += n;
            } // for k in TVs
            
            /*
            // mexPrintf("    avgMu=%.2f\n", sqrt(mu2/K));
            if (mu2 > ratioMax2) {
                smallRatio = 0;
            }
             */
            
            // Update best seed
            // Equivalent MATLAB calls:
            // Ni          = Ni(smallRatio);   // Find relevant neighbors
            // Ci          = Ci(smallRatio);
            // [~, k]      = max(Ni);          // Maximize affinity
            // k           = k(1);
            // s           = Ci(k);            // Remember to convert to 1-based!!!
            Cij = C_colData[j_index];
            // mexPrintf("  smallRatio=%d  Cij=%f  current max=%f\n", smallRatio, Cij, Cij_max);
            if (smallRatio && (Cij > Cij_max)) {
                Cij_max = Cij;
                s = j;
                // mexPrintf("  Set s to %d, current max=%f\n", s, Cij_max);
            }
        }
        // mexPrintf("seed s = %d\n", s);
        
        // Clean work arrays of node i 
        mxFree(Ci);
        mxFree(r);
        mxFree(q);
        mxFree(E);
        
        if (s < 0) {
            // No seed found, don't aggregate i
            continue;
        }

        //------------------------
        // Aggregate i with s
        //------------------------
        // Update TV values of new aggregate
        // Equivalent MATLAB calls:
        // x(i,:)  = xJoint(k,:);
        // x2(i,:) = xAggregate.^2;
        xi_index = i;                  // Beginning index of x(i,:)
        xs_index = s;                  // Beginning index of x(s,:)
        for (k = 0; k < K; k++) {
            x [xi_index] = x [xs_index];
            x2[xi_index] = x2[xs_index];
            // mexPrintf("Copied x[%d] to x[%d], new value = %f\n", xs_index, xi_index, x[xi_index]);
            // Go to next TV column
            xi_index += n;
            xs_index += n;
        }
        
        // Update node status arrays
        // mexPrintf("Updating stat arrays: i = %d, s = %d\n", i, s);
        stat[s]             = 0;
        stat[i]             = (double)(s+1);
        newAggregateSize    = aggregateSize[s]+1;
        aggregateSize[i]    = newAggregateSize;
        aggregateSize[s]    = newAggregateSize;
        *numAggregates      = (*numAggregates)-1;
    }
    // mexPrintf("end processBin() numAggregates = %d\n", *numAggregates);
}
        
/*
 * Check that A is a sparse n-by-n matrix.
 * Check that CANDIDATE is m-by-1.
 */
static void
        checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    mwSize n, K;
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 11) {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidNumInputs",
                "11 input arguments required.");
    }
    if (nlhs > 5) {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidNumOutputs",
                "Too many output arguments.");
    }
    
    /* Check for proper types of input and output arguments */
    if (!mxIsCell(BINS_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidInput",
                "BINS must be a cell array.");
    }
    if (!mxIsDouble(X_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidInput",
                "X must be a double-precision floating-point array.");
    }
    if (!mxIsDouble(X2_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidInput",
                "X2 must be a double-precision floating-point array.");
    }
    if (!mxIsDouble(AGGREGATESIZE_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidInput",
                "AGGREGATESIZE must be a double-precision floating-point array.");
    }
    //if (!mxIsDouble(NUMAGGREGATES_IN))  {
//        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidInput",
//                "NUMAGGREGATES must be a double-precision floating-point number.");
//    }
    if (mxGetClassID(NUMAGGREGATES_IN) != mxUINT32_CLASS)  {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidInput",
                "NUMAGGREGATES must be a uint32 unsigned integer.");
    }
    if (!mxIsSparse(C_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidInput",
                "C must be a sparse matrix.");
    }
    if (!mxIsDouble(D_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidInput",
                "D must be a double-precision floating-point array.");
    }
    if (!mxIsSparse(W_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidInput",
                "W must be a sparse matrix.");
    }
    if (!mxIsDouble(RATIOMAX_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidInput",
                "RATIOMAX must be a double-precision floating-point number.");
    }
    if (!mxIsDouble(MAXCOARSENINGRATIO_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidInput",
                "MAXCOARSENINGRATIO must be a double-precision floating-point number.");
    }

    /* Check for proper sizes of input and output arguments -- 
     * omitting full implementation, doing a simple example only */
    n = mxGetM(X_IN);
    K = mxGetN(X_IN);
    
    if ((mxGetM(X2_IN) != n) || (mxGetN(X2_IN) != K)) {
        mexErrMsgIdAndTxt( "MATLAB:aggregationsweep:invalidInput",
                "X2 and X must have the same size.");
    }
}

/* Convert input argument to unsigned int. */
static unsigned int
        get_as_uint32(const mxArray *x)
{
    unsigned int *pr;
    pr = (unsigned int *)mxGetData(x);
    return pr[0];
}

/* Convert input argument to double. */
static double
        get_as_double(const mxArray *x)
{
    double *pr;
    pr = (double *)mxGetData(x);
    return pr[0];
}
