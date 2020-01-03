/*=================================================================
 * undecidedNodes.c
 *
 * Find undecided nodes with open neighbors in a connection
 * matrix.
 *
 * MATLAB calling syntax:
 * bins = undecidedNodes(A, undecided, isOpen, numBins)
 *
 * undecided    = flag array indicating which candidate nodes have
 *                open neighbors
 * Amax         = max(A(undecided,isOpen), [], 2);
 * A            = adjacency matrix
 * candidate    = list of undecided nodes to filter
 * isOpen       = flag array indicating whether a node is open
 * Amax
 * numBins      = number of bins to bin undecided nodes into
 *=================================================================*/
#include "mex.h"
#include <math.h>       /* Needed for the floor() prototype */
#include <iostream>     /* For printouts */
#include <limits>       /* For max double value */
#include <vector>       /* For STL vector */
using namespace std;

#define A_IN         	prhs[0]
#define CANDIDATE_IN    prhs[1]
#define ISOPEN_IN       prhs[2]
#define NUMBINS_IN      prhs[3]

#define BINS_OUT        plhs[0]

/* Function declarations */
static void checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

/*
 * Main gateway function called by MATLAB.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    mwSize      n, numCandidates, numBins;
    mwIndex     j, k;
    mwIndex     *A_jcol, *A_irow, *Aj_irow;
    double      *candidate, *u, *A, *Aj,
            overall_min = numeric_limits<double>::max(), overall_max = 0.0;
    mxLogical   *isOpen;
    vector<int> undecided;      // List of undecided nodes, a subset of candidate
    vector<double> A_max;       // Corresponding list of max_{i is open} A(i,j)
    
    /* Read and validate input, output arguments */
    checkArguments(nlhs, plhs, nrhs, prhs);
    n               = mxGetM(A_IN);
    A_irow          = mxGetIr(A_IN);
    A_jcol          = mxGetJc(A_IN);
    A               = mxGetPr(A_IN);
    candidate       = mxGetPr(CANDIDATE_IN);
    numCandidates   = (mxGetN(CANDIDATE_IN) == 1) ? mxGetM(CANDIDATE_IN) : mxGetN(CANDIDATE_IN);
    isOpen          = mxGetLogicals(ISOPEN_IN);
    numBins         = (int)floor(mxGetScalar(NUMBINS_IN));
    
    /* Main loop over A-columns of candidate nodes j */
    for (u = candidate; u < candidate + numCandidates; u++) {
        j = (int)*u - 1; // Convert from MATLAB 1-base to 0-base
        double Aj_max = -numeric_limits<double>::max();
        bool isUndecided = false;
        // mexPrintf("j=%d, jcol range %d to %d\n", j, A_jcol[j], A_jcol[j+1]);
        /* For each neighbor i in A(:,j) */
        for (k = A_jcol[j], Aj_irow = A_irow + A_jcol[j], Aj = A + A_jcol[j];
        k < A_jcol[j+1]; k++, Aj_irow++, Aj++) {
            // mexPrintf("\tk=%d, i=%d, isOpen=%d\n", k, *Aj_irow, isOpen[*Aj_irow]);
            if (isOpen[*Aj_irow]) {
                /* Found open neighbor */
                if (!isUndecided) {
                    isUndecided = true;
                }
                /* Update maximum connection */
                if (*Aj > Aj_max) {
                    Aj_max = *Aj;
                }
                //mexPrintf("\t\topen, A=%f, Aj_max=%f\n", *Aj, Aj_max);
            }
        }
        
        /* Add 1-based candidate to undecided set; save corresponding maximum connection */
        if (isUndecided) {
            undecided.push_back((int)*u);
            A_max.push_back(Aj_max);
            /* Update bin endpoints */
            if (Aj_max > overall_max) {
                overall_max = Aj_max;
            }
            if (Aj_max < overall_min) {
                overall_min = Aj_max;
            }
            //mexPrintf("\tUndecided: u=%d, Aj_max=%f, current min=%f, max=%f\n", *u, Aj_max, overall_min, overall_max);
        }
    }
    //mexPrintf("min=%f, max=%f, numBins=%d\n", overall_min, overall_max, numBins);
    
    /*
     * Bin undecided nodes to simulate sorting. The range
     * [overall_min,overall_max] is sub-divided into N equidistan
     * intervals (bins). BINS is an Nx1 cell array of the
     * corresponding UNDECIDED-sub-vector indices, i.e.,
     * BINS{I} = FIND(UNDECIDED >= LOW(I) & UNDECIDED < HIGH(I)) where the
     * Ith interval is [LOW(I),HIGH(i)), except the last interval,
     * which is closed.)
     */
    
    /* Allocate bins */
    vector<vector<int> > bins(numBins, vector<int>());
    if (undecided.size() == 0) {
        BINS_OUT = mxCreateCellMatrix(0, 0);
        return;
    }
    
    /* Bins undecided nodes to bins */
    vector<int>::iterator i;
    vector<double>::iterator a;
    // Take care of corner case of one point or min=max        
    double h = (fabs(overall_max - overall_min) < 1e-15) ? 1.0 : 
        (double)numBins/(overall_max - overall_min);
    for (i = undecided.begin(), a = A_max.begin();
    i != undecided.end(); i++, a++) {
        int binIndex = (int)floor(h*(*a - overall_min));
        if (binIndex == numBins) {
            // Last interval is closed on the right
            binIndex--;
        }
        vector<int>& bin = bins[binIndex];
        bin.push_back(*i);
        //mexPrintf("Inserting i=%2d (a=%+f) into bin %2d, new size=%d 0x%p\n", 
//                *i, *a, binIndex, bin.size(), bin);
    }
    
    /* Copy vector of vectors to cell array */
    BINS_OUT = mxCreateCellMatrix(numBins, 1);
    for (k = 0; k < numBins; k++) {
        vector<int>& bin = bins[k];
        // mexPrintf("Bin k=%d size=%d 0x%p\n", k, bin.size(), bin);
        mxArray *cell = mxCreateDoubleMatrix((mwSize)1, (mwSize)bin.size(), mxREAL);
        double *b_double = mxGetPr(cell);
        for (vector<int>::iterator b = bin.begin(); b != bin.end(); b++, b_double++) {
            *b_double = *b;
        }
        mxSetCell(BINS_OUT, k, cell);
    }
}

/*
 * Check that A is a sparse n-by-n matrix.
 * Check that CANDIDATE, ISOPEN are double vectors.
 */
static void
        checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    mwSize m, n;
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 4) {
        mexErrMsgIdAndTxt( "MATLAB:undecidedNodes:invalidNumInputs",
                "3 input arguments required.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "MATLAB:undecidedNodes:invalidNumOutputs",
                "Too many output arguments.");
    }
    
    /* Check for proper types of input and output arguments */
    if (!mxIsSparse(A_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:undecidedNodes:invalidInput",
                "A must be a sparse matrix.");
    }
    if (!mxIsDouble(CANDIDATE_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:undecidedNodes:invalidInput",
                "CANDIDATE must be a double-precision floating-point array.");
    }
    if (!mxIsLogical(ISOPEN_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:undecidedNodes:invalidInput",
                "ISOPEN must be a logical array.");
    }
    if (!mxIsDouble(NUMBINS_IN)
    || ((mxGetM(NUMBINS_IN) != 1) && (mxGetN(NUMBINS_IN) != 1))) {
        mexErrMsgIdAndTxt( "MATLAB:undecidedNodes:invalidInput",
                "NUMBINS must be a scalar.");
    }
    
    /* Check for proper sizes of input and output arguments --
     * omitting full implementation, doing a simple example only */
    m = mxGetM(A_IN);
    n = mxGetN(A_IN);
    
    if (m != n) {
        mexErrMsgIdAndTxt( "MATLAB:undecidedNodes:invalidInput",
                "A must be square.");
    }
    /* -- could be empty --
    if ((mxGetM(CANDIDATE_IN) != 1) && (mxGetN(CANDIDATE_IN) != 1)) {
        mexErrMsgIdAndTxt( "MATLAB:undecidedNodes:invalidInput",
                "CANDIDATE must be a vector.");
    }
     */
    if (((mxGetM(ISOPEN_IN) != 1) || (mxGetN(ISOPEN_IN) != n)) &&
            ((mxGetM(ISOPEN_IN) != n) || (mxGetN(ISOPEN_IN) != 1))) {
        mexErrMsgIdAndTxt( "MATLAB:undecidedNodes:invalidInput",
                "ISOPEN must be a vector of the same size as N's dimension.");
    }
    if (mxGetScalar(NUMBINS_IN) <= 0) {
        mexErrMsgIdAndTxt( "MATLAB:undecidedNodes:invalidInput",
                "NUMBINS_IN must be a positive integer.");
    }
}
