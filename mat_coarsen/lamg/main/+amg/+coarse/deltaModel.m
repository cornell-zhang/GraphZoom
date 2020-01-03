function delta = deltaModel(stage, options)
%DELTAMODEL Approximate affinity model.
%   DELTA=DELTAMODEL(R,RCRITICAL) returns the affinity model as a Gaussian
%   function of aggregate size with decay coefficient(= standard deviation)
%   RCRITICAL.
%
%   See also:
%   http://bamg.pbworks.com/w/page/34608186/Aggregation-Algorithm#view=edit

%delta = exp(-((stage*options.deltaDecrement)/options.deltaInitial).^2);
if (stage > 3)
    error('Up to 3 aggregation sweeps are supported by this strategy');
elseif (stage == 3)
    % Remove threshold altogether - consider all connections of each node
    delta = 0.0;
else
    % Gradually decrease delta in the first couple of stages, allowing
    % stronger connections to be aggregated before weaker
    delta = options.deltaInitial * options.deltaDecrement.^(stage-1);
end

end
