/*=================================================================
 * writematrix.cpp
 *
 * write matrix to file using c, which is faster than using MATLAB
 * A can be a full or half matrix
 *=================================================================*/
#include "mex.h"
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#define A_IN prhs[0]
#define NNZ_IN prhs[1]
#define X_IN prhs[2]

/* Function declarations */
static void	checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

/*
 * Main gateway function called by MATLAB.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	char *filename;
	char buf[1000];
	int buflen, status;
	int nnz;
	mwSize n, m, i, j;
	mwSize *irow, *pcol;
	double *val;
	FILE *fp;
	
	checkArguments(nlhs, plhs, nrhs, prhs);

	/* calculate the length of the string */
	buflen = (mxGetM(X_IN)*mxGetN(X_IN))+1;

	/* Allocate memory for the input and output string */
/*	filename = (char*)mxCalloc(buflen, sizeof(char));*/

	/* Copy string data from X_IN to C string */
/*	status = mxGetString(X_IN, filename, buflen);
	mexPrintf("filename: %s\n");
	if(status != 0){
		mexWarnMsgTxt("Not enough space. String is truncated.");
	}*/

	filename = mxArrayToString(X_IN);
	if(filename == NULL){
		mexWarnMsgTxt("Not enough space. String is truncated.");
	}
	
	fp = fopen(filename, "w");
	if(fp == NULL){
		mexWarnMsgTxt("Cannot open file");
	}

	n = (mwSize) mxGetN(A_IN);
	m = (mwSize) mxGetM(A_IN);
	irow = (mwSize*)mxGetIr(A_IN);
	pcol = (mwSize*)mxGetJc(A_IN);
	val = (double*)mxGetPr(A_IN);

	nnz = (int)mxGetScalar(NNZ_IN);	

	fprintf(fp, "%zd %zd %d\n", m, n, nnz);

	for(i=0; i<n; i++){
		for(j=pcol[i]; j<pcol[i+1]; j++){
			fprintf(fp, "%zd %zd %lf\n", irow[j]+1, i+1, val[j]);
		}
	}
	
	fclose(fp);
	mxFree(filename);
}



static void
        checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    mwSize n, p;

    /* Check for proper number of input and output arguments */
    if (nrhs != 3) {
        mexErrMsgIdAndTxt( "MATLAB:writematrix:invalidNumInputs",
                "Thress input arguments required.");
    }


}
