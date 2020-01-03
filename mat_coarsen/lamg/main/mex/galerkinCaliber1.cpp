/*=================================================================
 * galerkinCaliber1.cpp
 *
 * Compute B = R*A*P where R=P' and P are a caliber-1 restriction and
 * interpolation operators, respectively.
 *=================================================================*/
#include "mex.h"
#include <math.h>       /* Needed for the ceil() prototype */
#include <iostream>     /* For printouts */
#include <vector>       /* For STL vector */
#include <algorithm>    /* For sort */
using namespace std;

#define R_IN    prhs[0]
#define A_IN    prhs[1]
#define P_IN    prhs[2]
#define B_OUT   plhs[0]

/* Function declarations */
static void     checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

/*
 * Main gateway function called by MATLAB.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    /* Index convention: small letter = fine quantity; capital letter = coarse quantity */
    mwSize  n, N, nz, NZMAX;
    mwIndex i, j, I, J, p, a, b, k;
    
    mwIndex *A_jcol, *A_jcol_next, *A_irow, *Ai_irow;
    mwIndex *P_jcol, *P_jcol_next, *P_irow;
    mwIndex *R_irow;                    // Since R is caliber-1, no need to keep track of jcol - each column has 1 non-zero
    mwIndex *B_jcol, *B_irow;
    double  *A, *Ai, *P, *R, *B, *B_column, percent_sparse;
    int     *B_in_column;
    
    /* Read and validate input, output arguments */
    checkArguments(nlhs, plhs, nrhs, prhs);
    n               = mxGetN(A_IN);     // # fine nodes
    N               = mxGetN(P_IN);     // # coarse nodes
    
    /* Initialize input matrix array pointers */
    A_irow      = mxGetIr(A_IN);
    A_jcol      = mxGetJc(A_IN);
    A_jcol_next = A_jcol + 1;
    A           = mxGetPr(A_IN);
    
    P_irow      = mxGetIr(P_IN);
    P_jcol      = mxGetJc(P_IN);
    P_jcol_next = P_jcol + 1;
    P           = mxGetPr(P_IN);
    
    R_irow      = mxGetIr(R_IN);
    R           = mxGetPr(R_IN);
    
    /* Initial coarse matrix allocation: 20% of fine edges */
    percent_sparse  = 0.2;
    nz              = A_jcol[n]; // fine matrix non-zero allocation
    NZMAX           = (mwSize)ceil((double)nz*percent_sparse);
    B_OUT           = mxCreateSparse(N, N, NZMAX, mxREAL);
    B_irow          = mxGetIr(B_OUT);
    B_jcol          = mxGetJc(B_OUT);
    B               = mxGetPr(B_OUT);
    
    /*
     * Allocate work arrays used in calculating a single B(:,J) column.
     * Using redundant access (basically, a hash of all possible coarse entries)
     * for speed.
     */
    B_column        = (double*)mxCalloc(N, sizeof(double)); // A hash table = the full B(:,J)
    B_in_column     = (int*)mxCalloc(N, sizeof(int));       // A flag array indicating whether B(I,J) is non-zero
    vector<int> B_column_irow;                              // Indices I in the column (not unique but a compressed representation of B_in_column). Initial allocation: 100 non-zeros
    
    /*
     * Loop over B-columns (J). Each J is the aggregate of several
     * fine indices j in P(:,J) = R(J,:). Accumulate the B-column into
     * the work array. k = running index over the B arrays.
     */
    for (J = 0, k = 0; J < N; J++, P_jcol++, P_jcol_next++, B_jcol++) {
        *B_jcol = k;
        /* For each j in P(:,J) */
        for (p = *P_jcol; p < *P_jcol_next; p++, P_irow++, P++) {
            j = *P_irow;
            /* For each i in A(:,j) */
            for (a = A_jcol[j], Ai_irow = A_irow+a, Ai = A+a;
            a < A_jcol_next[j];
            a++, Ai_irow++, Ai++) {
                i = *Ai_irow;
                I = R_irow[i];
                /*
                 * Accumulate into work arrays:
                 * B(I,J) += R(J,j)*A(i,j)*P(i,I)
                 * (R term obtained from P and P term obtained from R)
                 */
                B_column[I] += R[i] * (*Ai) * (*P);
                /* Mark I as a non-zero in this column if it is not marked yet */
                if (!B_in_column[I]) {
                    B_in_column[I] = true;
                    B_column_irow.insert(B_column_irow.end(), I);
                }
            } // for i (I)
        } // for j
        
        /* Append column to sparse B data structure */
        //mexPrintf("\tSaving cumulative row J=%d\n", j);
        /* MATLAB CSR format seems to require sorted irow indices within each column */
        std::sort(B_column_irow.begin(), B_column_irow.end());
        for (vector<int>::iterator b = B_column_irow.begin();
        b != B_column_irow.end(); b++) {
            /*
             * Check to see if non-zero element will fit in
             * allocated output array.  If not, increase percent_sparse
             * by 10%, recalculate nz, and augment the sparse array.
             */
            if (k >= NZMAX) {
                mwSize NZMAX_old = NZMAX;
                percent_sparse += 0.1;
                NZMAX = (mwSize)ceil((double)nz*percent_sparse);
                /* make sure nz increases at least by 1 */
                if (NZMAX_old == NZMAX) {
                    NZMAX++;
                }
                /* Reallocate arrays */
                mxSetNzmax(B_OUT, NZMAX);
                B_irow  = mxGetIr(B_OUT);
                mxSetIr(B_OUT, (mwIndex*)mxRealloc(B_irow, NZMAX*sizeof(mwIndex)));
                B       = mxGetPr(B_OUT);
                mxSetPr(B_OUT, (double*)mxRealloc(B, NZMAX*sizeof(double)));
                /* Set pointers back to where we were */
                B_irow  = mxGetIr(B_OUT) + k;
                B       = mxGetPr(B_OUT) + k;
            }
            
            /* Save non-zero entry */
            *B_irow  = *b;
            *B       = B_column[*b];
            B_irow++;
            B++;
            k++;
            
            /* Clear column work arrays while at it */
            B_column[*b] = 0.0;
            B_in_column[*b] = false;
        }
        B_column_irow.clear();
    } // for J
    
    *B_jcol = k; // Save end index of last column
    
    /* Clean up */
    mxFree(B_column);
    mxFree(B_in_column);
}

/*
 * Check that A is a sparse n-by-n matrix.
 * Check that B and X are n-by-p double matrices.
 */
static void checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    mwSize m, n;
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 3) {
        mexErrMsgIdAndTxt( "MATLAB:galerkinCaliber1:invalidNumInputs",
                "3 input arguments required.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "MATLAB:galerkinCaliber1:invalidNumOutputs",
                "Too many output arguments.");
    }
    
    /* Check for proper types of input and output arguments */
    if (!mxIsSparse(R_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:galerkinCaliber1:invalidInputSparsity",
                "R must be a sparse array.");
    }
    if (!mxIsSparse(A_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:galerkinCaliber1:invalidInputSparsity",
                "A must be a sparse array.");
    }
    if (!mxIsSparse(P_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:galerkinCaliber1:invalidInputSparsity",
                "P must be a sparse array.");
    }
    
    /* Check for proper sizes of input and output arguments */
    m = mxGetM(A_IN);
    n = mxGetN(A_IN);
    
    if (m != n) {
        mexErrMsgIdAndTxt( "MATLAB:galerkinCaliber1:invalidInput",
                "A must be square for the time being.");
    }
    if (mxGetN(R_IN) != m) {
        mexErrMsgIdAndTxt( "MATLAB:galerkinCaliber1:invalidInput",
                "R's column size must equals A's row size.");
    }
    if (mxGetM(P_IN) != n) {
        mexErrMsgIdAndTxt( "MATLAB:galerkinCaliber1:invalidInput",
                "P's row size must equals A's column size.");
    }
}
