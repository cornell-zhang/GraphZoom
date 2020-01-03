classdef Cycle < amg.api.IterativeMethod
    %CYCLE Multilevel cycle.
    %   This class implements is responsible for multilevel cycle control, i.e. the
    %   pattern in which levels in the setup hierarchy are visited. This
    %   class is designed for extension.
    %
    %   See also: SETUP.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.solve.Cycle')
    end
    
    %======================== MEMBERS =================================
%    properties (GetAccess = protected, Dependent)
    properties (GetAccess = protected, SetAccess = private)
        coarsest            % Coarsest level in the cycle
    end
    properties (GetAccess = protected, SetAccess = private)
        cycleIndex          % Cycle index
    end
    properties (GetAccess = protected, SetAccess = private)
        numLevels           % # cycle levels
        finest              % Finest level to run cycles on
%        numVisits           % Level visitation counters (numVisits(l) = # times level l was visited from the next-finer level)
%        coarsestDefault     % Coarsest level in the cycle (default value; potentially overridden by the processor)
    end
    properties (GetAccess = private, SetAccess = private)
        processor           % A function pointer that executes level processing
        coarsestOverride    % Cached field
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = Cycle(processor, cycleIndex, numLevels, finest)
            % Create an NUMLEVEL-level cycle at level FINEST with cycle
            % index CYCLEINDEX that executes the business logic of
            % PROCESSOR.
            obj.processor = processor;
            if (isscalar(cycleIndex) && ~isempty(numLevels))
                obj.cycleIndex  = repmat(cycleIndex, numLevels-1, 1);
            else
                obj.cycleIndex  = cycleIndex;
            end
            obj.numLevels       = numLevels;
            obj.finest          = finest;
%            obj.coarsestDefault = obj.finest + obj.numLevels - 1;
            obj.coarsest        = obj.getCoarsest(obj.finest + obj.numLevels - 1);
            obj.coarsestOverride = obj.processor.coarsest;
            if (isempty(obj.coarsestOverride))
                obj.coarsestOverride = -1; % Dummy value that cannot equal a real level
            end
        end
    end
    
    %======================== METHODS =================================
    methods
        function [x, r] = run(obj, x, r)
            % Execute a cycle at level FINEST.
            
            % Initialize state and level visitation counters l = current
            % level k = next level to visit
            L               = obj.coarsest;
            numVisits       = zeros(1,L-1);
            % Local field aliases, for speed in MATLAB
            p               = obj.processor;
            cOverride       = obj.coarsestOverride;
            f               = obj.finest;
            gam             = obj.cycleIndex;

            % Inject pre-cycle iterate
            l               = f;
            p.initialize(l, obj.numLevels, x, r);
            
            % Execute until we return to the finest level
            while (1)
                %k = obj.nextLevel(l); % Enapsulation slows us down!...
                % Compute the next level to process given the current level L
                % and the cycle visitation state (default
                % fractional-cycle-index algorithm). This hook can be
                % overridden by sub-classes.
                if (l == obj.coarsest)
                    % Coarsest level, go to next-finer level
                    k = l-1;
                else
                    if (l == f)
                        maxVisits = 1;
                    else
                        maxVisits = gam(l)*numVisits(l-1);
                    end
                    if (numVisits(l) < maxVisits)
                        k = l+1;
                    else
                        k = l-1;
                    end
                end
                %                 if (obj.logger.debugEnabled)
                %                     obj.logger.debug('Current level = %d, next level = %d\n', l, k);
                %                 end
                
                if ((l == cOverride) || (l == L))
                    % Coarsest level
                    p.coarsestProcess(l);
                end
                
                if (k < f)
                    break;
                elseif (k > l)
                    % since we've just started visiting level l, increment
                    % its counter
                    numVisits(l) = numVisits(l)+1;
                    % Go from level l to next-coarser level k
                    p.preProcess(l);
                else
                    % Go from level l to next-finer level k
                    p.postProcess(k);
                end
                % Update state
                l = k;
            end
            
            p.postCycle(obj.finest);
            
            % Retrieve post-cycle iterate
            [x, r] = p.result(obj.finest);
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function l = getCoarsest(obj, coarsestDefault)
            % Return the index of the coarsest level.
            if (obj.coarsestOverride > 0)
                l = obj.coarsestOverride;
            else
                l = coarsestDefault;
            end
        end
    end    
end