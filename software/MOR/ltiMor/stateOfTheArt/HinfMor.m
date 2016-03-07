function [sysr, HinfRel, sysr0, HinfRatio, tOpt, bound, sysm, Virka, Rt] = HinfMor(sys, n, varargin) 
    % HINFMOR - H-infinity reduction by tangential interpolation
    % ------------------------------------------------------------------
    % TODO
    % sysr = HINFMOR(sys, varargin) 
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
    % Last Change:  23 Nov 2015
    % Copyright (c) ?
    % ------------------------------------------------------------------
   
    %%  Input parsing and execution parameters
    if ~isempty(varargin) 
        if isstruct(varargin{1}) %Opts passsed
            Opts = varargin{1};
        else %Opts.corrType passed
            Opts.corrType = varargin{1};        
        end
    else
        Opts = struct();
    end
    
    Def.plotCostOverDr = 0;
    Def.irka        = struct('stopCrit','combAny','tol',1e-6); %run irka with defaul parameters
    Def.corrType    = 'normOptCycle';
    Def.solver      = 'fmincon'; %optimization solver
    Def.DrInit      = '0'; %0, '0', Ge0, matchGe0, maxGe
    Def.plot        = 0; % generate analysis plot
    Def.sampling    = 'random'; %sampling for sweepDr
    Def.sweepPoints = 2e3;
    
    Def.surrogate   = 'original';   %original, 'model', 'vf', 'loewner'
    Def.whatData    = 'new';        %'all','new'
    Def.deflate     = 1;
    Def.tol         = 1e-6;
    
    Def.vf.poles   = 'vectfit3'; %vectfit,eigs
    Def.vf.maxiter = 20;
    Def.vf.tol     = 1e-10;
    
    % create the options structure
    if ~exist('Opts','var') || isempty(Opts)
        Opts = Def;
    else
        Opts = parseOpts(Opts,Def);
    end
    
    %%  Run IRKA
    if sys.isSiso
        % initialize
        try s0 = -eigs(sys,n,'sm').'; catch , s0 = zeros(1,n); end
%         s0 = zeros(1,n);
        % run IRKA
        [sysr0, Virka, ~, ~, ~, ~, ~, Rt, ~, Lt,s0Traj,RtTraj, LtTraj] = irka(sys,s0,Opts.irka);
    else %MIMO
        % initialize
        %   compute one step of tangential Krylov at 0 to get initial tangent 
        %   directions
        
%         s0 = zeros(1,n); Rt = ones(sys.m,n); Lt = ones(sys.p,n);
        s0 = -eigs(sys,n,'sm').'; Rt = ones(sys.m,n); Lt = ones(sys.p,n);
        sysr = rk(sys,s0,s0,Rt,Lt);  [X,D,Y] = eig(sysr);
        Rt = full((Y.'*sysr.B).'); Lt = full(sysr.C*X); s0 = -diag(D).';
        %run IRKA
        [sysr0, Virka, ~, ~, ~, ~, ~, Rt, ~, Lt, s0Traj, RtTraj, LtTraj] = irka(sys,s0,Rt,Lt,Opts.irka);
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
    
    %%  Create Surrogate Model
    %   To reduce the cost of Hinf optimization, create a surrogate model
    %   from the data collected during irka
    
    sysm = createSurrogate;
    fprintf('Size of the surrogate model: %i \n',sysm.n)
    isstable(sysm)
%     figure; bode(sys,'b',sysr0,'--g',sysm,'--r'); keyboard

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

    switch Opts.corrType
        case 'steadyState'
            warning('this option is obsolete and shows bad performance');
            %plus, Ge(0) changes depending on Dr

            DrOpt = DrInit('Ge0');
            sysr = sysrfun(DrOpt);
        case 'steadyStateOpt'
            warning('this option is obsolete and shows bad performance');
            % however, is seems to work fine for build...

            G0 = freqresp(sysm,0); %the only costly part
            Dr0 = G0-freqresp(sysr0,0);

            cost = @(Dr) abs(...
                        abs(G0-...
                        freqresp(sysrfun(Dr),0)) - abs(Dr));
            DrOpt = fmincon(cost,Dr0);
            sysr = sss(sysr0.A+Lt.'*DrOpt*Rt, sysr0.B-Lt.'*DrOpt, ...
                       sysr0.C-DrOpt*Rt, Dr0, sysr0.E);
        case 'findGe0match'
            warning('this option is obsolete and shows bad performance');

            DrOpt = DrInit('matchGe0');
            sysr = sysrfun(Dr);
        case 'normOpt_siso'
            warning('this option is obsolete and shows bad performance');
             % running optimization wr to each entry of D individually
            % the cost function takes into account only the SISO tf
            DrOpt = zeros(sys.p,sys.m); tOpt = 0;
            for iOut = 1:sys.p
                for jIn = 1:sys.m
                    Dr0 = 0; 
                    sysrCurr = @(Dr) sss(....
                                    sysr0.A+Lt(iOut,:)'*Dr*Rt(jIn,:),...
                                    sysr0.B(:,jIn)+Lt(iOut,:).'*Dr, ...
                                    sysr0.C(iOut,:)+Dr*Rt(jIn,:), Dr, sysr0.E);
                    cost = @(Dr) norm(sysm(iOut,jIn)-sysrCurr(Dr),Inf);
                    [DrOptCurr, ~, tOptCurr] = normOpt(Dr0,cost);
                    tOpt = tOpt + tOptCurr;
                    DrOpt(iOut,jIn) = DrOptCurr;
                end
            end
            sysr = sysrfun(DrOpt);
        case 'DrRange'
            % Get steady state response of the error system
            Dr0 = DrInit('Ge0');

            % Define a range for the feedthrough
            nStep = 100;
            DrRange = linspace(-Dr0,Dr0, nStep); 

            % Run the actual function
            plotOverDrRange;
        case 'normOpt'
            Dr0 = DrInit(Opts.DrInit);
            cost = @(Dr) norm(sysm-sysrfun(Dr),Inf);
            [DrOpt, Hinf,tOpt] = normOpt(Dr0,cost);
            sysr = sysrfun(DrOpt);         
        case 'normOptCycle'
            % running optimization wr to each entry of D individually
            % the cost function takes into account the whole MIMO system
            DrOpt = DrInit(Opts.DrInit); HinfVec = norm(sysm-sysr0,Inf); tOpt = 0;
            nCycles = 3; cycleCount = 0; stop = 0; %max number of cycles defined
            while cycleCount < nCycles && ~stop;
            cycleCount = cycleCount+1;
            for iOut = 1:sys.p
                for jIn = 1:sys.m
                    Dr0 = DrOpt(iOut,jIn);
                    cost = @(Dr) norm(sysm-sysrfun(Dr,iOut,jIn,DrOpt),Inf);
                    [DrOptCurr, Hinf,tOptCurr] = normOpt(Dr0,cost);
                    tOpt = tOpt+tOptCurr;
                    DrOpt(iOut,jIn) = DrOptCurr;
                    HinfVec = [HinfVec, Hinf];
                    if length(HinfVec) > sys.p*sys.m +1 %cycled already once
                        crit = mean(abs(diff(HinfVec(end-2:end))./HinfVec(end-2:end-1)));
                        %mean improvement less that 1%
                        if crit < 1e-2; stop = 1; break, end
                    end
                end
                if stop, break, end %breaking out of nested for loop
            end
            end
            sysr = sysrfun(DrOpt); 
            if Opts.plot
                figure; plot(0:1:length(HinfVec)-1,HinfVec/HinfVec(1)); 
                ylabel('relative error decrease');
            end            
        case 'normOptCycleCombo'
            % running optimization wr to each entry of D individually
            % the cost function takes into account the whole MIMO system
            % after one cycle is run, we use the result to initialize a
            % multivariate optimization
            
            % 1) cycle optimization
            Opts.solver = 'fmincon';
            DrOpt = DrInit(Opts.DrInit); HinfVec = norm(ss(sysm-sysr0),Inf); tOpt = 0;
            for iOut = 1:sys.p
                for jIn = 1:sys.m
                    Dr0 = DrOpt(iOut,jIn);
                    cost = @(Dr) norm(ss(sysm-sysrfun(Dr,iOut,jIn,DrOpt)),Inf);
                    constr = @(Dr) stabilityConstraintCycle(Dr,iOut,jIn,DrOpt);
                    [DrOptCurr, ~,tOptCurr] = normOpt(Dr0,cost,constr);
                    tOpt = tOpt+tOptCurr;
                    DrOpt(iOut,jIn) = DrOptCurr;
                end
            end
            
            % 2) multivariate optimization
            cost = @(Dr) norm(ss(sysm-sysrfun(Dr)),Inf);
            [DrOpt, Hinf,tOptCurr] = normOpt(DrOpt,cost);
            tOpt = tOpt + tOptCurr;
            
            sysr = sysrfun(DrOpt); 
        case 'sweepDr'
            cost = @(Dr) norm(ss(sysm-sysrfun(Dr)),Inf);
            [DrOpt, tOpt, DrArray,costArray] = sweepDr(cost);
            assignin('caller','DrArray',DrArray);
            assignin('caller','costArray',costArray);
            sysr = sysrfun(DrOpt); 
        otherwise
            error('Specified Hinf optimization type not valid');
    end
    
    %   See how the cost behaves around the chosen minimum?
    if Opts.plotCostOverDr
        nStep = 20; kRange = 6;
        if isscalar(DrOpt) %SISO
            DrRange = linspace(DrOpt*(1-kRange),DrOpt*(1+kRange), nStep); 
        elseif any (size(DrOpt) == 1) % SIMO or MISO
            DrRange = cell(size(DrOpt)); %get the right size
            DrRange1 = linspace(DrOpt(1)*(1-kRange),DrOpt(1)*(1+kRange), nStep);
            DrRange2 = linspace(DrOpt(2)*(1-kRange),DrOpt(2)*(1+kRange), nStep);
            [DrRange1, DrRange2] = meshgrid(DrRange1,DrRange2);
            DrRange{1} = DrRange1; DrRange{2} = DrRange2;
        end
        plotOverDrRange(DrOpt,Hinf);
    end

    %% Additional outputs
    if nargout > 1
        % Error indicators
%         if ~exist('Hinf','var')
%             Hinf = norm(sysm-sysr,inf);%optimized
%         end
%         HinfO = norm(sysm,inf); %original
%         HinfRel = Hinf/HinfO;
%         HinfRatio = Hinf/norm(sysm-sysr0,inf); %ratio to irka ROM

        % Real error
        Hinf = norm(ss(sys-sysr),inf);%optimized
        HinfO = norm(ss(sys),inf); %original
        HinfRel = Hinf/HinfO;
        HinfRatio = Hinf/norm(ss(sys-sysr0),inf); %ratio to irka ROM
        
        if nargout > 5
%             bound = HinfBound(sys,B_,C_);
            bound  =[];
        end
    end

    %% ======= Auxiliary ========
    function Dr0 = DrInit(type)
        %   Initialize Dr for optimization
        switch type
            case '0'
                Dr0 = zeros(sys.p,sys.m);
            case 0
                Dr0 = DrInit('0');    
                type = '0'; %overwrite for stability check at the end
            case 'Ge0'   
                Dr0 = freqresp(sysm,0)-freqresp(sysr0,0);      
            case 'Ge0half'
                Dr0 = DrInit('Ge0')/2;
            case 'matchGe0_old'        
                % this computation does not work well for MIMO systems
                % since is sweeping Dr0 only along a hyperline with
                % direction of the absolute value of Dr0
                G0 = freqresp(sysm,0); %the only costly part

                Dr0 = DrInit('Ge0'); %get an initial feedthrough
                deltaDr = 20*abs(Dr0); nStep = 100; 
                DrSet(:,:,1) = DrInit('0'); dSet(:,:,1) = Dr0; dMin = norm(Dr0); %initial error
                if Opts.plot, figure; sigma(sysm-sysr0,'b', 'LineWidth',2); end
                
                for k = 0:nStep
                    Dr = Dr0-deltaDr + k*(2*deltaDr)/nStep;
                    sysr = sysrfun(Dr);

%                     d = abs(abs(G0-freqresp(sysr,0)) - abs(Dr));
                      d = norm(G0 - (freqresp(sysr,0) + Dr));
                    if d < dMin && isstable(sysr)
                        dMin = d;
                        dSet(:,:,end+1) = d;
                        DrSet(:,:,end+1)= Dr;
                        if Opts.plot
                            syse = sysm-sysr; sigma(syse,'Color',rand(1,3)); 
                            drawnow
                        end
                    end
                end
                %   best feedthrough in term of minimizing the error between the
                %   response at 0 and Inf
                Dr0 = DrSet(:,:,end); 
                if Opts.plot 
                    syse = sysm-sysrfun(Dr0); sigma(syse,'Color',rand(1,3),...
                                                   'LineWidth',2); 
                    drawnow 
                end
            case 'matchGe0'      
                %   Run a sweep in an sys.m x sys.p dimensinal space
                %   The claim is that all computations are cheap since we
                %   compute G0 once.
                
                G0 = freqresp(sysm,0); %the only costly part
                sweepcost = @(Dr0) norm(G0 - (freqresp(sysrfun(Dr0),0) + Dr0));
                
                Dr0 = sweepDr(sweepcost);
            case 'maxGe'
                % finde the frequency w at which the maximum singular value
                % of the transfer function matrix is obtained. Conduct a
                % sweep to minimize the error at w
                
                %expensive computations
                [~, w] = norm(ss(sysm-sysr0),inf);
                Gew = freqresp(sysm,w);
                
                sweepcost = @(Dr0) norm(Gew - freqresp(sysrfun(Dr0),w));
                
                Dr0 = sweepDr(sweepcost);              
            otherwise
                error('Initialization option for Dr not valid');
        end
        % make sure the initialization yields a stable system 
        %(if not 0 and if not called by DrInit itself)
        caller = dbstack;
        if ~strcmp(caller(2).name,'HinfMor/DrInit')&& ~strcmp(type,'0') &&...
                ~isstable(sysrfun(Dr0))
            warning('Selected initialization for Dr0 would have yielded an unstable system. Changing it to 0');
            Dr0 = DrInit('0');
        end
    end
    function [DrOpt, tOpt, DrArray, costArray] = sweepDr(sweepcost)
        % This is used in parallel (parfor) 
        
        %   Determine the relevant frequency range for Dr based on the Hinf
        %   error after IRKA
        [~,wmax] = norm(ss(sysm),inf); deltaDr = freqresp(sysm-sysr0,wmax);
        
        probSize = sys.m*sys.p; %dimension of the search space

        %CURSE of DIMENSIONALITY!!
        nPointsMax = Opts.sweepPoints;
        nStep = floor(nthroot(nPointsMax,probSize));
        if mod(nStep,2) == 0
          %number is even
          nStep = nStep-1;
        end 
        % take at least two points
        nStep = max([nStep,2]);

        % Create the grid
        x = {}; sampling = 'random';
        for iOut = 1:sys.p
            for jIn = 1:sys.m
                switch sampling
                    case 'grid'
                        x = [x, ...
                        {linspace(-deltaDr(iOut,jIn),deltaDr(iOut,jIn),nStep).'}];
                    case 'random'
                        x = [x, ...
                        {randn(nStep,1)*3*deltaDr(iOut,jIn)}];
                end
            end
        end
        Xl = cell(1,probSize); [Xl{:}] = ndgrid(x{:});   
        
        % Run the sweep
        nPoints = nStep^probSize;     
        DrArray = zeros(sys.p,sys.m,nPoints); 
        costArray = zeros(1,1,nPoints);  
        p = sys.p; m = sys.m;
        tic
        parfor k=1:nPoints  
            Dr0l = zeros(p,m);
            %   generate the current feedthrough
            for iEl = 1:probSize, Dr0l(iEl) = Xl{iEl}(k); end
            DrArray(:,:,k)= Dr0l;
            costArray(:,:,k) = sweepcost(Dr0l);
        end    
        tOpt = toc;
        [~, idxMin] = min(squeeze(costArray));
        DrOpt = DrArray(:,:,idxMin);    
    end
    function [DrOpt, Hinf,tOpt] = normOpt(Dr0,cost,constr)       

            switch Opts.solver
                case 'fminsearch'
                tic, [DrOpt, Hinf] = fminsearch(cost,Dr0); tOpt = toc;
                
                case 'fminunc'
                optOpts = optimoptions(@fminunc, 'algorithm','quasi-newton');
                tic, [DrOpt, Hinf] = fminunc(cost,Dr0,optOpts); tOpt = toc;
                
                case 'fmincon'
                optOpts = optimoptions('fmincon','UseParallel',1,...
                                        'algorithm','sqp');
                if ~exist('constr','var')
                    constr = @stabilityConstraint;
                end
                tic, [DrOpt, Hinf] = fmincon(cost,Dr0,[],[],[],...
                    [],[],[],constr,optOpts); tOpt = toc;
               
                case 'gs'
                    
                % Restrict the search space to improve execution
                [lb,ub] = searchSpaceLimits(sysm-sysr0);    
                
                % Define optimization parameters
                optOpts = optimoptions('fmincon','UseParallel',1,...
                                        'algorithm','sqp');
                problem = createOptimProblem('fmincon',...
                            'objective',cost,'x0',Dr0,'options',optOpts,...
                            'nonlcon',@stabilityConstraint,...
                            'lb',lb,'ub',ub);
                gs = GlobalSearch('NumStageOnePoints',20,...%start points
                                  'NumTrialPoints',400,... %set of all potential start points
                                  'StartPointsToRun','bounds-ineqs',...%exclude certain points?
                                  'Display','iter',...
                                  'MaxTime',300); %stop after 5 min
                                 
                tic,  [DrOpt,Hinf] = run(gs,problem); tOpt = toc;
                              
                case 'ms'
                optOpts = optimoptions('fminunc', 'algorithm','quasi-newton');
                problem = createOptimProblem('fminunc',....
                            'objective',cost, 'x0',Dr0,'options',optOpts);
                ms = MultiStart('UseParallel',true);
                tic, [DrOpt,Hinf,~,~,allmins] = run(ms,problem,25); tOpt = toc;
                
                %   Get the best stable result
                k = 1; nOpt = length(allmins);
                while ~isstable(sysrfun(DrOpt))
                    k = k+1;
                    DrOpt = allmins(k).X;
                    Hinf  = allmins(k).Fval;
                    if k >= nOpt
                        warning('none of the local optima from MS was stable')
                        DrOpt = allmins(k).X;
                        Hinf  = allmins(k).Fval;
                        break
                    end
                end
                
                case 'ga'
                    options = gaoptimset('UseParallel',true,...
                                         'PopulationSize',25,...
                                         'Generations',20,...
                                         'InitialPopulation',Dr0(:).',...
                                         'Display','iter');
                    
                    hybridoptions = optimoptions('fmincon','UseParallel',1,...
                                    'Display','iter','algorithm','sqp');
                    options = gaoptimset(options,...
                    'HybridFcn',{@fmincon, hybridoptions});

                    gacost = @(x) cost(reshape(x,size(Dr0,1),size(Dr0,2)));

                    tic, [xOpt, Hinf] = ga(gacost,numel(Dr0),[],[],[],[],...
                            [],[],@stabilityConstraintGA,options); tOpt = toc;
                    DrOpt = reshape(xOpt,size(Dr0,1),size(Dr0,2));
            end
    end
    function sysr = sysrfun(Dr,iOut,jIn,DrMIMO)
        if nargin == 1
            %Dr is the full feedthrough
            DrMIMO = Dr;
        else
            DrMIMO(iOut,jIn) = Dr;
        end
        sysr= sss(sysr0.A+Lt.'*DrMIMO*Rt, sysr0.B+Lt.'*DrMIMO, ...
                                     sysr0.C+DrMIMO*Rt, DrMIMO, sysr0.E);
    end
    function [minDr, minVal] = plotOverDrRange(varargin)
        if isnumeric(DrRange) %vector of Dr values
            %initializing
            normVec = zeros(1,length(DrRange));
            normO = norm(ss(sysm),inf); 
            normVec(1) = norm(ss(sysm-sysr0),inf)/normO; 
            minVal = normVec(1); minDr = 0; DrRange = [0,DrRange];
            for iDr = 2:length(DrRange)
                sysrTest = sysrfun(DrRange(iDr));
                normVec(iDr) = norm(ss(sysm-sysrTest),inf)/normO;
                if normVec(iDr) < minVal
                    minDr = DrRange(iDr); minVal = normVec(iDr);
                end
            end
            % sort Dr to be sure you cane use lines in plots
            [DrRange,idx] = sort(DrRange,'ascend'); normVec = normVec(idx);
            figure; h(1) = plot(DrRange,normVec,'-b'); hold on; 
            h(2) = plot(minDr,minVal,'*g');plot([DrRange(1),DrRange(end)],minVal*[1,1],'--g');
            legNames = {'Error', 'Min on plot'};
            %optimizer passed to function
            if ~isempty(varargin) 
                h(3) = plot(varargin{1},varargin{2}/normO,'or'); 
                plot([DrRange(1),DrRange(end)],varargin{2}/normO*[1,1],'--r');
                legNames = [legNames, {'Min from optimization'}];
            end
            
            % Add zero and Dr0 to the plot
            currDr = 0; currVal = norm(ss(sysm-sysrfun(currDr)),inf)/normO;
            h(4) = plot(currDr, currVal,'ok');          
            currDr = freqresp(sysm-sysrfun(0),0); currVal = norm(ss(sysm-sysrfun(currDr)),inf)/normO;
            h(5) = plot(currDr,currVal,'sm');
            legNames = [legNames, {'val@0','Ge0(0)'}];
            
            % labeling
            xlabel('Dr'); ylabel('Relative Hinf error over Dr')
            title(sprintf('%s, n=%i',sys.Name,sysr.n),'Interpreter','none');
            
            % rescale y-axis (often you see high peaks)
            ylim(minVal*[.25,4]);
            
            legend(h,legNames,'Location','SouthOutside');
        else % Dr is a grid (MISO or SIMO)
            currDr = zeros(size(DrRange)); %get the right shape
            minDr = zeros(size(DrRange));
            
            Dr1Range = DrRange{1}; Dr2Range = DrRange{2};
            normMat = zeros(size(Dr1Range));
            normO = norm(ss(sysm),inf); 
            % in this case, we don't add 0 as a value to the grid
            minVal = Inf;
            for iDr = 1:size(Dr1Range,1)
                for jDr = 1:size(Dr1Range,2)
                    currDr(1) = Dr1Range(iDr,jDr);
                    currDr(2) = Dr2Range(iDr,jDr);
                    sysrTest = sysrfun(currDr);
                    normMat(iDr,jDr) = norm(ss(sysm-sysrTest),inf)/normO;
                    if normMat(iDr,jDr) < minVal
                        minDr(1) = Dr1Range(iDr,jDr);
                        minDr(2) = Dr2Range(iDr,jDr);
                        minVal = normMat(iDr,jDr);
                    end
                end
            end
            
            figure; h(1) = surf(Dr1Range,Dr2Range,normMat); hold on; 
            h(2) = plot3(minDr(1),minDr(2),minVal,'pg','MarkerFaceColor','g');
            plot3(Dr1Range,Dr2Range,minVal*ones(size(Dr1Range)),'--g');
            legNames = {'Error surface', 'Min on surface'};
            %optimizer passed to function
            if ~isempty(varargin) 
                DrOpti = varargin{1}; optimVal = varargin{2}/normO;
                h(3) = plot3(DrOpti(1),DrOpti(2),optimVal,'or','MarkerFaceColor','r'); 
                plot3(Dr1Range,Dr2Range,optimVal*ones(size(Dr1Range)),'--r');
                legNames = [legNames, {'Min from optimization'}];
            end
            
            % Add zero and Dr0 to the plot
            currDr = zeros(size(currDr)); currVal = norm(ss(sysm-sysrfun(currDr)),inf)/normO;
            h(4) = plot3(currDr(1),currDr(2),currVal,'ok','MarkerFaceColor','k');            
            currDr = abs(freqresp(sysm,0) - freqresp(sysr0,0));
            currVal = norm(ss(sysm-sysrfun(currDr)),inf)/normO;
            h(5) = plot3(currDr(1),currDr(2),currVal,'sm','MarkerFaceColor','m');
            legNames = [legNames, {'val@0','Ge0(0)'}];
            
            % labeling
            xlabel('Dr'); zlabel('Relative Hinf error over Dr')
            title(sprintf('%s, n=%i',sys.Name,sysr.n),'Interpreter','none');
            
            % rescale y-axis (often you see high peaks)
            ZLims = minVal*[.25,4];
            zlim(ZLims);
            caxis(ZLims)
            
            % legend
            legend(h,legNames,'Location','SouthOutside')
        end
                
            drawnow
            
            if 1 %saving
                cdir = pwd;
                cd('..\res')
                sysSaveNm = sys.Name;
                k = strfind(sysSaveNm,':');
                if ~isempty(k)
                    if strcmp(sysSaveNm(k-1),'_')
                        sysSaveNm = strrep(sysSaveNm,':','simo');
                    else
                        sysSaveNm = strrep(sysSaveNm,':','miso');
                    end
                end
                saveas(gcf,sprintf('ErrorOverDr_%s_n%i',sysSaveNm,sysr.n));
                cd(cdir);
            end
    end
    function [c,ceq]=stabilityConstraint(x)
        % define a nonlinear constraint to impose stability
        ceq = 1-isstable(ss(sysrfun(x)));
        c = [];
    end
    function [c,ceq]=stabilityConstraintGA(x)
        % define a nonlinear constraint to impose stability
        [c,ceq]=stabilityConstraint(reshape(x,size(Dr0,1),size(Dr0,2)));
    end
    function [c,ceq]= stabilityConstraintCycle(Dr,iOut,jIn,DrOpt)
        ceq = 1-isstable(ss(sysrfun(Dr,iOut,jIn,DrOpt)));
        c = [];
    end
    function [lb,ub] = searchSpaceLimits(syse)
        %syse: error system
        %[lb,ub] matrix values lower and upper bounds on Dr
        
        fac = 5; %scaling/robustness factor
        %initialize
        
        p = syse.p; m = syse.m;
        lb = zeros(p,m); ub = zeros(p,m);
        
        % define values
        for iO = 1:p
            parfor jI = 1:m
                val = norm(syse(iO,jI),inf);
                lb(iO,jI) = -fac*val; ub(iO,jI) = fac*val;
            end
        end
        
    end
    function sysm = createSurrogate
        switch Opts.surrogate
            case 'original'
                sysm = sys;
            case 'model'
                [s0m,Rtm,Ltm] = getModelData(s0Traj,RtTraj,LtTraj);
                arnoldiOpts.makeOrth = 0;
                [~,V,W] = rk(sys,s0m,s0m,Rtm,Ltm,arnoldiOpts);
                
                sysm = sss(W'*sys.A*V, W'*sys.B, sys.C*V,sys.D,W'*sys.E*V);               
            case 'vf'  
                [s0m] = getModelData(s0Traj,RtTraj,LtTraj);
                % take only one complex conjugate partner
                s0m = cplxpair(s0m); idx = find(imag(s0m)); s0m(idx(1:2:end)) = [];
                figure('Name','Sampling frequencies for VF'); 
                plot(s0m,'o');xlabel('real');ylabel('imag')
                
                % generate frequency sample
%                 fss = freqresp(sys,s0m); fss = reshape(fss,numel(fss(:,:,1)),length(fss));
                f = freqresp(sys,s0m); f = reshape(f,numel(f(:,:,1)),length(f));
                           
                nm = min([round(length(s0m)),60]);  %model function order
                
                m = sys.m; p = sys.p;
                if m>1, nm = round(nm/m);end %avoid blowing-up for MIMO
                if mod(nm,2) ~= 0, nm = nm-1; end   %make even
                
%                 figure; loglog(abs(imag(s0m)),abs(f),'bx'); hold on
%                         loglog(abs(imag(s0m)),abs(fss),'or');
                         
                poles = initializePoles(Opts.vf.poles,nm);
%                 poles = -logspace(-2,2,nm);
                          
                %MIMO systems have to be fitted columnwise
                AA = []; BB = []; CC = []; DD = [];
                weight=ones(p,size(f,2));
                for iCol = 1:m
                    fm = f((iCol-1)*p+1 : iCol*p,:);
                for iter = 1:Opts.vf.maxiter
                    [SER,poles,rmserr] =vectfit3(fm,s0m,poles,weight);
                    fprintf(1,'VF iteration %i, error %e \n',iter,rmserr);
                    if rmserr <= Opts.vf.tol, break, end
                end
                    AA = blkdiag(AA,SER.A); 
                    BB = blkdiag(BB,SER.B);
                    CC = [CC, SER.C];
                    DD = [DD, SER.D];
                end
                
                sysm = sss(AA,BB,CC,DD);
%                 isstable(sysm)
                figure('Name','Original Vs surrogate models');
                bode(ss(sys),'b-',ss(sysm),'--r'); keyboard;            
            case 'loewner'
                %   Get the data
                [s0m,Rtm,Ltm] = getModelData(s0Traj,RtTraj,LtTraj);
                [~,V,W] = rk(sys,s0m,s0m,Rtm,Ltm);
                % note that V,W are orthogonal and real, so there is no
                % need to postprocess the Loewner matrices
                
                %   Create Loewner matrices
                L   = - W'*sys.E*V; %Loewner matrix
                sL  = - W'*sys.A*V; %shifted Loewner matrix

                %   Deflate
                r = rank([L, sL],Opts.rankTol);
                if r == rank([L; sL],Opts.rankTol)
                    for iS = 1:length(s0m)
                        if rank(s0m(iS)*L-sL,Opts.rankTol) == r
                            break
                        end
                    end
                else
                    warning('Loewner conditions not satisfied');
                    sysm = sysr0; return
                end
                [Ws, ~, Vs] = svd(s0m(iS)*L-sL,'econ');
                V= V*Vs(:,1:r); W= W*Ws(:,1:r);
                
                %   Build the model function
                sysm = sss(W'*sys.A*V, W'*sys.B, sys.C*V,sys.D,W'*sys.E*V);
        end
    end
    function [s0m,Rtm,Ltm] = getModelData(s0Traj,RtTraj,LtTraj)
        % get interpolation data out of the trajectories
        kIrka = size(s0Traj,3); nRed = size(s0Traj,2);
        % initialize
        s0m = s0Traj(:,:,1); Rtm = RtTraj(:,:,1); Ltm = LtTraj(:,:,1);
        for iStep = 2:kIrka
            s0new = s0Traj(:,:,iStep);
            Rtnew = RtTraj(:,:,iStep); Ltnew = LtTraj(:,:,iStep);
            
            switch Opts.whatData
                case 'new'
                    idxS = ismemberf(s0new,s0m,'tol',Opts.tol); %available in the matlab central
                    idxR = ismemberf(Rtnew.',Rtm.','rows','tol',Opts.tol).';
                    idxL = ismemberf(Ltnew.',Ltm.','rows','tol',Opts.tol).';
                    idxNew = or(or(~idxS, ~idxR),~idxL);
                case 'all'
                    idxNew = 1:nRed; %take all
            end
            
            s0m = [s0m, s0new(idxNew)];
            Rtm = [Rtm, Rtnew(:,idxNew)]; Ltm = [Ltm, Ltnew(:,idxNew)];
        end
        
        %   Do complexpair
        s0mUnsrt = s0m; s0m = cplxpair(s0mUnsrt);
        % get permutation indices, since cplxpair does not do it for you
        [~,cplxSorting] = ismember(s0m,s0mUnsrt);
        Rtm = Rtm(:,cplxSorting); Ltm = Ltm(:,cplxSorting);        
    end
    function poles = initializePoles(type,nm)
        switch type
            case 'eigs'
                poles = eigs(sys,nm,'sm').';
            case 'vectfit3'
                try
                    wMax = abs(imag(eigs(sys,1,'li')));
                catch
                    wMax = 1e3;
                end
                
                %generate initial poles
                bet=logspace(-2,log10(wMax),nm/2);
                poles=[];
                for k=1:length(bet)
                    alf=-bet(k)*1e-2;
                    poles=[poles (alf-1i*bet(k)) (alf+1i*bet(k)) ];
                end
            case 'gershgorin'
        end
    end

    %% Trash
    function Dr0 = sweepDr0(sweepcost)
        %   Compute Dr0 from a sweep that tries to minimize "cost"
        
        if Opts.plot, figure; sigma(sysm-sysr0,'b', 'LineWidth',2); end

        Dr0 = DrInit('0'); % Initialize with the data at the origin
        DrSet(:,:,1)= Dr0; dMin = sweepcost(Dr0); dSet(:,:,1) = dMin;

        deltaDr = 2*abs(DrInit('Ge0'));
        probSize = sys.m*sys.p; %dimension of the search space

        %CURSE of DIMENSIONALITY!!
        if probSize < 9 , nStep = 9; else nStep = 5; end

        % Create the grid
        x = {}; 
        for iOut = 1:sys.p
            for jIn = 1:sys.m
                x = [x, ...
                    {linspace(-deltaDr(iOut,jIn),deltaDr(iOut,jIn),nStep).'}];
            end
        end
        X = cell(1,probSize); [X{:}] = ndgrid(x{:});   
        
        % Run the sweep
        nPoints = nStep^probSize;                
        for k=1:nPoints    
            %   generate the current feedthrough
            for iEl = 1:probSize, Dr0(iEl) = X{iEl}(k); end

            sysr = sysrfun(Dr0);

            d = sweepcost(Dr0);
            if d < dMin && isstable(sysr)
                dMin = d;
%                 dSet(:,:,end+1) = d; %only for analysis
%                 DrSet(:,:,end+1)= Dr0;
                DrSet = Dr0;
                if Opts.plot
                    syse = sysm-sysr; sigma(syse,'Color',rand(1,3)); 
                    drawnow
                end
            end
        end
        
        %   best feedthrough
        Dr0 = DrSet(:,:,end); 
        if Opts.plot 
            syse = sysm-sysrfun(Dr0); sigma(syse,'Color',rand(1,3),...
                                           'LineWidth',2); drawnow 
        end          
    end
    function bound = HinfBound(sys,B_,C_)
        % Panzer 2014 
%         function bndHinf = BoundHinf(L_S,P_S,B,C)
        % Upper bound on H-infinity norm of strictly dissipative system
        % Input: L_S,P_S: Cholesky factor of S=-A-A', and permutation matrix;
        % B_,C_ : Perp input and output matrices
        % Output: bndHinf: Upper bound
        % (c) 2014 Heiko K.F. Panzer, Tech. Univ. Muenchen.
        % This file is published under the BSD 3-Clause License. All rights reserved.
        
        S = -(sys.A + sys.A.'); [L_S,p,P_S] = chol(S); 
            if p
                warning('System is not in strictly dissipative form. HinfBound set to Inf');
                bound = inf;
            else
                B_S = L_S'\(P_S'*B_);
                C_S = (L_S'\(P_S'*C_'))';
                bound = norm(full(C_S*B_S)) + norm(full(B_S))*norm(full(C_S));
            end
    end

end




