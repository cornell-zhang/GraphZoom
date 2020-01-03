/*=================================================================
 * medianCol.cpp
 *
 * Compute the median of values of a vector over the non-zero
 * indices of each column of a sparse matrix.
 *
 * MATLAB syntax: y = medianCol(A,x)
 *=================================================================*/
#include "mex.h"
#include <vector>       /* For STL vector */
#include <algorithm>    /* For median computation */
using namespace std;

/* Input arguments */
#define A_IN        prhs[0]
#define X_IN        prhs[1]

/* Output arguments */
#define Y_OUT       plhs[0]

/* Function declarations */
static void     checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
static double   median(vector<double> &v);
/*
 * Main gateway function called by MATLAB.
 */
void
        mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    mwSize  n;
    mwIndex *A_jcol, *A_jcol_next, *A_irow;
    mwIndex i, j, k, nnz;
    double  *x, *y;
    vector<double> z;
    
    /* Read and validate input, output arguments */
    checkArguments(nlhs, plhs, nrhs, prhs);
    n           = mxGetN(A_IN);
    A_irow      = mxGetIr(A_IN);
    A_jcol      = mxGetJc(A_IN);        /* Points to start of col A(:,j) */
    A_jcol_next = A_jcol + 1;
    x           = mxGetPr(X_IN);
    
    /* Duplicate STATUS input array into an output array, to be changed in-place */
    Y_OUT       = mxCreateNumericMatrix(0, 0, mxDOUBLE_CLASS, mxREAL);
    y           = (double*)mxCalloc(n, sizeof(double)); // A hash table = the full B(:,J)
    mxSetPr(Y_OUT, y);
    mxSetM(Y_OUT, mxGetM(X_IN));
    mxSetN(Y_OUT, mxGetN(X_IN));
    
    /* Main loop over A-columns */
    for (j = 0; j < n; j++, A_jcol++, A_jcol_next++, y++) {
        /* Create an empty vector with a space for nnz[j] non-zeros */
        nnz = (*A_jcol_next) - (*A_jcol);
        if (nnz > 0) {
            z.clear();
            z.reserve(nnz);
        }
        /*
         * Loop over non-zero elements in A(:,j) and copy the
         * corresponding x values into z
         */
        for (k = *A_jcol; k < *A_jcol_next; k++, A_irow++) {
            z.push_back(x[*A_irow]);
        }

        /* Find the median of z and store it in y[j] */
        if (nnz > 0) {
            *y = median(z);
        }
    } // for j in A-columns
}

/*
 * Check that A is a sparse n-by-n matrix.
 * Check that X is n-by-1.
 */
static void
        checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    mwSize n;
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 2) {
        mexErrMsgIdAndTxt( "MATLAB:medianCol:invalidNumInputs",
                "Two input arguments required.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "MATLAB:medianCol:invalidNumOutputs",
                "Too many output arguments.");
    }
    
    /* Check for proper types of input and output arguments */
    if (!mxIsSparse(A_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:medianCol:invalidInput",
                "First input argument A must be a sparse matrix.");
    }
    if (!mxIsDouble(X_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:medianCol:invalidInput",
                "Second input argument X must be a double-precision floating-point array.");
    }
    
    /* Check for proper sizes of input and output arguments */
    n = (mxGetN(X_IN) == 1) ? mxGetM(X_IN) : mxGetN(X_IN);
    if ((mxGetM(A_IN) != n) || (mxGetN(A_IN) != n)) {
        mexErrMsgIdAndTxt( "MATLAB:medianCol:invalidInput",
                "A must be NxN, where X is Nx1.");
    }
    if ((mxGetM(X_IN) > 1) && (mxGetN(X_IN) > 1)) {
        mexErrMsgIdAndTxt( "MATLAB:medianCol:invalidInput",
                "X must be a vector.");
    }
}

/* Calculate the [n/2+1]-element of a vector. */
double median(vector<double> &v)
{
    size_t n = v.size() / 2;
    nth_element(v.begin(), v.begin()+n, v.end());
    return v[n];
}
