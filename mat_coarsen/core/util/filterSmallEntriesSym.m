function A = filterSmallEntriesSym(A, b, delta, absFlag, boundType)
%FILTERSMALLENTRIES Filter small symmetric matrix entries.
%   C=FILTERSMALLENTRIESSYM(A,B,DELTA,ABSFLAG,BOUNDTYPE) removes the small
%   entries (I,J) of a real symmetric sparse matrix A in the returned
%   matrix C. Those are defined by
%
%   |A(I,J)| < DELTA * BOUND(I,J) if ABSFLAG='abs'
%    A(I,J)  < DELTA * BOUND(I,J) if ABSFLAG='value'
%
%   BOUND(I,J) = MAX(B(I),B(J))   if BOUNDTYPE='max'
%   BOUND(I,J) = MIN(B(I),B(J))   if BOUNDTYPE='min'
%
%   See also: SPARSE, DIAG, SPONES.

[i,j,a] = find(A);
if (strcmp(absFlag, 'abs'))
    B = abs(A);
else
    B = A;
end
M = diag(b)*spones(A);
if (strcmp(boundType, 'max'))
    M = max(M,M');
else
    M = min(M,M');
end

b = nonzeros(B);
m = nonzeros(M);
k = find(b >= delta*m);
A = sparse(i(k),j(k),a(k),size(A,1),size(A,2));

end
