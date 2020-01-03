/*=================================================================
 * lowdegreesweep.cpp
 *
 * Sweep over an undirected graph and mark an independent set of
 * low-degree nodes.
 *=================================================================*/
#include "mex.h"
#include "elimination.h"

/* Input arguments */
#define STATUS_IN      prhs[0]
#define A_IN           prhs[1]
#define CANDIDATE_IN   prhs[2]
//#define MAXDEGREE_IN   prhs[3]

/* Output arguments */
#define STATUS_OUT     plhs[0]

/* Function declarations */
//static unsigned int    get_as_uint32(const mxArray *x);
static void            checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

/*
 * Main gateway function called by MATLAB.
 */
void
        mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    unsigned int /* maxDegree, */ hasLowDegreeNeighbor;
    mwSize  n;
    mwIndex *A_jcol, *A_irow;
    mwIndex i, j, k, l, colStart, colEnd;
    double  *candidate, *status;
        
    /* Read and validate input, output arguments */
    checkArguments(nlhs, plhs, nrhs, prhs);
    n           = mxGetN(A_IN);
    A_irow      = mxGetIr(A_IN);
    A_jcol      = mxGetJc(A_IN);        // Points to start of col A(:,j)
    //maxDegree   = get_as_uint32(MAXDEGREE_IN);
    
    /* Duplicate STATUS input array into an output array, to be changed in-place */
    STATUS_OUT = mxDuplicateArray(STATUS_IN);
    status     = mxGetPr(STATUS_OUT);
    
    /* Main loop over candidate nodes */
    //mexPrintf("#candidates=%d\n", mxGetN(CANDIDATE_IN));
    for (k = 0, candidate = mxGetPr(CANDIDATE_IN); k < mxGetN(CANDIDATE_IN); k++, candidate++) {
        i = (*candidate)-1; // i is 0-based, candidate values are 1-based
        //mexPrintf("i=%d   status=%d\n", i, status[i]);
        if (!status[i]) {
            // i hasn't been marked yet, try to mark it now
            colStart    = A_jcol[i];
            colEnd      = A_jcol[i+1];
            //mexPrintf("\tCol range %d--%d\n", colStart, colEnd);
            
            // Check if i has a low-degree neighbor j
            // (l = neighbor index). Ignore diagonal elements.
            hasLowDegreeNeighbor = 0;
            for (l = colStart; l < colEnd; l++) {
                j = A_irow[l];
                //mexPrintf("\tnbhr=%d  status=%d\n", j, status[j]);
                if ((j != i) && (status[j] == LOW_DEGREE)) {
                    hasLowDegreeNeighbor = 1;
                    break;
                }
            }
            //mexPrintf("\thasLowDegreeNeighbor=%d\n", hasLowDegreeNeighbor);
                        
            if (hasLowDegreeNeighbor) {
                // Node has a low-degree neighbor, cannot be eliminated
                status[i] = NOT_ELIMINATED;
            } else {
                // % Check i's neighbors (omitted here to save work)
                // %         if (isempty(find(status(nbhrs) == LOW_DEGREE, 1)) && ...
                // %                 ((degree <= MAX_DEGREE_UNCHECKED) || (numel(find(W(nbhrs,nbhrs))) <= degree)))

                // A node whose elimination does not increase the number of
                // A-edges [by much, if maxDegree <= 4] and does not depend on another candidate ==>
                // can be eliminated. Its neighbors cannot be eliminated so that F is independent.
                status[i] = LOW_DEGREE;
                //mexPrintf("\tMarking i as %d\n", status[i]);
                for (l = colStart; l < colEnd; l++) {
                    j = A_irow[l];
                    if (j != i) {
                        status[j] = NOT_ELIMINATED;
                        //mexPrintf("\tMarking nbhr %d as %d\n", j, status[j]);
                    }
                }
            }
        } // if i not status yet
    } // for candidates
}

/*
 * Check that A is a sparse n-by-n matrix.
 * Check that CANDIDATE is m-by-1.
 */
static void
        checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    mwSize n;
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 3) {
        mexErrMsgIdAndTxt( "MATLAB:lowdegreesweep:invalidNumInputs",
                "Three input arguments required.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "MATLAB:lowdegreesweep:invalidNumOutputs",
                "Too many output arguments.");
    }
    
    /* Check for proper types of input and output arguments */
    if (!mxIsDouble(STATUS_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:lowdegreesweep:invalidInput",
                "First input argument STATUS must be a double-precision floating-point array.");
    }
    if (!mxIsDouble(A_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:lowdegreesweep:invalidInput",
                "Second input argument A must be a double-precision floating-point array.");
    }
    if (!mxIsDouble(CANDIDATE_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:lowdegreesweep:invalidInput",
                "Third input argument CANDIDATE must be a double-precision floating-point array.");
    }
    /*
    if (mxGetClassID(MAXDEGREE_IN) != mxUINT32_CLASS)  {
        mexErrMsgIdAndTxt( "MATLAB:lowdegreesweep:invalidInput",
                "Fourt input argument MAXDEGREE must be a uint32 unsigned integer.");
    }
     */
    
    /* Check for proper sizes of input and output arguments */
    n   = mxGetN(A_IN);
    
    if (mxGetM(A_IN) != n) {
        mexErrMsgIdAndTxt( "MATLAB:lowdegreesweep:invalidInput",
                "A must be square.");
    }
    if (mxGetM(CANDIDATE_IN) > n) {
        mexErrMsgIdAndTxt( "MATLAB:lowdegreesweep:invalidInput",
                "CANDIDATE's size cannot be larger than A's size.");
    }
    if (mxGetM(CANDIDATE_IN) != 1) {
        mexErrMsgIdAndTxt( "MATLAB:lowdegreesweep:invalidInput",
                "CANDIDATE must be a row vector.");
    }
}

/* Convert input argument to unsigned int. */
/*
static unsigned int
        get_as_uint32(const mxArray *x)
{
    unsigned int *pr;
    pr = (unsigned int *)mxGetData(x);
    return pr[0];
}
*/
