/*=================================================================
 * mxgsrelax.c
 *
 * Gauss-Seidel relaxation on A*x=b.
 *=================================================================*/
#include "mex.h"

#define A_IN   prhs[0]
#define X_IN   prhs[1]
#define R_IN   prhs[2]
#define NU_IN  prhs[3]
#define X_OUT  plhs[0]
#define R_OUT  plhs[1]

/* Function declarations */
static unsigned int    get_as_uint32(const mxArray *x);
static void            checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

/*
 * Main gateway function called by MATLAB.
 */
void
        mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    unsigned int nu;
    mwSize  n, p;
    mwIndex *A_jcol, *A_jcol_next, *A_irow, *A_irow_old;
    mwIndex i, j, k, m, sweep, x_col_offset;
    double  *A, *A_old, *x, *r, *xk, *rk, aii, delta;
        
    /* Read and validate input, output arguments */
    checkArguments(nlhs, plhs, nrhs, prhs);
    n   = mxGetN(A_IN);
    p   = mxGetN(X_IN);
    nu  = get_as_uint32(NU_IN);
    
    /* Create a solution output array to be changed in-place */
    X_OUT = mxDuplicateArray(X_IN);
    R_OUT = mxDuplicateArray(R_IN);
    
    /* Main loop over problems */
    for (k = 0; k < p; k++) {
        // Get to the start of x(:,k), r(:,k) and b(:,k)
        x_col_offset = n*k;
        xk  = mxGetPr(X_OUT) + x_col_offset;
        rk  = mxGetPr(R_OUT) + x_col_offset;
        
        /* Loop over Gauss-Seidel sweeps */
        for (sweep = 0; sweep < nu; sweep++) {
            x = xk;
            r = rk;
            //mexPrintf("Problem %d, sweep %d\n", k, sweep);
            A           = mxGetPr(A_IN);
            A_irow      = mxGetIr(A_IN);
            A_jcol      = mxGetJc(A_IN);     // Points to start of col j
            A_jcol_next = A_jcol + 1;
            for (i = 0; i < n; i++, x++, r++, A_jcol++, A_jcol_next++) {
                /* Use A's symmetry: access row i by accessing column i,
                 * which is faster in CSR format */
                /* x(i) <- (b(i) - sum_{j!=i}(A(:,i)*x(i)))/(A(i,i)) */
                //mexPrintf("\tRow %d\n", i);

                // Find diagonal element. This loop could be eliminated
                // by passing-in A's pre-computed diagonal
                A_old = A;
                A_irow_old = A_irow;
                for (j = *A_jcol; j < *A_jcol_next; j++, A++, A_irow++) {
                    if (*A_irow == i) {
                        // Diagonal element
                        aii = *A;
                        break;
                    }
                }
                A = A_old;
                A_irow = A_irow_old;
                //mexPrintf("\t\tA(%d,%d) = %f\n", i+1, i+1, aii);

                delta = *r/aii;
                *x += delta;
                //mexPrintf("\ttx(%d) <- %f\n", i+1, *x);
                //mexPrintf("\tjcol array range of this row: %d to %d\n", *A_jcol, *A_jcol_next-1);
                for (j = *A_jcol; j < *A_jcol_next; j++, A++, A_irow++) {
                    m = *A_irow;
                    if (m == i) {
                        // Diagonal element: annihilate current dynamic residual
                        *r = 0;
                        //mexPrintf("\t\tA(%d,%d) = %f\n", i+1, i+1, aii);
                    } else {
                        // Off-diagonal element
                        rk[m] -= delta * (*A);
                    }
                }
                //mexPrintf("\t\tx(%d) <- %f\n", i+1, *x);
            }
        }
    }
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
    if (nrhs != 4) {
        mexErrMsgIdAndTxt( "MATLAB:gsrelax:invalidNumInputs",
                "Four input arguments required.");
    }
    if (nlhs > 2) {
        mexErrMsgIdAndTxt( "MATLAB:gsrelax:invalidNumOutputs",
                "Too many output arguments.");
    }
    
    /* Check for proper types of input and output arguments */
    if (!mxIsSparse(A_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:gsrelax:invalidInputSparsity",
                "First input argument A must be a sparse array.");
    }
    if (!mxIsDouble(X_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:gsrelax:invalidInput",
                "Third input argument X must be a double-precision floating-point array.");
    }
    if (!mxIsDouble(R_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:gsrelax:invalidInput",
                "Fourth input argument R must be a double-precision floating-point array.");
    }
    if (mxGetClassID(NU_IN) != mxUINT32_CLASS)  {
        mexErrMsgIdAndTxt( "MATLAB:gsrelax:invalidInput",
                "Fifth input argument NU must be a uint32 unsigned integer.");
    }
    
    /* Check for proper sizes of input and output arguments */
    n   = mxGetN(A_IN);
    p   = mxGetN(X_IN);
    // nu  = get_as_uint32(NU_IN); // May need validation here in the future
    
    if (mxGetM(A_IN) != n) {
        mexErrMsgIdAndTxt( "MATLAB:gsrelax:invalidInput",
                "A must be square.");
    }
    if (mxGetM(X_IN) != n) {
        mexErrMsgIdAndTxt( "MATLAB:gsrelax:invalidInput",
                "Row size of X must equal the column size of A.");
    }
    if (mxGetM(R_IN) != n) {
        mexErrMsgIdAndTxt( "MATLAB:gsrelax:invalidInput",
                "Row size of R must equal the column size of X.");
    }
    if (mxGetN(R_IN) != p) {
        mexErrMsgIdAndTxt( "MATLAB:gsrelax:invalidInput",
                "Column size of R must equal the column size of X.");
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
