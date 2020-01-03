
/*=================================================================
 * eliminationOperators.c
 *
 * Compute elimination operators (restriction and affine term matrix)
 * for an F-C graph node partitioning.
 *
 * MATLAB usage: [R,q] = eliminationOperators(A, f, c_index)
 *=================================================================*/
#include "mex.h"
#include "elimination.h"
#include <math.h>       /* Needed for the ceil() prototype */

/* Input arguments */
#define A_IN            prhs[0]
#define F_IN            prhs[1]
#define C_INDEX_IN      prhs[2]

/* Output arguments */
#define R_OUT           plhs[0]
#define Q_OUT           plhs[1]

/* Function declarations */
static void            checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

/*
 * Main gateway function called by MATLAB.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    mwSize  n, nc, nf, nzmax, nzmax_old;
    mwIndex *A_jcol, *A_irow, *R_jcol, *R_irow;
    mwSize  i, j, k, l, ff, colStart, colEnd;
    int     c;
    double  *c_index, *f, *A, *Af, *R, *Rf, *q, scalingFactor;
    
    /* Read and validate input, output arguments */
    checkArguments(nlhs, plhs, nrhs, prhs);
    n           = mxGetN(A_IN);
    A_irow      = mxGetIr(A_IN);
    A_jcol      = mxGetJc(A_IN);
    A           = mxGetPr(A_IN);
    nf          = (mxGetN(F_IN) == 1) ? mxGetM(F_IN) : mxGetN(F_IN);
    nc          = n-nf;
    c_index     = mxGetPr(C_INDEX_IN);
    
    /* Allocate output arrays */
    // TODO: fix memory leak when the initial allocation is smaller than 4*nf (chosen
    // to avoid the bug as we don't eliminate nodes with deg>4). When mxRealloc() is called,
    // MATLAB intermittently crashes.
    nzmax       = (mwSize)ceil((double)nf * 2.5); // Initial allocation assumes 2.5 neighbors per F-node. Increment by 20% below if not sufficient
    //mexPrintf("Initial R allocation size %d\n", nzmax);
    R_OUT       = mxCreateSparse(nc, nf, nzmax, mxREAL);
    R_irow      = mxGetIr(R_OUT);
    R_jcol      = mxGetJc(R_OUT);
    R           = mxGetPr(R_OUT);
    Q_OUT       = mxCreateDoubleMatrix(nf, 1, mxREAL);

    /* Main loop over F-columns of A (A(:,j), j in F) */
    //mexPrintf("n=%d, nf=%d, nc=%d\n", n, nf, nc);
    for (ff = 0, f = mxGetPr(F_IN), k = 0, q = mxGetPr(Q_OUT); 
        ff < nf;
        ff++, f++, q++, R_jcol++) {
        *R_jcol = k;
        j = (int)(*f)-1; // j is 0-based, f_in input array is 1-based
        //mexPrintf("j=%d R_jcol=%d R_jcol[%d]=%d\n", j, *R_jcol, ff, *(mxGetJc(R_OUT)+ff));
        colStart    = A_jcol[j];
        colEnd      = A_jcol[j+1];
        //mexPrintf("\tCol range %d--%d\n", colStart, colEnd);
        
        /* 
         * Loop over i in A(:,j). the diagonal element i=f is 
         * saved for q; all others are assigned p-weights. At the end
         * of column processing, we scale all p-weights by -q.
         */
        for (l = colStart, Af = A+colStart; l < colEnd; l++, Af++) {
            i = A_irow[l];
            if (j == i) {
                // q(j) <- 1/A(j,j); save the p-row scaling factor -1/A(j,j)
                *q = 1.0/(*Af);
                scalingFactor = -(*q);
                //mexPrintf("\t\tq=%f, scalingFactor=%f\n", *q, scalingFactor);
            } else {
                // Off diagonal element
                //mexPrintf("\t\tOff diag i=%d, a=%f\n", i, *Af);
                /*
                 * Check to see if non-zero element will fit in
                 * allocated output array.  If not, increase allocation
                 * by 20%, recalculate nz, and augment the sparse array.
                 */
                if (k >= nzmax) {
                    nzmax_old = nzmax;
                    nzmax = (mwSize)ceil((double)nzmax_old * 1.2);
                    /* make sure nz increases at least by 1 */
                    if (nzmax_old == nzmax) {
                        nzmax++;
                    }
                    //mexPrintf("Reallocating R to size %d (current k=%d)\n", nzmax, k);
                    /* Reallocate arrays */
                    R       = mxGetPr(R_OUT);
                    mxSetPr(R_OUT, (double*)mxRealloc(R, nzmax*sizeof(double)));
                    
                    R_irow  = mxGetIr(R_OUT);
                    mxSetIr(R_OUT, (mwIndex*)mxRealloc(R_irow, nzmax*sizeof(mwIndex)));
                    
                    /* Set pointers back to where we were */
                    mxSetNzmax(R_OUT, nzmax);
                    R_irow  = mxGetIr(R_OUT) + k;
                    R       = mxGetPr(R_OUT) + k;
                }
                // Initially set R(c(i),j) <- a_{ij}
                //if (realloc) {
//                    mexPrintf("here 2\n");
//                    mexPrintf("\t\tAbout to save k=%d, set R_irow=%d->%d\n", k, *R_irow, (int)c_index[i]-1);
//                }
                c = ((int)c_index[i]) - 1;
                //mexPrintf("c = %d, c >= 0 ? %d\n", c, c >= 0);
                if (c >= 0) {
                *R_irow  = c; // Convert to 0-based index
//                if (realloc) {
//                    mexPrintf("\t\tAbout to save k=%d, set R=%f->%f\n", k, *R, *Af);
//                }
                *R       = *Af;
                
                //if (k % 200 == 0) {
                //mexPrintf("\t\tSaved k=%d, i=%d, c=%d, set R_irow=%d, R=%f\n", k, i, c, *R_irow, *R);
                //}

                R_irow++;
                R++;
                k++;
                }
                //realloc = 0;
            }
        } // for i in A(:,j)

        /* 
         * Scale R row by scalingFactor = -1/A(j,j), so that
         R(i,j) = -A(i,j)/A(j,j), the elimination weights 
         */
        for (l = (*R_jcol), Rf = mxGetPr(R_OUT)+(*R_jcol); l < k; l++, Rf++) {
            //mexPrintf("Scaling l=%d\n", l);
            *Rf *= scalingFactor;
        } // for entry in R(:,j)
    } // for j in F
    
    *R_jcol = k; // Save end index of last column
    //mexPrintf("Saving last R_jcol=%d\n", *R_jcol);
    /*
    mexPrintf("R: %d x %d\n",  mxGetM(R_OUT),  mxGetN(R_OUT));
    R_jcol = mxGetJc(R_OUT);
    mexPrintf("R_jcol=");
    for (j = 0; j <= mxGetN(R_OUT); j++) {
          mexPrintf(" %d", R_jcol[j]);
    }
    mexPrintf("\n");
     */
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
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidNumInputs",
                "Four input arguments required.");
    }
    if (nlhs < 2) {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidNumOutputs",
                "Too few output arguments.");
    }
    if (nlhs > 2) {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidNumOutputs",
                "Too many output arguments.");
    }
    
    /* Check for proper types of input and output arguments */
    if (!mxIsSparse(A_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidInput",
                "A must be a sparse matrix.");
    }
    if (!mxIsDouble(F_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidInput",
                "F must be a double-precision floating-point array.");
    }
    if (!mxIsDouble(C_INDEX_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidInput",
                "C_INDEX must be a double-precision floating-point array.");
    }

    /* Check for proper sizes of input and output arguments */
    n = mxGetN(A_IN);
    
    if (mxGetM(A_IN) != n) {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidInput",
                "A must be square.");
    }
    if ((mxGetM(F_IN) != 1) && (mxGetN(F_IN) != 1)) {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidInput",
                "F must be a vector.");
    }
    if (((mxGetM(C_INDEX_IN) != n) || (mxGetN(C_INDEX_IN) != 1)) &&
        ((mxGetM(C_INDEX_IN) != 1) || (mxGetN(C_INDEX_IN) != n))) {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidInput",
                "C_INDEX must be a vector whose size equals A's dimension.");
    }
}
