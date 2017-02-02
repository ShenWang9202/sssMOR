classdef ssRed < ss
% SSRED - Reduced state-space LTI system (ssRed) class
%
% Syntax:
%       sysr = ssRed(method,params,A,B,C)
%       sysr = ssRed(method,params,A,B,C,paramsList)
%       sysr = ssRed(method,params,A,B,C,D)
%       sysr = ssRed(method,params,A,B,C,D,paramsList)
%       sysr = ssRed(method,params,A,B,C,D,E)
%       sysr = ssRed(method,params,A,B,C,D,E,paramsList)
%       sysr = ssRed(method,params,sys_sss)
%       sysr = ssRed(method,params,sys_sss,paramsList)
%       sysr = ssRed(method,params,sys_ss)
%       sysr = ssRed(method,params,sys_ss,paramsList)
%       sysr = ssRed(method,params,sys_ssRed)
%
% Description:
%       This class is derived from the ss-class. It is used to represent
%       models which are the result of reducing the order of large models
%       with specific algorithms. ssRed objects have all attributes that ss
%       objects normally possess
%
% Input Arguments:
%       -method: name of the used reduction algorithm;
%                ['tbr' / 'modalMor' / 'irka' / 'rk' / 'projectiveMor' / 'porkV' / 'porkW' / 'spark' / 'cure_spark' / 'cure_irka' / 'cure_rk+pork' / 'rkOp' / 'rkIcop' / 'userDefined']
%       -params (tbr):          structure with the parameters for the tbr-algorithm;
%           -.originalOrder:    Model order before reduction;
%           -.type:             select amongst different tbr algorithms
%                               ['tbr' / 'adi' / 'matchDcGain' ]
%           -.redErr:           upper bound of reduction error
%                               ['0' / positive float]
%           -.hsvTol:           tolerance for Hankel-Singular values
%                               ['1e-15' / positive float]
%           -.lse:              solve linear system of equations (only for adi)
%                               ['gauss' / 'luChol']
%           -.hsv:              Hankel singular values
%       -params (modalMor):     structure with the parameters for the
%                               modalMor-algorithm
%           -.originalOrder:    Model order before reduction
%           -.type:             option to eigs command;
%                               ['SM' / 'LM' / 'SA' / 'LA' / 'SR' / 'LR' / real or complex scalar]
%           -.orth:             orhtogonalization;
%                               ['0' / 'qr']
%           -.real:             real reduced system;
%                               ['real' / '0']
%           -.tol:              tolerance for the eigenspace computation;
%                               [positive float]
%           -.dominance:        perform dominance analysis;
%                               ['0' / 'analyze' / '2q' / '3q' / '4q']
%       -params (irka):         structure with the parameters for the
%                               irka-algorithm
%           -.originalOrder:    Model order before reduction
%           -.maxiter:          maximum number of iterations;
%                               [50 / positive integer]
%           -.tol:              convergence tolerance;
%                               [1e-3 / positive float]
%           -.type:             choose between different irka modifications;
%                               ['' / 'stab']
%           -.stopCrit:	        stopping criterion;
%                               ['combAny' / 's0' / 'sysr' / 'combAll']
%           -.orth:             orthogonalization of new projection direction
%                               ['2mgs' / 0 / 'dgks' / 'mgs']
%           -.reorth:           reorthogonalization
%                               ['gs' / 0 / 'qr']
%           -.lse:              use LU or hessenberg decomposition
%                               ['sparse' / 'full' / 'hess']
%           -.dgksTol:          tolerance for dgks orthogonalization
%                               [1e-12 / positive float]
%           -.krylov:           standard or cascaded krylov basis
%                               [0 / 'cascade]
%           -.kIter:            number of iterations
%           -.s0:               final choice of shifts
%           -.Rt:               final choice of right tangential directions
%                               for MIMO
%           -.Lt:               final choice of left tangential directions
%                               for MIMO
%           -.s0Traj:           trajectory of all shift
%           -.RtTraj:           trajectory of right tangential directions
%           -.LtTraj:           trajectory of left tangential directions
%       -params (rk):           structure with the parameters for the
%                               rk-algorithm
%           -.originalOrder:    Model order before reduction
%           -.real:             keep the projection matrices real
%                               [true / false]
%           -.orth:             orthogonalization of new projection direction
%                               ['2mgs' / 0 / 'dgks' / 'mgs']
%           -.reorth:           reorthogonalization
%                               ['gs' / 0 / 'qr']
%           -.lse:              use LU or hessenberg decomposition
%                               ['sparse' / 'full' / 'hess']
%           -.dgksTol:          tolerance for dgks orthogonalization
%                               [1e-12 / positive float]
%           -.krylov:           standard or cascaded krylov basis
%                               [0 / 'cascade]
%           -.IP:               inner product
%           -.s0_inp:           expansion points for input Krylov subspaces
%           -.s0_out:           expansion points for output Krylov
%                               subspaces
%           -.Rt:               right tangential directions for MIMO
%           -.Lt:               left tangential directions for MIMO
%       -params (projectiveMor):structure with the parameters for the
%                               projectiveMor-algorithm
%           -.originalOrder:    Model order before reduction
%           -.trans:            choose how W should be transposed
%                               [ {T} / H ]
%       -params (porkV):        structure with the parameters for the
%                               porkV-algorithm
%           -.originalOrder:    Model order before reduction
%       -params (porkW):        structure with the parameters for the
%                               porkW-algorithm
%           -.originalOrder:    Model order before reduction
%       -params (spark):        structure with the parameters for the
%                               spark-algorithm
%           -.originalOrder:    Model order before reduction
%           -.spark.type:       chooses between standard SPARK, where the original 
%                               model is reduced directly, or MESPARK, where a 
%                               model function is created and updated after convergence.
%                               [{'model'} / 'standard']
%           -.spark.mfe:        maximum functions evaluations
%                               [{'5e3'} / positive integer]
%           -.spark.mi:         maximum iterations in solver
%                               [{'150'} / positive integer]
%           -.spark.xTol:       step tolerance in solver
%                               [{'1e-10'} / positive float]
%           -.spark.fTol:       function value tolerance
%                               [{'1e-10'} / positive float]
%           -.spark.modelTol:   convergence tolerance for model funciton
%                               [{'1e-5'} / positive float]
%           -.spark.pork:       projection with porkV (input krylov subspace)
%                               or porkW (output krylov subspace)
%                               [{'V'} / 'W']
%           -.mespark.ritz:     use eigenvalues of model function to initialize
%                               the shifts 
%                               [{'1'} / '0']
%           -.mespark.pertIter: number of iterations after which a
%                               pertubation of the shifts starts to avoid
%                               stagnation of the model function
%                               [{'5'} / positive integer]
%           -.mespark.maxIter:  maximum number of model function updates
%                               [{'20'} / positive integer]
%       -params (cure_spark):   structure with the parameters for the
%                               cure-algorithm (reduction algorithm spark)
%           -.originalOrder:    Model order before reduction
%           -.currentReducedOrder: Model order at the current iteration
%                                  step of the cure algorithm
%           -.shifts:           Shifts used for the current iteration step 
%                               of the cure algorihm
%           -.cure.fact:        factorization mode 
%                               [{'V'} / 'W']
%           -.cure.stop:        stopping criterion
%                               [{'nmax'} / 'h2Error']
%           -.cure.stopval:     value according to which the stopping criterion is evaluated
%                               [{'round(sqrt(sys.n))'} / positive integer]
%           -.cure.maxIter:     maximum number of CURE iterations
%                               [{'20'} / positive integer]
%           -.spark.type:       chooses between standard SPARK, where the original 
%                               model is reduced directly, or MESPARK, where a 
%                               model function is created and updated after convergence.
%                               [{'model'} / 'standard']
%           -.spark.mfe:        maximum functions evaluations
%                               [{'5e3'} / positive integer]
%           -.spark.mi:         maximum iterations in solver
%                               [{'150'} / positive integer]
%           -.spark.xTol:       step tolerance in solver
%                               [{'1e-10'} / positive float]
%           -.spark.fTol:       function value tolerance
%                               [{'1e-10'} / positive float]
%           -.spark.modelTol:   convergence tolerance for model funciton
%                               [{'1e-5'} / positive float]
%           -.mespark.ritz:     use eigenvalues of model function to initialize
%                               the shifts 
%                               [{'1'} / '0']
%           -.mespark.pertIter: number of iterations after which a
%                               pertubation of the shifts starts to avoid
%                               stagnation of the model function
%                               [{'5'} / positive integer]
%           -.mespark.maxIter:  maximum number of model function updates
%                               [{'20'} / positive integer]
%       -params (cure_irka):    structure with the parameters for the
%                               cure-algorithm (reduction algorithm irka)
%           -.originalOrder:    Model order before reduction
%           -.currentReducedOrder: Model order at the current iteration
%                                  step of the cure algorithm
%           -.shifts:           Shifts used for the current iteration step 
%                               of the cure algorihm
%           -.cure.fact:        factorization mode 
%                               [{'V'} / 'W']
%           -.cure.stop:        stopping criterion
%                               [{'nmax'} / 'h2Error']
%           -.cure.stopval:     value according to which the stopping criterion is evaluated
%                               [{'round(sqrt(sys.n))'} / positive integer]
%           -.cure.SE_DAE:      reduction of index 1 semiexplicit DAE 
%                               [{'0'} / '1']
%           -.cure.maxIter:     maximum number of CURE iterations
%                               [{'20'} / positive integer]
%           -.maxiter:          maximum number of iterations;
%                               [50 / positive integer]
%           -.tol:              convergence tolerance;
%                               [1e-3 / positive float]
%           -.type:             choose between different irka modifications;
%                               ['' / 'stab']
%           -.verbose:          show text output during iterations;
%                               [0 / 1]
%           -.stopCrit:	        stopping criterion;
%                               ['combAny' / 's0' / 'sysr' / 'combAll']
%           -.suppressverbose:  suppress any type of verbose for speedup;
%                               [0 / 1]
%           -.orth:             orthogonalization of new projection direction
%                               ['2mgs' / 0 / 'dgks' / 'mgs']
%           -.reorth:           reorthogonalization
%                               ['gs' / 0 / 'qr']
%           -.lse:              use LU or hessenberg decomposition
%                               ['sparse' / 'full' / 'hess']
%           -.dgksTol:          tolerance for dgks orthogonalization
%                               [1e-12 / positive float]
%           -.krylov:           standard or cascaded krylov basis
%                               [0 / 'cascade]
%           -.kIter:            number of iterations
%           -.s0:               final choice of shifts
%           -.Rt:               final choice of right tangential directions
%                               for MIMO
%           -.Lt:               final choice of left tangential directions
%                               for MIMO
%           -.s0Traj:           trajectory of all shift
%           -.RtTraj:           trajectory of right tangential directions
%           -.LtTraj:           trajectory of left tangential directions
%       -params (cure_rk+pork): structure with the parameters for the
%                               cure-algorithm (reduction algorithm rk+pork)
%           -.originalOrder:    Model order before reduction
%           -.currentReducedOrder: Model order at the current iteration
%                                  step of the cure algorithm
%           -.shifts:           Shifts used for the current iteration step 
%                               of the cure algorihm
%           -.cure.fact:        factorization mode 
%                               [{'V'} / 'W']
%           -.cure.stop:        stopping criterion
%                               [{'nmax'} / 'h2Error']
%           -.cure.stopval:     value according to which the stopping criterion is evaluated
%                               [{'round(sqrt(sys.n))'} / positive integer]
%           -.cure.SE_DAE:      reduction of index 1 semiexplicit DAE 
%                               [{'0'} / '1']
%           -.cure.maxIter:     maximum number of CURE iterations
%                               [{'20'} / positive integer]
%           -.real:             keep the projection matrices real
%                               [true / false]
%           -.orth:             orthogonalization of new projection direction
%                               ['2mgs' / 0 / 'dgks' / 'mgs']
%           -.reorth:           reorthogonalization
%                               ['gs' / 0 / 'qr']
%           -.lse:              use LU or hessenberg decomposition
%                               ['sparse' / 'full' / 'hess']
%           -.dgksTol:          tolerance for dgks orthogonalization
%                               [1e-12 / positive float]
%           -.krylov:           standard or cascaded krylov basis
%                               [0 / 'cascade]
%           -.IP:               inner product
%           -.s0_inp:           expansion points for input Krylov subspaces
%           -.s0_out:           expansion points for output Krylov
%                               subspaces
%           -.Rt:               right tangential directions for MIMO
%           -.Lt:               left tangential directions for MIMO
%       -params (rkOp):         structure with the parameters for the
%                               rkOp-algorithm
%           -.originalOrder:    Model order before reduction
%           -.sOpt:             optimal expansion point
%           -.rk:               reduction type
%                               [{'twoSided'} / 'input' / 'output']
%           -.lse:              solve linear system of equations
%                               [{'sparse'} / 'full' / 'gauss' / 'hess' / 'iterative' ]
%       -params (rkIcop):       structure with the parameters for the
%                               rkIcop-algorithm
%           -.originalOrder:    Model order before reduction
%           -.sOpt:             optimal expansion point
%           -.s0:               inital expansion point (scalar)
%           -.rk:               reduction type
%                               [{'twoSided'} / 'input' / 'output']
%           -.maxIter:          maximum number of iterations;
%                               [{20} / positive integer]
%           -.tol:              convergence tolerance;
%                               [{1e-2} / positive float]
%           -.lse:              solve linear system of equations
%                               [{'sparse'} / 'full' / 'gauss' / 'hess' / 'iterative' ]
%       -params (modelFct):     structure with the parameters for the
%                               modelFct-algorithm
%           -.originalOrder:    Model order before reduction
%           -.s0mTot:           vector of all shifts used
%           -.updateModel:      chooses which shifts of s0mr are included in update;
%                               [{'new'} / 'all' / 'lean' ]
%           -.modelTol:         tolerance for identifying new shifts;
%                               [{1e-2} / positive float ]
%       -params (cirka):        structure with the parameters for the
%                               cirka-algorithm
%           -.originalOrder:    Model order before reduction
%           -.modelFctOrder:    Final order of the model function
%           -.kIrka:            Vector of irka iterations
%           -.s0:               final shifts for reduction
%           -.qm0:              initial size of model function;
%                               [{2*length(s0)} / positive integer]
%           -.s0m:              initial shifts for surrogate;
%                               [{[s0,s0]} / vector ]
%           -.maxiter:          maximum number of iterations;
%                               [{15} / positive integer]
%           -.tol:              convergence tolerance;
%                               [{1e-3} / positive float]
%           -.stopCrit:         convergence criterion for CIRKA;
%                               ['s0' / 'sysr' / 'sysm' / {'combAny'} / 'combAll']
%           -.updateModel:      type of model function update;
%                               [{'new'},'all']
%           -.clearInit:        reset the model function after first iteration;
%                               [{true}, false]
%           -.irka:             irka options (cmp irka)
%       -params (stabsep):      structure with the parameters for the
%                               stabsep-algorithm
%           -.originalOrder     Model order before reduction
%       -params (userDefined):  []
%       -A: system matrix
%       -B: input matrix
%       -C: output matrix
%       -D: static gain matrix
%       -E: descriptor matrix
%       -sys_ss:    control system toolbox state-space (ss)-object
%       -sys_sss:   sparse state-space (sss)-object
%       -paramsList{i}: Cell-Array of structs. Each field of the cell-array 
%                       represents one reduction (without the current reduction).
%           -.method:           name of the used reduction algorithm (see above)                               
%           -.params:           structure with the parameters of the used
%                               algorithm (see above)
%
% Output Arguments:
%       -sys: reduced state-space (ssRed)-object
%
% Examples:
%       This code creates an instance of the ssRed-class
%
%> A = rand(10);
%> B = rand(10,1);
%> C = rand(1,10);
%> params.originalOrder = 20;
%> sysr = ssRed('porkV',params,A,B,C);
%
% See Also: 
%        ss, dss, sss
%
% References:
%		* *[1] Documentation of the Control System Toolbox from MATLAB*
%
%------------------------------------------------------------------
% This file is part of <a href="matlab:docsearch sssMOR">sssMOR</a>, a Sparse State-Space, Model Order 
% Reduction and System Analysis Toolbox developed at the Chair of 
% Automatic Control, Technische Universitaet Muenchen. For updates 
% and further information please visit <a href="https://www.rt.mw.tum.de/">www.rt.mw.tum.de</a>
% For any suggestions, submission and/or bug reports, mail us at
%                   -> <a href="mailto:sssMOR@rt.mw.tum.de">sssMOR@rt.mw.tum.de</a> <-
%
% More Toolbox Info by searching <a href="matlab:docsearch sssMOR">sssMOR</a> in the Matlab Documentation
%
%------------------------------------------------------------------
% Authors:      Niklas Kochdumper, Alessandro Castagnotto
% Email:        <a href="mailto:sssMOR@rt.mw.tum.de">sssMOR@rt.mw.tum.de</a>
% Website:      <a href="https://www.rt.mw.tum.de/">www.rt.mw.tum.de</a>
% Work Adress:  Technische Universitaet Muenchen
% Last Change:  20 Jan 2017
% Copyright (c) 2016,2017 Chair of Automatic Control, TU Muenchen
%------------------------------------------------------------------
    
    properties(SetAccess = private)
        reductionParameters
    end
    properties(Dependent, Hidden)
        n,p,m
        isSiso, isSimo, isMiso, isMimo, isBig
        isDae, isDescriptor
    end
    properties(Hidden)
        HankelSingularValues
        TBal, TBalInv
        ConGram, ConGramChol
        ObsGram, ObsGramChol
        
        isSym
    end
    properties(Hidden,Access = private)
        a_,b_,c_,d_,e_
    end
    
    methods
        function obj = ssRed(varargin)
            % parse and check the arguments
            if nargin < 3 || nargin > 8 || nargin == 4
                error('Invalid syntax for the "ssRed" command. Type "help ssRed" for more information.');
            end
            paramsList = [];
            nargin_new = nargin;
            if ~isnumeric(varargin{nargin}) && ~isa(varargin{nargin},'ss') && ...
               ~isa(varargin{nargin},'sss')         %paramsList specified
                paramsList = varargin{nargin};
                nargin_new = nargin_new-1;
            end
            if nargin_new == 3
                sys = varargin{3};
                if isa(sys,'ssRed')
                    if ~isempty(paramsList)
                        error('Invalid syntax for the "ssRed" command. Type "help ssRed" for more information.');
                    end
                    paramsList = sys.reductionParameters;
                end
                if isa(sys,'ss')    %ss-objects or ssRed-objects
                   [A,B,C,D,E] = dssdata(sys);
                elseif isa(sys,'sss')   %sss-objects
                   [A,B,C,D,E] = full(dssdata(sys));
                else
                   error('The third argument has to be an object of type "ss" or "sss"'); 
                end
            else
                A = full(varargin{3});
                B = full(varargin{4});
                C = full(varargin{5});
                
                if nargin_new == 6
                    D = full(varargin{6});
                    E = [];
                elseif nargin_new == 7
                    D = full(varargin{6});
                    E = full(varargin{7});
                else                
                    D = [];
                    E = [];
                end             
            end
            
            if ~isa(varargin{1},'char')
                error('sssMOR:ssRed:wrongUsage',...
                    'The first argument must be a string specifying the reduction method. Type "help ssRed" for more information.');
            elseif ~ismember(varargin{1},{'tbr', ...
                    'modalMor','rk','irka','projectiveMor','porkV','porkW', ...
                    'spark','cure_spark','cure_irka','cure_rk+pork','rkOp', ...
                    'rkIcop','modelFct','cirka','stabsep','userDefined'})
                error('sssMOR:ssRed:reductionMethodUndefined',...
                    'The reduction method specified (%s) is undefined. Type "help ssRed" for more information.',...
                    varargin{1});
            end
            
            % call the constructor of the superclass ss
            obj@ss(A,B,C,D,'e',E);
            
            % store the correct names for the properties containing the
            % system matrices. This is a compatibility fix because the
            % property names changed from lower to upper case in Matlab
            % R2016a. To access the system matrices, use "obj.(obj.a_)"
            obj.a_ = ltipack.matchProperty('a',...
                            ltipack.allprops(obj),class(obj));
            obj.b_ = ltipack.matchProperty('b',...
                            ltipack.allprops(obj),class(obj));
            obj.c_ = ltipack.matchProperty('c',...
                            ltipack.allprops(obj),class(obj));
            obj.d_ = ltipack.matchProperty('d',...
                            ltipack.allprops(obj),class(obj));
            obj.e_ = ltipack.matchProperty('e',...
                            ltipack.allprops(obj),class(obj));
                        
            % check all fields of paramsList
            if ~isempty(paramsList)
                try
                   for i = 1:size(paramsList,1)
                      if length(fieldnames(paramsList{i})) ~= 2
                          error('The argument "paramsList" has the wrong format. Type "help ssRed" for more information.');
                      end
                      if i > 1 && ismember(paramsList{i-1}.method,{'cure_spark','cure_irka','cure_rk+pork'})
                          paramsList{i}.params = obj.parseParamsStruct(paramsList{i}.params,paramsList{i}.method,0);
                      else
                          paramsList{i}.params = obj.parseParamsStruct(paramsList{i}.params,paramsList{i}.method,1);
                      end
                   end
                catch ex
                   error('The argument "paramsList" has the wrong format. Type "help ssRed" for more information.'); 
                end
            end
            
            % update the reductionParameters list
            if isempty(paramsList)
               obj.reductionParameters = cell(1,1);
               obj.reductionParameters{1,1}.method = varargin{1};
               try
                   obj.reductionParameters{1,1}.params = obj.parseParamsStruct(varargin{2},varargin{1},1);
               catch ex
                   error('The argument "params" has the wrong format. Type "help ssRed" for more information.');
               end
            else
               len = size(paramsList,1);
               obj.reductionParameters = paramsList;
               obj.reductionParameters{len+1,1}.method = varargin{1};
               try
                   obj.reductionParameters{len+1,1}.params = obj.parseParamsStruct(varargin{2},varargin{1},1);
               catch ex
                   error('The argument "params" has the wrong format. Type "help ssRed" for more information.');
               end
            end
            
            % remove unnecessary parmaters from the reduction history
            if nargin_new == 3 && isa(sys,'ssRed')
                if ~strcmp(varargin{1},'projectiveMor')
                    obj.reductionParameters = obj.removeReductionMethod(obj.reductionParameters,'projectiveMor');
                end
                if strcmp(varargin{1},'irka')
                    obj.reductionParameters = obj.removeReductionMethod(obj.reductionParameters,'rk'); 
                end
                if strcmp(varargin{1},'rkOp') || strcmp(varargin{1},'rkIcop')
                    obj.reductionParameters{end-1,1} = [];
                    obj.reductionParameters = obj.reductionParameters(~cellfun('isempty',obj.reductionParameters));
                end
            end
            obj.reductionParameters = obj.removeCureParameters(obj.reductionParameters); 
        end
                
        %% Get Basic Properties
        function m = get.m(sys) % number of inputs
            m = size(sys.(sys.b_),2);
        end
        function n = get.n(sys) % system order
            n = size(sys.(sys.a_),1);
        end
        function p = get.p(sys) % number of outputs
            p = size(sys.(sys.c_),1);
        end
        
        %% Get helper functions
        function isSiso = get.isSiso(sys); isSiso=(sys.p==1)&&(sys.m==1); end
        function isSimo = get.isSimo(sys); isSimo=(sys.p>1)&&(sys.m==1); end
        function isMiso = get.isMiso(sys); isMiso=(sys.p==1)&&(sys.m>1); end
        function isMimo = get.isMimo(sys); isMimo=(sys.p>1)||(sys.m>1); end
        function isBig = get.isBig(sys); isBig=(sys.n>5000);end
        
        function isDae = get.isDae(sys)
            if condest(sys.(sys.e_))==Inf
                isDae = 1;
            else
                isDae = 0;
            end
        end
        
        function isDescriptor = get.isDescriptor(sys)
            isDescriptor = logical(full(any(any(sys.(sys.e_)-eye(size(sys.(sys.e_)))))));
        end
        
        function sys = resolveDescriptor(sys)
            sys.(sys.a_) = sys.(sys.e_)\sys.(sys.a_);
            sys.(sys.b_) = sys.(sys.e_)\sys.(sys.b_);
            sys.(sys.e_) = eye(size(sys.(sys.a_))); 
            %makes the usage of sys.e in computations more robust than []
        end
        
        function isSym = get.isSym(sys) %A=A', E=E'
            if isequal(sys.isSym,0) || isequal(sys.isSym,1)
                isSym = sys.isSym;
            else
                if max(max(sys.(sys.a_)-sys.(sys.a_).'))<1e-6 && max(max(sys.(sys.e_)-sys.(sys.e_).'))<1e-6
                    isSym = 1;
                else
                    isSym = 0;
                end
            end
        end    
        
        function sys = changeReductionParameters(sys,params)
        % This function overrides the last entry of the cell-array 
        % "obj.reductionParameters" with the parameters specified in 
        % "params". 
        
            l = length(sys.reductionParameters);
        
            try
                if l > 1 && ismember(sys.reductionParameters{l-1}.method,{'cure_spark','cure_irka','cure_rk+pork'})
                    sys.reductionParameters{l}.params = sys.parseParamsStruct(params.params,params.method,0);
                    sys.reductionParameters{l}.method = params.method;
                else
                    sys.reductionParameters{l}.params = sys.parseParamsStruct(params.params,params.method,0);
                    sys.reductionParameters{l}.method = params.method;
                end
            catch ex
                error('The argument "params" has the wrong format. Type "help ssRed" for more information.');
            end 
        end
        
        %% Overload subsref to cope with compatibility issues in MATLAB
        function result = subsref(sys, arg)
            %   Parts are taken from built-in subsref
            %   Copyright 1986-2010 The MathWorks, Inc.
            
            ni = nargin;
            if ni==1,
               result = M;  return
            end
            switch arg(1).type
              case '.'
                  %COMPATIBILITY ISSUE BETWEEN 2015b and 2016a
                  % make sure system matrices have the right (lower/upper)
                  % case
                  if any(strcmp(arg(1).subs,{'a','b','c','d','e','A','B','C','D','E'}))
                        arg(1).subs = ltipack.matchProperty(arg(1).subs,...
                            ltipack.allprops(sys),class(sys));
                  end
                 result = builtin('subsref',sys,arg(1));
              case '()'
                 result = subparen(sys,arg(1).subs);
              case '{}'
                 ctrlMsgUtils.error('Control:ltiobject:subsref3')
            end
           if length(arg)>1,
              % SUBSREF for InputOutputModel objects can't be invoked again
              % inside this method so jump out to make sure that downstream
              % references to InputOutputModel properties are handled correctly,
              result = ltipack.dotref(result,arg(2:end));
           end
    end
        %% Override operators and build-in-functions
        
        function infostr = disp(sys)
        % Displays information about a reduced state-space model (Similar
        % to sss/disp, but with additional information)
            if isempty(sys)
                fprintf(1,'  Empty reduced state-space model.\n\n');
            else
                mc = metaclass(sys);
                str = [];
                if ~isempty(mc.Name) && ~isempty(sys.Name)
                    str = [mc.Name ' Model ' sys.Name, ' '];
                end

                if sys.isDae;            str = [str '(DAE)'];
                elseif sys.isDescriptor; str = [str '(DssRed)'];
                else                     str = [str '(ssRed)'];
                end

                if sys.isSiso;       str = [str '(SISO)'];
                elseif sys.isSimo;   str = [str '(SIMO)'];
                elseif sys.isMiso;   str = [str '(MISO)'];
                elseif sys.isMimo;   str = [str '(MIMO)'];
                end

                str = [str  char(10), num2str(sys.n) ' states, ' num2str(sys.m) ...
                    ' inputs, ' num2str(sys.p) ' outputs'];

                if sys.Ts==0
                    str = [str  char(10) 'Continuous-time state-space model.'];
                else
                    str = [str  char(10) 'Sample time: ' num2str(sys.Ts) ' seconds'];
                    str = [str  char(10) 'Discrete-time state-space model.'];
                end
                
                params = sys.reductionParameters{end,1};
                if strcmp(params.method,'userDefined')
                    str = [str char(10) 'Reduction Method: ' params.method char(10)];
                else
                    str = [str char(10) 'Reduction Method: ' params.method char(10) ...
                            'Original order: ' num2str(params.params.originalOrder)];
                end

                if nargout>0
                    infostr = {str};
                else
                    str = strrep(str, char(10), [char(10) '  ']);
                    disp(['  ' str char(10)]);
                end
            end
        end
        
        
        function varargout = eig(sys, varargin)
            if sys.isBig
                warning(['System order is very large: ',num2str(sys.n),'. You may want to try eigs(sys) instead.'])
            end
            
            [A,~,~,~,E] = dssdata(sys);
            if sys.isDescriptor
                if nargout==1||nargout==0
                    [varargout{1}] = eig(full(A), full(E),varargin{:});
                elseif nargout == 2
                    [varargout{1}, varargout{2}] = eig(full(A), full(E),varargin{:});
                elseif nargout == 3
                    [varargout{1}, varargout{2}, varargout{3}]  = eig(full(A), full(E),varargin{:});
                end
            else
                if nargout==1||nargout==0
                    [varargout{1}] = eig(full(A),varargin{:});
                elseif nargout == 2
                    [varargout{1}, varargout{2}] = eig(full(A),varargin{:});
                elseif nargout == 3
                    [varargout{1}, varargout{2}, varargout{3}]  = eig(full(A),varargin{:});
                end
            end
        end
        
        function diff = minus(sys1, sys2) 
            [A1,B1,C1,D1,E1] = dssdata(sys1);
            [A2,B2,C2,D2,E2] = dssdata(sys2);
            if size(A1,1) == 0
                if isa(sys2,'sss')
                    diff = sss(A2, B2, -C2, D2, E2);
                else
                    diff = dss(A2, B2, -C2, D2, E2);
                end
                return
            end
            if size(A2,1) == 0
                diff = dss(A1, B1, C1, D1, E1);
                return
            end

            if size(B1,2) ~= size(B2,2)
                error('sys1 and sys2 must have same number of inputs.')
            end
            if size(C1,1) ~= size(C2,1)
                error('sys1 and sys2 must have same number of outputs.')
            end
            if isa(sys1,'ss') && isempty(E1)
                sys1.(sys1.e_) = eye(size(A1,1));
            end
            if isa(sys2,'ss') && isempty(E2)
                sys2.(sys1.e_) = eye(size(A2,1));
            end

            if isa(sys2,'sss')           
                diff = sss([A1 sparse(size(A1,1),size(A2,1)); sparse(size(A2,1),size(A1,1)) A2], ...
                    [B1; B2], ...
                    [C1, -C2], ...
                    D1 - D2, ...
                    [E1 sparse(size(A1,1),size(A2,1)); sparse(size(A2,1),size(A1,1)) E2]);
            else
                diff = dss([A1 zeros(size(A1,1),size(A2,1)); zeros(size(A2,1),size(A1,1)) A2], ...
                    [B1; B2], ...
                    [C1, -C2], ...
                    D1 - D2, ...
                    [E1 zeros(size(A1,1),size(A2,1)); zeros(size(A2,1),size(A1,1)) E2]);
            end
        end
        
        function [r,p,d] = residue(sys, Opts)       
            Def.rType = 'res';

            if ~exist('Opts','var') || isempty(Opts)
                Opts = Def;
            else
                Opts = parseOpts(Opts,Def);
            end

            %perform eigen-decomposition of system
            try
                [T,J] = eig(sys);
            catch err
                error('Computation of the eigenvalues and eigenvectors failed with message:%s',err.message);
            end

            % transform system to diagonal form
            p=diag(J).';
            if issparse(T)
                rcondNumber = 1/condest(T);
            else
                rcondNumber=rcond(T);
            end
            if rcondNumber<eps
                warning(['Matrix of eigenvectors is close to singular or badly scaled. Results may be inaccurate. RCOND =',num2str(rcondNumber)]);
            end
            [~,B,C,D,E] = dssdata(sys);
            B=(E*T)\B;
            C=C*T;
            d=D;

            % calculate residues
            if strcmp(Opts.rType,'dir')
                % return the residual directions instead of the residuals
                r = {C, B};  
            else
                % return the residuals
                r = cell(1,sys.n);
                for i=1:sys.n
                    r{i} = full(C(:,i)*B(i,:));
                end
            end
        end
        
        function tmax = decayTime(sys)
            [res,p]=residue(sys);

            % is system stable?
            if any(real(p)>0 & real(p)<1e6) % larger than 0 but, smaller than infinity-threshold
                % no -> tmax=NaN
                tmax=NaN;
                warning('sss:decayTime:UnstableSys','The system is not stable. The decay time is set to tmax=NaN.');
                return
            end

            tmax=0; temp = cat(3,res{:}); 
            for i=1:sys.p
                for j=1:sys.m
                    % how much does each pole contribute to energy flow?
                    h2=zeros(size(p));
                    for k=1:length(p)
                        %we need the siso residual for all poles into on vectors
                        resIJvec = squeeze(temp(i,j,:)).';
                        h2(k)=res{k}(i,j)*sum(resIJvec./(-p(k)-p));
                    end

                    [h2_sorted, I] = sort(real(h2));
                    % which pole contributes more than 1% of total energy?
                    I_dom = I( h2_sorted > 0.01*sum(h2_sorted) );
                    if isempty(I_dom)
                        % no poles are dominant, use slowest
                        I_dom = 1:length(p);
                    end
                    % use slowest among dominant poles
                    [h2_dom, I2] = sort(abs(real(p(I_dom))));

                    % when has slowest pole decayed to 1% of its maximum amplitude?
                    tmax=max([tmax, log(100)/abs(real(p(I_dom(I2(1)))))]);
                end
            end
        end
        
        function [issd, numericalAbscissa] = issd(sys)
            %  Parse input
            if condest(sys.(sys.e_))>1e16, error('issd does not support DAEs'),end

            %  Perform computations
            % E >0?
            isPosDef = ispd(sys.(sys.e_));
            if ~isPosDef
                if nargout == 0, warning('System is not strictly dissipative (E~>0).'); 
                else issd = 0; end
                return
            end

            % A + A' <0?  
            isNegDef = ispd(-sys.(sys.a_)-sys.(sys.a_)');
            if isNegDef
                if nargout == 0, fprintf('System is strictly dissipative.\n'); else issd = 1; end
            else
                if nargout == 0, warning('System is not strictly dissipative (E>0, A+A''~<0)'); else issd = 0; end
            end

            if nargout==2 % computation of the numerical abscissa required
                p    = 20;		% number of Lanczos vectors
                tol  = 1e-10;	% convergence tolerance
                opts = struct('issym',true, 'p',p, 'tol',tol, 'v0',sum(sys.(sys.e_),2));
                try
                    numericalAbscissa = eigs((sys.(sys.a_)+sys.(sys.a_)')/2, sys.(sys.e_), 1, 'la', opts);
                catch err
                    warning('Computation of the numerical abscissa failed with message:%s',err.message);
                    numericalAbscissa = NaN;
                end
            end
        end
        
        function  [tf,g,t] = impulse(sys,varargin)
        % Override the impulse-function with three output-arguments for
        % ssRed-objects, because this syntax does not exist for the
        % Matlab build-in impulse function. Impulse with three output
        % arguments is needed in the sssMOR_App. So this function makes it
        % possible that plotting with the app works for ssRed-objects, too.
        
            % check if a tf-object should be given back
            if ~isempty(varargin) && isfield(varargin{nargin-1},'tf') && ...
                    varargin{nargin-1}.tf == 1
               
                % final Time
                t = [];
                if nargin == 3 && isfloat(varargin{1})
                    t = varargin{1};
                end

                if ~isempty(t)
                    Tfinal=t(end);
                else
                    Tfinal=0;
                end

                % get h,t by calling ss/step

                sys.(sys.d_) = zeros(size(sys.(sys.d_)));
                if ~isempty(t)
                    [h,tg] = step(sys, t(end));
                else
                    [h,tg] = step(sys);
                end

                % compute impulse response [g,t]
                if length(size(h)) == 2
                    g{1,1}=gradient(h,tg);                        
                    g{1,1}(isnan(h))=0;
                else
                    g = cell(size(h,2),size(h,3));
                    for k=1:size(g,1)
                        for j=1:size(g,2)
                            g{k,j}=gradient(h(:,k,j),tg);                        
                            g{k,j}(isnan(h(:,k,j)))=0;
                        end
                    end
                end

                % get Ts and Tfinal
                Ts=Inf;
                if isempty(t) || isscalar(t)
                    for k=1:size(g,1)
                         for j=1:size(g,2)
                            Ts=min(min(diff(tg),Ts));
                            if ~isscalar(t)
                                Tfinal=max(max(tg),Tfinal);
                            end
                         end
                    end
                else
                    Ts=min(diff(t));
                    Tfinal=t(end);
                end

                t=0:Ts:Tfinal(end);

                % create tf-object
                tf = cellfun(@(x) [x(1) diff(x')],g,'UniformOutput',false);
                tf = filt(tf,1,Ts);
                tf.Name = sys.Name;
                t = t';
                
                % provide output arguments
                if nargout == 1
                    varargout{1} = tf;
                elseif nargout == 3
                    varargout{1} = tf;
                    varargout{2} = h;
                    varargout{3} = t;
                else
                    error('Only up to three output arguments are supported, if Opts.tf==1');
                end
            else
                if nargout == 0
                    impulse@ss(sys,varargin);
                elseif nargout == 1
                    varargout{1} = impulse@ss(sys,varargin);
                elseif nargout == 2
                    [varargout{1},varargout{2}] = impulse@ss(sys,varargin);
                elseif nargout == 3
                    [varargout{1},varargout{2},varargout{3}] = impulse@ss(sys,varargin);
                end
            end
        end
        
        function  varargout = step(sys,varargin)
        % Override the step-function with three output-arguments for
        % ssRed-objects, because this syntax does not exist for the
        % Matlab build-in step function. Step with three output
        % arguments is needed in the sssMOR_App. So this function makes it
        % possible that plotting with the app works for ssRed-objects, too.
        
            % check if a tf-object should be given back
            if ~isempty(varargin) && isfield(varargin{nargin-1},'tf') && ...
                    varargin{nargin-1}.tf == 1
                % final Time
                t = [];
                if nargin == 3 && isfloat(varargin{1})
                    t = varargin{1};
                end

                if ~isempty(t)
                    Tfinal=t(end);
                else
                    Tfinal=0;
                end

                % get h,t by calling ss/step

                sys.(sys.d_) = zeros(size(sys.(sys.d_)));
                if ~isempty(t)
                    [h,tg] = step@ss(sys, t(end));
                else
                    [h,tg] = step@ss(sys, []);
                end

                % create cell array
                if length(size(h)) == 2
                    h_{1,1}=h;                        
                else
                    h_ = cell(size(h,2),size(h,3));
                    for k=1:size(h_,1)
                        for j=1:size(h_,2)
                            h_{k,j}=h(:,k,j);                      
                        end
                    end
                end

                % get Ts and Tfinal
                Ts=Inf;
                if isempty(t) || isscalar(t)
                    for k=1:size(h_,1)
                         for j=1:size(h_,2)
                            Ts=min(min(diff(tg),Ts));
                            if ~isscalar(t)
                                Tfinal=max(max(tg),Tfinal);
                            end
                         end
                    end
                else
                    Ts=min(diff(t));
                    Tfinal=t(end);
                end

                t=0:Ts:Tfinal(end);

                % create tf-object
                tf = cellfun(@(x) [x(1) diff(x')],h_,'UniformOutput',false);
                tf = filt(tf,1,Ts);
                tf.Name = sys.Name;
                t = t';
                
                % provide output arguments
                if nargout == 1
                    varargout{1} = tf;
                elseif nargout == 3
                    varargout{1} = tf;
                    varargout{2} = h;
                    varargout{3} = t;
                else
                    error('Only up to three output arguments are supported, if Opts.tf==1');
                end
            else
                if nargout == 0
                    step@ss(sys,varargin);
                elseif nargout == 1
                    varargout{1} = step@ss(sys,varargin);
                elseif nargout == 2
                    [varargout{1},varargout{2}] = step@ss(sys,varargin);
                elseif nargout == 3
                    [varargout{1},varargout{2},varargout{3}] = step@ss(sys,varargin);
                end
            end
        end
        
        function  [S,R] = lyapchol(sys,Opts)
            if sys.isDescriptor
                S = lyapchol(sys.(sys.a_),sys.(sys.b_),sys.(sys.e_));
            else
                S = lyapchol(sys.(sys.a_),sys.(sys.b_));
            end
            S = S';

            if nargout>1
                if sys.isDescriptor
                    R = lyapchol(sys.(sys.a_)', sys.(sys.c_)',sys.(sys.e_)');
                else
                    R = lyapchol(sys.(sys.a_)',sys.(sys.c_)');
                end
                R = R';
            end
        end
    end
    
    %%Private and static helper methods
    methods(Hidden, Access = private, Static)
        
        function parsedStruct       = parseParamsStruct(params,method,cureRequired)
        % Checks if the struct with the parameters  "params" has the correct
        % structure for the specified reduction method "method". If this is
        % the case, then the values of the required fields of the struct 
        % "params" are copied to the struct "parsedStruct". If ths struct
        % "params" contains additional fields, these fields are not copied
        % to the struct "parsedStruct". Because the field "cure" is only
        % stored for the first cure iteration, the parameter "cureRequired"
        % indicates whether the field "cure" is required in the struct
        % "params" or not
            
            % check algorithm-specific parameters
            if strcmp(method,'tbr')                     %tbr
               list = {'originalOrder','type','redErr','hsvTol','lse','hsv'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');                 
            elseif strcmp(method,'modalMor')            %modalMor  
               list = {'originalOrder','type','orth','real','tol','dominance'};
               parsedStruct = ssRed.parseStructFields(params,list,'params'); 
            elseif strcmp(method,'irka')                %irka
               list = {'originalOrder','maxiter','tol','type','stopCrit', ...
                       'orth','lse','dgksTol','krylov', ...
                       's0','Rt','Lt','kIter','s0Traj','RtTraj','LtTraj'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');
            elseif strcmp(method,'rk')                  %rk
               list = {'originalOrder','real','orth','reorth','lse','dgksTol','krylov', ...
                       'IP','Rt','Lt','s0_inp','s0_out'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');
            elseif strcmp(method,'modelFct')           %modelFct
               list = {'originalOrder','s0mTot','updateModel','modelTol'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');
            elseif strcmp(method,'cirka')               %cirka
               list = {'originalOrder','modelFctOrder','kIrka','s0',...
                        'qm0','s0m','maxiter','tol','stopCrit','updateModel',...
                        'clearInit','irka'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');
            elseif strcmp(method,'projectiveMor')       %projectiveMor
               list = {'originalOrder','trans'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');
            elseif strcmp(method,'stabsep')             %stabsep
               list = {'originalOrder'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');
            elseif strcmp(method,'porkV')               %porkV
               list = {'originalOrder'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');
            elseif strcmp(method,'porkW')               %porkW
               list = {'originalOrder'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');
            elseif strcmp(method,'spark')               %spark
               list = {'originalOrder'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');
               
               list = {'spark','mespark'};
               ssRed.parseStructFields(params,list,'params');
               
               list = {'type','mfe','mi','xTol', ...
                       'pork','fTol','modelTol'};
               parsedStruct.spark = ssRed.parseStructFields(params.spark,list,'params.spark');
               
               list = {'ritz','pertIter','maxIter'};
               parsedStruct.mespark = ssRed.parseStructFields(params.mespark,list,'params.mespark');
            elseif strcmp(method,'cure_spark')          %cure_spark  
               list = {'originalOrder','currentReducedOrder','shifts'};
               parsedStruct = ssRed.parseStructFields(params,list,'params'); 
                
               if cureRequired
                    list = {'cure','spark','mespark'};
                    ssRed.parseStructFields(params,list,'params');
               
                    list = {'fact','stop','stopval','maxIter'};
                    parsedStruct.cure = ssRed.parseStructFields(params.cure,list,'params.cure');
               else
                    list = {'spark','mespark'};
                    ssRed.parseStructFields(params,list,'params');
               end

               list = {'type','mfe','mi','xTol', ...
                       'fTol','modelTol'};
               parsedStruct.spark = ssRed.parseStructFields(params.spark,list,'params.spark');
               
               list = {'ritz','pertIter','maxIter'};
               parsedStruct.mespark = ssRed.parseStructFields(params.mespark,list,'params.mespark');
            elseif strcmp(method,'cure_irka')           %cure_irka
               list = {'originalOrder','currentReducedOrder','shifts','maxiter','tol', ...
                       'type','stopCrit','orth','lse','dgksTol','krylov', ...
                       's0','Rt','Lt','kIter','s0Traj','RtTraj','LtTraj'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');
               
               if cureRequired
                    list = {'cure'};
                    ssRed.parseStructFields(params,list,'params');
               
                    list = {'fact','stop','stopval','maxIter'};
                    parsedStruct.cure = ssRed.parseStructFields(params.cure,list,'params.cure');  
               end
            elseif strcmp(method,'cure_rk+pork')        %cure_rk+pork
               list = {'originalOrder','currentReducedOrder','shifts','real', ...
                       'orth','reorth','lse','dgksTol','krylov', ...
                       'IP','Rt','Lt','s0_inp','s0_out'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');
               
               if cureRequired
                    list = {'cure'};
                    ssRed.parseStructFields(params,list,'params');
               
                    list = {'fact','stop','stopval','maxIter'};
                    parsedStruct.cure = ssRed.parseStructFields(params.cure,list,'params.cure');
               end
            elseif strcmp(method,'rkOp')
               list = {'originalOrder','sOpt','rk','lse'};
               parsedStruct = ssRed.parseStructFields(params,list,'params');  
            elseif strcmp(method,'rkIcop')
               list = {'originalOrder','sOpt','s0','rk','maxIter','tol','lse'};
               parsedStruct = ssRed.parseStructFields(params,list,'params'); 
            elseif strcmp(method,'userDefined')
               parsedStruct = params;
            end
        end
        
        function parsedParamsList   = removeReductionMethod(paramsList,method)
        %Removes the reductionParameters for the specified reduction method
        %"method" from the reduction history. This is i.e. necessary for
        %"rk", because in the algorithm projectiveMor is used. This
        %function then deletes "projectiveMor" from the reduction history, 
        %because "projectiveMor" performs just the projection in "rk", but 
        %is not a standalone reduction algorithm    
            
            parsedParamsList = paramsList;
            if size(paramsList,1) > 1
                if strcmp(paramsList{end-1}.method,method)
                     parsedParamsList{end-1} = [];
                     parsedParamsList = parsedParamsList(~cellfun('isempty',parsedParamsList));
                end
            end 
        end
        
        function parsedParamsList   = removeCureParameters(paramsList)
        %The parameters under the field "cure" stay the same for all cure
        %iterations. Because of this, the field "cure" is only stored for
        %the first iteration step. Therefore, this function removes all the
        %redundant cure paramters from the reduction history
            
            parsedParamsList = paramsList;
        
            for i = 2:length(paramsList)
                if ismember(paramsList{i-1}.method,{'cure_spark','cure_irka','cure_rk+pork'}) && ...
                   isfield(paramsList{i}.params,'cure')
                    parsedParamsList{i}.params = rmfield(parsedParamsList{i}.params,'cure');
                end
            end
        end
        
        function outputStruct       = parseStructFields(structure,fields,structName)
        %This function checks if the the struct "structure" contains all fields
        %specified in the cell-array "fields". If the case, all the values 
        %of the fields of the struct "structure" are copied to the struct 
        %"outputStruct". The variable "structName" is used in the error
        %message to inform the user which field caused the error.
             
            for i = 1:length(fields)
               if ~isfield(structure,fields{i})
                  error(strcat('Struct "',structName, ...
                      '" does not contain the field "',fields{i},'"!'));
               else
                  outputStruct.(fields{i}) = structure.(fields{i});
               end
            end                   
        end
        
    end    
end

