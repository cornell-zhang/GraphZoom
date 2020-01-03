/*=================================================================
 * filterSmallEntries.c
 *
 * Filter small entries from a real sparse matrix A relative to a
 * bound vector b. (Should work even for non-symmetric matrices.)
 *=================================================================*/
#include "mex.h"
#include <string.h>
#include <math.h>

#define A_IN            prhs[0]
#define B_IN            prhs[1]
#define DELTA_IN        prhs[2]
#define ABSFLAG_IN      prhs[3]
#define BOUNDTYPE_IN	prhs[4]
#define C_OUT           plhs[0]

/* Function definitions */
typedef double (*absFlagFunction)(double);
typedef double (*boundTypeFunction)(double, double);

/* Function declarations */
static void                 checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
static double               get_as_double(const mxArray *x);
static double               identityValue(double x);
static double               maxBound(double x, double y);
static double               minBound(double x, double y);
static double               absValue(double x);
static absFlagFunction      getAbsFlagFunction(char *absFlag);
static boundTypeFunction    getBoundTypeFunction(char *boundType);

/*
 * Main gateway function called by MATLAB.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    mwSize  n, nzmax;
    mwIndex *A_jcol, *A_jcol_next, *A_irow, *C_jcol, *C_irow;
    mwIndex i, j, k;
    double  *A, *C, *b, *bi, delta;
    absFlagFunction absFlagFunc;
    boundTypeFunction boundTypeFunc;
    
    /* Read and validate input, output arguments */
    checkArguments(nlhs, plhs, nrhs, prhs);
    n               = mxGetN(A_IN);
    nzmax           = mxGetNzmax(A_IN);
    b               = mxGetPr(B_IN);
    delta           = get_as_double(DELTA_IN);
    // Determine appropriate function pointers based on flag values
    absFlagFunc     = getAbsFlagFunction(mxArrayToString(ABSFLAG_IN));
    boundTypeFunc   = getBoundTypeFunction(mxArrayToString(BOUNDTYPE_IN));
    
    /* We cannot assume that C will be sparser than A, so allocate the
     * same number of non-zeros up front. */
    C_OUT       = mxCreateSparse(n, n, nzmax, mxREAL);
    C_irow      = mxGetIr(C_OUT);
    C_jcol      = mxGetJc(C_OUT);
    C           = mxGetPr(C_OUT);

    /* Main loop over A-entries. Copy relevant entries to C-arrays. */
    A_irow      = mxGetIr(A_IN);
    A_jcol      = mxGetJc(A_IN);
    A_jcol_next = A_jcol + 1;
    A           = mxGetPr(A_IN);
    bi          = b;
    // i = column counter (A,C columns correspond to each other)
    // j = index within A-column
    // k = global C-non-zero counter
    for (k = 0, i = 0; i < n; i++, A_jcol++, A_jcol_next++, bi++, C_jcol++) {
        *C_jcol = k; // Save beginning index of column i
        // mexPrintf("\tColumn i=%d, C_jcol=%d\n", i, *C_jcol);
        for (j = *A_jcol; j < *A_jcol_next; j++, A_irow++, A++) {
            /*
            mexPrintf("\t\tA(%d,%d) = %f  abs=%f, bound(%f,%f)=%f, entry is %s\n", 
                    i+1, *A_irow+1, *A, absFlagFunc(*A), 
                    *bi, b[*A_irow], boundTypeFunc(*bi, b[*A_irow]),
                    (absFlagFunc(*A) >= delta*boundTypeFunc(*bi, b[*A_irow])) ? "large" : "small");
             */
            if (/* (*A_irow != i) && */ (absFlagFunc(*A) >= delta*boundTypeFunc(*bi, b[*A_irow]))) {
                // Copy large off-diagonal entry to C. It satisfies 
                // ABSFUNC[ A(I,J) ] >= DELTA * BOUNDFUNC [ B(I),B(J) ]
                *C_irow = *A_irow;
                *C      = *A;
                // mexPrintf("\t\t\tC(%d,%d) = %f\n", i+1, *C_irow+1, *C);
                
                // Advance pointers to next 
                C_irow++;
                C++;
                k++;
            }
        }
    }
    *C_jcol = k; // Save end index of last column
    // mexPrintf("\tColumn i=%d, C_jcol=%d\n", n, *C_jcol);
}

/*
 * Check that A is a sparse n-by-n matrix.
 * Check that B and X are n-by-p double matrices.
 */
static void checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    mwSize n;
    
    /* Check for proper number of input and output arguments */
    if (nrhs != 5) {
        mexErrMsgIdAndTxt( "MATLAB:filterSmallEntries:invalidNumInputs",
                "Five input arguments required.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt( "MATLAB:filterSmallEntries:invalidNumOutputs",
                "Too many output arguments.");
    }
    
    /* Check for proper types of input and output arguments */
    if (!mxIsSparse(A_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:filterSmallEntries:invalidInputSparsity",
                "First input argument A must be a sparse array.");
    }
    if (!mxIsDouble(B_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:filterSmallEntries:invalidInput",
                "Second input argument X must be a double-precision floating-point array.");
    }
    if (!mxIsDouble(DELTA_IN))  {
        mexErrMsgIdAndTxt( "MATLAB:filterSmallEntries:invalidInput",
                "Third input argument DELTA must be a double-precision floating-point number.");
    }
    
    /* Check for proper sizes of input and output arguments */
    n   = mxGetN(A_IN);
    
    if (mxGetM(A_IN) != n) {
        mexErrMsgIdAndTxt( "MATLAB:filterSmallEntries:invalidInput",
                "A must be square.");
    }
    if (((mxGetM(B_IN) != n) || (mxGetN(B_IN) != 1)) &&
            ((mxGetM(B_IN) != 1) || (mxGetN(B_IN) != n)))
    {
        mexErrMsgIdAndTxt( "MATLAB:filterSmallEntries:invalidInput",
                "B must be a vector whose size equals A's.");
    }
    if ((mxGetM(DELTA_IN) != 1) || (mxGetN(DELTA_IN) != 1))
    {
        mexErrMsgIdAndTxt( "MATLAB:filterSmallEntries:invalidInput",
                "DELTA must be scalar.");
    }
    if (!mxIsChar(ABSFLAG_IN)) {
        mexErrMsgIdAndTxt( "MATLAB:filterSmallEntries:invalidInput",
                "ABSFLAG must be a string.");
    }
    if (!mxIsChar(BOUNDTYPE_IN)) {
        mexErrMsgIdAndTxt( "MATLAB:filterSmallEntries:invalidInput",
                "BOUNDTYPE must be a string.");
    }
}

/* Convert input argument to double. */
static double
        get_as_double(const mxArray *x)
{
    double *pr;
    pr = (double *)mxGetData(x);
    return pr[0];
}

/*
 * Convert the ABSTYPE flag into the corresponding functor.
 */
static absFlagFunction getAbsFlagFunction(char *absFlag)
{
    if (strcmp(absFlag, "value") == 0) {
        return &identityValue;
    } 
    else if (strcmp(absFlag, "abs") == 0) {
        return &absValue;
    } 
    else {
        mexErrMsgIdAndTxt( "MATLAB:filterSmallEntries:invalidInput",
                "ABSFLAG must be a 'value' or 'abs'.");
    }
}

/*
 * Convert the BOUNDTYPE flag into the corresponding functor.
 */
static boundTypeFunction getBoundTypeFunction(char *boundType)
{
    if (strcmp(boundType, "max") == 0) {
        return &maxBound;
    } 
    else if (strcmp(boundType, "min") == 0) {
        return &minBound;
    } 
    else {
        mexErrMsgIdAndTxt( "MATLAB:filterSmallEntries:invalidInput",
                "BOUNDTYPE must be a 'max' or 'min'.");
    }
}

/*
 * Identity functor.
 */
static double identityValue(double x)
{
    return x;
}

/*
 * Absolute-value functor.
 */
static double absValue(double x)
{
    return fabs(x);
}

/*
 * Maximum functor.
 */
static double maxBound(double x, double y)
{
    return (x < y) ? y : x;
}

/*
 * Minimum functor.
 */
static double minBound(double x, double y)
{
    return (x > y) ? y : x;
}
