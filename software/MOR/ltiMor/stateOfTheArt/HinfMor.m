function [sysr, sysr0, Hinf] = HinfMor(sys, n, varargin) 
    % HINFMOR - H-infinity reduction by tangential interpolation
    % ------------------------------------------------------------------
    %
    % [sysr, Hinf] = HINFMOR(sys, varargin) 
    % Inputs:       * sys: full oder model (sss)
    %               * Opts (opt.) structure with execution parameters
    % Outputs:      * sysr: reduced order model (sss)
    %               * Hinf: H-infinity error (or indicator)
    % ------------------------------------------------------------------
    % USAGE:  
    %
    % See also IRKA
    %
    % ------------------------------------------------------------------
    % REFERENCES:
    % [1] Gugercin (2008), H2 model reduction for large-scale linear
    %     dynamical systems
    % [2] Flagg (2013), Interpolatory Hinf model reduction
    % [3] Beattie (2014), Model reduction by rational interpolation
    % ------------------------------------------------------------------
    % Authors:      Alessandro Castagnotto
    % Last Change:  10 Nov 2015
    % Copyright (c) ?
    % ------------------------------------------------------------------

    %%  Run IRKA
    if sys.isSiso
        % initialize
        try s0 = -eigs(sys,n,'sm').'; catch , s0 = zeros(1,n); end
        % run IRKA
        [sysr0, ~, ~, s0, ~, ~, ~, ~, Rt, ~, Lt] = irka(sys,s0);
    else %MIMO
        % initialize
        %   compute one step of tangential Krylov at 0 to get initial tangent 
        %   directions
        s0 = -eigs(sys,n,'sm').'; Rt = ones(sys.m,n); Lt = ones(sys.p,n);
        sysr = rk(sys,s0,s0,Rt,Lt);  [X,D,Y] = eig(sysr);
        Rt = full((Y.'*sysr.B).'); Lt = full(sysr.C*X); s0 = -diag(D).';
        %run IRKA
        [sysr0, ~, ~, s0, ~, ~, ~, ~, Rt, ~, Lt] = irka(sys,s0,Rt,Lt);
    end

    %   Transform (A- s0*E) to (s0*E- A)
    sysr0.C = -sysr0.C; sysr0.B = -sysr0.B;
    Rt = -Rt; Lt = -Lt;

    % % Check that the generalized tangential directions are correct
    % R = getSylvester(sys,sysr0,-V); L = getSylvester(sys,sysr0,-W,'W'); 
    % if norm(Rt-R)> 1e-5 || norm(Lt-L)> 1e-5
    %     warning('Residuals could be wrong')
    %     keyboard
    % end


    %%  Make Hinf correction
    %
    % steadyState: just take the current steady state error (can yield worse
    %               results)
    % steadyStateOpt: optimize over the difference in between the magnitude of
    %                 the steady state error and Dr
    % findGe0match: finds the feedthrough that best matches the steady-state
    %               error amplitude
    % normOpt:      Optimizes the actual inf norm of the error system!!
    % steadyState+normOpt: Initializes optimization at Ge(0)
    % DRange:       computes the actual error norm for a series of feedtrhoughs
    %               and takes the one with minimum value

    if nargin>2
        corrType = varargin{1};
    else
        corrType = 'normOpt';
    end

    %   Parametrize reduced order models by Dr
    sysrfun = @(Dr) sss(sysr0.A+Lt.'*Dr*Rt, sysr0.B+Lt.'*Dr, ...
                                     sysr0.C+Dr*Rt, Dr, sysr0.E);

    switch corrType
        case 'steadyState'
            warning(['This approach fails due to the same reasons stated for ',...
                'the forAll case']);
            %plus, Ge(0) changes depending on Dr

            Dr = freqresp(sys,0)-freqresp(sysr0,0);
            sysr = sysrfun(Dr);
        case 'steadyStateOpt'
            warning(['This approach fails due to the same reasons stated for ',...
                'the forAll case']);
            % however, is seems to work fine for build...

            G0 = freqresp(sys,0); %the only costly part
            Dr0 = G0-freqresp(sysr0,0);

            cost = @(Dr) abs(...
                        abs(G0-...
                        freqresp(sysrfun(Dr),0)) - abs(Dr));
            DrOpt = fmincon(cost,Dr0)
            sysr = sss(sysr0.A+Lt.'*DrOpt*Rt, sysr0.B-Lt.'*DrOpt, ...
                       sysr0.C-DrOpt*Rt, Dr0, sysr0.E);
        case 'findGe0match'
            warning(['This approach fails since there does not seem to be a ',...
                'reduced order model that yields a completely flat magnitude',...
                'response in the error']);

            G0 = freqresp(sys,0); %the only costly part

            Dr0 = G0 - freqresp(sysr0,0) %get an initial feedthrough
            deltaDr = 100*abs(Dr0), nStep = 5000; DrSet = []; dSet = [];
            syse0 = sys-sysr0;
            Hinf0 = norm(syse0,Inf); d0 = abs(Dr0); dMin = d0; %initial error
            drawnow
            for Dr = Dr0-deltaDr:(2*deltaDr)/nStep:Dr0+deltaDr;
                sysr = sysrfun(Dr);

                d = abs(abs(G0-freqresp(sysr,0)) - abs(Dr));
                if d < dMin
                    dMin = d;
                    dSet = [dSet, d];
                    DrSet = [DrSet,Dr];
    %                 syse = sys-sysr; sigma(syse,'Color',rand(1,3));
    %                 drawnow, keyboard
                end
            end
            %   best feedthrough in term of minimizing the error between the
            %   response at 0 and Inf
            Dr = DrSet(end), dMin
            sysr = sysrfun(Dr);
        case 'normOpt'
            Dr0 = zeros(sys.p,sys.m);
            sysr = normOpt(Dr0);
        case 'steadyState+normOpt'
            % execution params
            plotCostOverDr = 1;
            
            % initialization at steady-state error amplitude response
            G0 = freqresp(sys,0); Dr0 = G0-freqresp(sysr0,0);
            [sysr, DrOpt, Hinf] = normOpt(Dr0);

            %   See how the cost behaves around the chosen minimum?
            if plotCostOverDr
                nStep = 50; kRange = 10;
                DrRange = linspace(DrOpt*(1-kRange),DrOpt*(1+kRange), nStep); 
                plotOverDrRange(DrOpt,Hinf);
            end
        case 'DrRange'
            % Get steady state response of the error system
            G0 = freqresp(sys,0); 
            Dr0 = abs(G0 - freqresp(sysr0,0));

            % Define a range for the feedthrough
            nStep = 100;
            DrRange = linspace(-Dr0,Dr0, nStep); 

            % Run the actual function
            plotOverDrRange;
        otherwise
            error('Specified Hinf optimization type not valid');
    end

    %% 
    if nargout == 3
        Hinf = norm(sys-sysr,inf)/norm(sys,inf);
    end

    function [minDr, minVal] = plotOverDrRange(varargin)

            %initializing
            normVec = zeros(1,length(DrRange));
            normO = norm(ss(sys),inf); 
            normVec(1) = norm(ss(sys-sysr0),inf)/normO; 
            minVal = normVec(1); minDr = 0; DrRange = [0,DrRange];
            for iDr = 2:length(DrRange)
                sysrTest = sysrfun(DrRange(iDr));
                normVec(iDr) = norm(ss(sys-sysrTest),inf)/normO;
                if normVec(iDr) < minVal
                    minDr = DrRange(iDr); minVal = normVec(iDr);
                end
            end
            % sort Dr to be sure you cane use lines in plots
            [DrRange,idx] = sort(DrRange,'ascend'); normVec = normVec(idx);
            figure; plot(DrRange,normVec,'-b'); hold on; 
            plot(minDr,minVal,'*g');plot([DrRange(1),DrRange(end)],minVal*[1,1],'--g');
            titStr = sprintf('min in range=%4.3e',minDr);
            
            %optimizer passed to function
            if ~isempty(varargin) 
                plot(varargin{1},varargin{2}/normO,'or'); 
                plot([DrRange(1),DrRange(end)],varargin{2}/normO*[1,1],'--r');
                titStr = [titStr, sprintf(', min from opt=%4.3e',varargin{1})];
            end
            
            % labeling
            xlabel(titStr); ylabel('Relative Hinf error over Dr')
            title(sprintf('%s, n=%i',sys.Name,sysr.n),'Interpreter','none');
            
            % rescale y-axis (often you see high peaks)
            ylim(minVal*[.25,4]);
                
            drawnow
            
            if 1 %saving
                cdir = pwd;
                cd('..\res')
                saveas(gcf,sprintf('ErrorOverDr_%s_n%i',sys.Name,sysr.n));
                cd(cdir);
            end
    end

    function [sysr, DrOpt, Hinf] = normOpt(Dr0)
        
            cost = @(Dr) norm(sys-sysrfun(Dr),Inf);
            solver = 'fminsearch';
            warning('optimizing over the actual error norm');
            warning off
            switch solver
                case 'fminsearch'
                %zero initialization
                tic, [DrOpt, Hinf] = fminsearch(cost,Dr0), tOpt = toc

                case 'ga'
                    options = gaoptimset('Display','iter','TimeLimit',5*60,...
                        'UseParallel',true, 'PopInitRange',[-1;1]);
                    tic, [DrOpt, Hinf] = ga(cost,1,[],[],[],[],[],[],[],options); tOpt = toc
            end
            warning on
            sysr = sysrfun(DrOpt); 
    end

end



