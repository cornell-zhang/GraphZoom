%FILTERSMALLENTRIES Filter small symmetric matrix entries.
%   C=FILTERSMALLENTRIES(A,B,DELTA,ABSFLAG,BOUNDTYPE) removes the small
%   entries (I,J) of a real sparse matrix A in the returned matrix C. Those
%   are defined by
%
%   |A(I,J)| < DELTA * BOUND(I,J) if ABSFLAG='abs'
%    A(I,J)  < DELTA * BOUND(I,J) if ABSFLAG='value'
%
%   BOUND(I,J) = MAX(B(I),B(J))   if BOUNDTYPE='max'
%   BOUND(I,J) = MIN(B(I),B(J))   if BOUNDTYPE='min'
%
%   See also: SPARSE, DIAG, SPONES.
