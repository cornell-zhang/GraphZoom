function b = poissonNoise(a)
%POISSONNOISE Add a Poisson noise to a tensor.
%   B = POISSONNOISE(A) adds Poisson noise to each entry of the tensor A. A
%   may be a vector, matrix or a tensor of any dimension. (The size of B
%   equals the size of A.)
%
%   See also RAND.

%==========================================================================

clear varargin;
sizeA = size(a);

a = a(:);

%  (Monte-Carlo Rejection Method) Ref. Numerical Recipes in C, 2nd Edition,
%  Press, Teukolsky, Vetterling, Flannery (Cambridge Press)

b=zeros(size(a));
idx1=find(a<50); % Cases where pixel intensities are less than 50 units
if (~isempty(idx1))
    g=exp(-a(idx1));
    em=-ones(size(g));
    t=ones(size(g));
    idx2=[1:length(idx1)]';
    while ~isempty(idx2)
        em(idx2)=em(idx2)+1;
        t(idx2)=t(idx2).*rand(size(idx2));
        idx2=idx2(find(t(idx2)>g(idx2)));
    end
    b(idx1)=em;
end

% For large pixel intensities the Poisson pdf becomes very similar to a
% Gaussian pdf of mean and of variance equal to the local pixel
% intensities. Ref. Mathematical Methods of Physics, 2nd Edition, Mathews,
% Walker (Addison Wesley)
idx1=find(a>=50); % Cases where pixel intensities are more than 49 units
if (~isempty(idx1))
    b(idx1)=round(a(idx1)+sqrt(a(idx1)).*randn(size(idx1)));
end

b = reshape(b,sizeA);
