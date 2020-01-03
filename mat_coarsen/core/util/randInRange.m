function x = randInRange(a, b, varargin)
%RANDINRANGE Uniformly distributed pseudorandom numbers in [a, b].
%   This function returns A + (B-A)*RAND(OPTIONS) for all possible OPTIONS
%   passed to RAND. Note that A and B should match the size of the return
%   type of RAND, if you are interested in returning such sizes.
%
%   See also: RAND.

%==========================================================================

x = a + (b-a).*rand(varargin{:});
