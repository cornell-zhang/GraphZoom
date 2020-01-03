/*=================================================================
 * galerkinElimination.cpp
 *
 * Compute B = A(c,c)+P*A(c,f) where P is an elimination
 * interpolation.
 *
 * MATLAB usage:  B = galerkinElimination(A, R, status, c, index)
 *=================================================================*/
#include "mex.h"
#include "elimination.h"
#include <math.h>       /* Needed for the ceil() prototype */
#include <iostream>     /* For printouts */
#include <vector>       /* For STL vector */
#include <algorithm>    /* For sort */
using namespace std;

/* Input arguments */
#define A_IN        prhs[0]
#define R_IN        prhs[1]
#define STATUS_IN   prhs[2]
#define C_IN        prhs[3]
#define INDEX_IN    prhs[4]

/* Output arguments */
#define B_OUT       plhs[0]

/* Function declarations */
static void     checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

/*
 * Main gateway function called by MATLAB.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    /* Index convention: small letter = fine quantity; capital letter = coarse quantity */
    mwSize  n, nc, nf, NZMAX;
    mwIndex i, j, r, a, b, k, q, cc;
    int     m;
    
    mwIndex *A_jcol, *A_irow, *Aj_irow;
    mwIndex *R_jcol, *R_irow, *Ri_irow;
    mwIndex *B_jcol, *B_irow;
    double  *A, *Aj, *R, *Ri, *B, *B_column, percent_sparse, *c, *c_node, *index, *status;
    int     *B_in_column;
    
    /* Read and validate input, output arguments */
    checkArguments(nlhs, plhs, nrhs, prhs);
    n           = mxGetN(A_IN);     // total # nodes
    nc          = mxGetM(R_IN);     // # C nodes
    nf          = mxGetN(R_IN);     // # F nodes
    status      = mxGetPr(STATUS_IN);
    c           = mxGetPr(C_IN);
    index       = mxGetPr(INDEX_IN);
    
    /* Initialize input matrix array pointers */
    A_irow      = mxGetIr(A_IN);
    A_jcol      = mxGetJc(A_IN);
    A           = mxGetPr(A_IN);
    
    R_irow      = mxGetIr(R_IN);
    R_jcol      = mxGetJc(R_IN);
    R           = mxGetPr(R_IN);
    
    /* Initial coarse matrix allocation: 20% of fine edges */
    percent_sparse  = 0.2;
    NZMAX           = (mwSize)ceil((double)A_jcol[n]*percent_sparse);
    B_OUT           = mxCreateSparse(nc, nc, NZMAX, mxREAL);
    B_irow          = mxGetIr(B_OUT);
    B_jcol          = mxGetJc(B_OUT);
    B               = mxGetPr(B_OUT);
    
    /*
     * Allocate work arrays used in calculating a single B(:,J) column.
     * Using redundant access (basically, a hash of all possible coarse entries)
     * for speed.
     */
    B_column        = (double*)mxCalloc(nc, sizeof(double)); // A hash table = the full B(:,J)
    B_in_column     = (int*)mxCalloc(nc, sizeof(int));       // A flag array indicating whether B(I,J) is non-zero
    vector<int> B_column_irow;                               // Indices I in the column (not unique but a compressed representation of B_in_column). Initial allocation: 100 non-zeros
    
    /*
     * Loop over B-columns (j in C). k = running index over the B arrays.
     */
    for (c_node = mxGetPr(C_IN), cc = 0, k = 0; cc < nc; cc++, c_node++, B_jcol++) {
        j = (int)*c_node - 1; // 0-based column index of c in the matrix A
        *B_jcol = k;
        //mexPrintf("Column cc=%d, c_node=%d, j=%d, B_jcol=%d\n", cc, (int)*c_node, j, *B_jcol);
        /* For each i in A(:,j) */
        for (a = A_jcol[j], Aj_irow = A_irow+a, Aj = A+a;
            a < A_jcol[j+1]; a++, Aj_irow++, Aj++) {
            i = *Aj_irow;
            m = (int)index[i] - 1;      // 0-based column index of i in the coarse matrix B
            //mexPrintf("\tRow i=%d, status=%d, m=%d\n", i, (int)status[i], m);
            if (status[i] != LOW_DEGREE) {
                /*
                 * i = C-neighbor. Accumulate into work arrays:
                 * B(i,j) += A(i,j)
                 */
                //mexPrintf("\t-- C-neighbor A(i,j)=%f\n", *Aj);
                B_column[m] += (*Aj);
                /* Mark c as a non-zero in this column if not marked yet */
                if (!B_in_column[m]) {
                    B_in_column[m] = true;
                    B_column_irow.push_back(m);
                }
            } else {
                //mexPrintf("\t-- F-neighbor, R_jcol range %d to %d\n", R_jcol[m], R_jcol[m+1]);
                /*
                 * i = F-neighbor. Loop over q in R(:,m(j)) and accumulate
                 * into work arrays: B(i,j) += A(i,j) * R(m,j)
                 */
                for (r = R_jcol[m], Ri_irow = R_irow+r, Ri = R+r;
                    r < R_jcol[m+1]; r++, Ri_irow++, Ri++) {
                    q = index[(int)c[*Ri_irow]-1] - 1;   // 0-based column index of C-neighbor of i in the coarse matrix B
                    B_column[q] += (*Aj) * (*Ri);
                    //mexPrintf("\t\tC-neighbor r=%d Ri_irow=%d, c=%d, q=%d, Aj=%f, Ri=%f, B=%f\n", r, *Ri_irow, (int)c[*Ri_irow], q, *Aj, *Ri, B_column[q]);
                    /* Mark m as a non-zero in this column if not marked yet */
                    if (!B_in_column[q]) {
                        B_in_column[q] = true;
                        B_column_irow.push_back(q);
                    }
                }
            }
        } // for i in A(:,j)

        /* Append column to sparse B data structure */
        //mexPrintf("\tSaving cumulative row j=%d\n", j);
        /* MATLAB CSR format seems to require sorted irow indices within each column */
        std::sort(B_column_irow.begin(), B_column_irow.end());
        for (vector<int>::iterator b = B_column_irow.begin();
        b != B_column_irow.end(); b++) {
            /*
             * Check to see if non-zero element will fit in
             * allocated output array.  If not, increase nz by 40%,
             * and augment the sparse array.
             */
            if (k >= NZMAX) {
                mwSize NZMAX_old = NZMAX;
                NZMAX = (mwSize)ceil((double)NZMAX * 1.4);
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
    } // for j in C
    
    //mexPrintf("Column j=%d, B_jcol=%d\n", j, *B_jcol);
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
    if (nrhs != 5) {
        mexErrMsgIdAndTxt( "MATLAB:galerkinElimination:invalidNumInputs",
                "5 input arguments required.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "MATLAB:galerkinElimination:invalidNumOutputs",
                "Too many output arguments.");
    }
    
    /* Check for proper types of input and output arguments */
    if (!mxIsSparse(A_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:galerkinElimination:invalidInputSparsity",
                "A must be a sparse array.");
    }
    if (!mxIsSparse(R_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:galerkinElimination:invalidInputSparsity",
                "R must be a sparse array.");
    }
    if (!mxIsDouble(STATUS_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidInput",
                "STATUS must be a double-precision floating-point array.");
    }
    if (!mxIsDouble(C_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidInput",
                "C must be a double-precision floating-point array.");
    }
    if (!mxIsDouble(INDEX_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidInput",
                "INDEX must be a double-precision floating-point array.");
    }

    /* Check for proper sizes of input and output arguments */
    m = mxGetM(A_IN);
    n = mxGetN(A_IN);
    
    if (m != n) {
        mexErrMsgIdAndTxt( "MATLAB:galerkinElimination:invalidInput",
                "A must be square for the time being.");
    }
    if (((mxGetM(STATUS_IN) != n) || (mxGetN(STATUS_IN) != 1)) &&
        ((mxGetM(STATUS_IN) != 1) || (mxGetN(STATUS_IN) != n))) {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidInput",
                "STATUS must be a vector whose size equals A's dimension.");
    }
    if ((mxGetM(C_IN) != 1) && (mxGetN(C_IN) != 1)) {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidInput",
                "C must be a vector.");
    }
    if (((mxGetM(INDEX_IN) != n) || (mxGetN(INDEX_IN) != 1)) &&
        ((mxGetM(INDEX_IN) != 1) || (mxGetN(INDEX_IN) != n))) {
        mexErrMsgIdAndTxt( "MATLAB:eliminationOperators:invalidInput",
                "INDEX must be a vector whose size equals A's dimension.");
    }
}
