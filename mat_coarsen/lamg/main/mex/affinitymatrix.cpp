/*=================================================================
 * affinitymatrix.c
 *
 * Compute affinities between all graph neighbors of the symmetric
 * adjacency matrix W.
 *=================================================================*/
#include "mex.h"

#define W_IN   prhs[0]
#define X_IN   prhs[1]
#define C_OUT  plhs[0]

/* Function declarations */
static void            checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

/*
 * Main gateway function called by MATLAB.
 */
void
        mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    mwSize  n, p;
    mwIndex *C_jcol, *C_jcol_next, *C_irow;
    mwIndex i, j, k;
    double  *C, *x_in, *x, *xi, *y, *normSquared, *normX, nxr, innerProduct;
        
    /* Read and validate input, output arguments */
    checkArguments(nlhs, plhs, nrhs, prhs);
    n       = mxGetN(W_IN);
    p       = mxGetN(X_IN);
    
    /* Allocate an affinity matrix C with the same sparsity pattern as W's */
    C_OUT   = mxDuplicateArray(W_IN);
    
    /* Calculate the norm terms (X(i,:),X(i,:)) for all i */
    normSquared = (double*)mxCalloc(n, sizeof(double));
    for (i = 0, xi = mxGetPr(X_IN), normX = normSquared; i < n; i++, xi++, normX++) {
        for (k = 0, x = xi; k < p; k++, x += n) {
            *normX += (*x)*(*x);
        }
    }

    /* For each graph neighbors i,j, let x=X(i,:), y=X(j,:). Calculate  */
    /* C(i,j) = (sum(x.*y, 2)).^2 ./ (sum(x.*x, 2) .* sum(y.*y, 2))     */
    // Main loop over C-columns C(:,i)
    x_in        = mxGetPr(X_IN);
    xi          = mxGetPr(X_IN);
    normX       = normSquared;
    C_irow      = mxGetIr(C_OUT);
    C_jcol      = mxGetJc(C_OUT);
    C_jcol_next = C_jcol + 1;
    C           = mxGetPr(C_OUT);
    for (i = 0; i < n; i++, xi++, normX++, C_jcol++, C_jcol_next++) {
        nxr = 1./(*normX); // Reciprocal of (X(i,:),X(i,:)) -- can be reused in all C(j,i)
        //mexPrintf("\ti=%d, jcol array range of this row: %d to %d, nxr = %f\n", i, *C_jcol, *C_jcol_next-1, nxr);
        for (j = *C_jcol; j < *C_jcol_next; j++, C_irow++, C++) {
            // Compute innerProduct = (x,y) = sum(x.*y, 2)
            innerProduct = 0.;
            for (k = 0, x = xi, y = x_in + *C_irow; k < p; k++, x += n, y += n) {
                innerProduct += (*x)*(*y);
            }
            
            // C(i,j) = (sum(x.*y, 2)).^2 ./ (sum(x.*x, 2) .* sum(y.*y, 2))
            *C = (innerProduct * innerProduct) * nxr / normSquared[*C_irow];
            //mexPrintf("\t\tC(%d,%d) = %f*%f/%f = %f\n", i+1, *C_irow+1, innerProduct, nxr, normSquared[*C_irow], *C);
        }
    }

    // Free temporary arrays
    mxFree(normSquared);
}

/*
 * Check that A is a sparse n-by-n matrix.
 * Check that B and X are n-by-p double matrices.
 */
static void
        checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
//    unsigned int nu;
    mwSize n, p;
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 2) {
        mexErrMsgIdAndTxt( "MATLAB:affinitymatrix:invalidNumInputs",
                "Two input arguments required.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "MATLAB:affinitymatrix:invalidNumOutputs",
                "Too many output arguments.");
    }
    
    /* Check for proper types of input and output arguments */
    if (!mxIsSparse(W_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:affinitymatrix:invalidInputSparsity",
                "First input argument W must be a sparse array.");
    }
    if (!mxIsDouble(X_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:affinitymatrix:invalidInput",
                "Second input argument X must be a double-precision floating-point array.");
    }
    
    /* Check for proper sizes of input and output arguments */
    n   = mxGetN(W_IN);
    p   = mxGetN(X_IN);
    
    if (mxGetM(W_IN) != n) {
        mexErrMsgIdAndTxt( "MATLAB:affinitymatrix:invalidInput",
                "W must be square.");
    }
    if (mxGetM(X_IN) != n) {
        mexErrMsgIdAndTxt( "MATLAB:affinitymatrix:invalidInput",
                "Row size of X must equal the column size of W.");
    }
}
