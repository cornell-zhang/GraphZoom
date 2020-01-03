function alpha = connectionStrength(C)
%CONNECTIONSTRENGTH Algebraic connection strength.
%   ALPHA=CONNECTIONSTRENGTH(C) returns the matrix of ALPHA factors that
%   determine whether a connection is strong or not. Namely,
%   ALPHA(I,J)=C(I,J)/SQRT(C(I,I)*C(J,J)).
%
%   See also: CONNECTIONESTIMATOR.

D       = diag(diag(C).^(-0.5));
alpha   = D*C*D;

end
