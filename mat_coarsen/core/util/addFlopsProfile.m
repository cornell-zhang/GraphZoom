function addFlopsProfile(logger, message, fl)
% ADDFLOPSPROFILE   Increment the global flopcount variable (profiling
% version). ADDFLOPS(fl) is equivalent to FLOPS(FLOPS+FL), but more
% efficient.

addflops(fl);

% Using hard-coded logging flag because it is very slow to repetitively call
% flopsLogger.infoEnabled, as profiling reveals
%flopsLogger = core.logging.Logger.getInstance('flops');
%if (flopsLogger.infoEnabled)

if (0)
    logger.info('%-30s flops=%6d\n', message, fl);
end
