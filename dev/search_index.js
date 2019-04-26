var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#Home-1",
    "page": "Home",
    "title": "NOMAD.jl documentation",
    "category": "section",
    "text": "This package provides a Julia interface for NOMAD, which is a C++ implementation of the Mesh Adaptive Direct Search algorithm (MADS), designed for difficult blackbox optimization problems. These problems occur when the functions defining the objective and constraints are the result of costly computer simulations."
},

{
    "location": "#Type-of-problems-treated-1",
    "page": "Home",
    "title": "Type of problems treated",
    "category": "section",
    "text": "NOMAD allows to deal with optimization problems of the form :beginalign*\nmin quad  f(x) \n c_i(x) leq 0 quad i in I \n ell leq x leq u\nendalign*where fmathbbR^nrightarrowmathbbR, cmathbbR^nrightarrowmathbbR^m, I = 12dotsm, and ell_j u_j in mathbbRcuppminfty for i = 1dotsm.The functions f and c_i are typically blackbox functions whose evaluations require computer simulation."
},

{
    "location": "#Quick-start-1",
    "page": "Home",
    "title": "Quick start",
    "category": "section",
    "text": "You first need to declare a function eval(x::Vector{Float64}) that returns a boolean and a Vector{Float64} that contains the objective function and constraints evaluated for x.function eval(x)\n    f=x[1]^2+x[2]^2\n    c=1-x[1]\n    count_eval=true\n    bb_outputs = [f,c]\n    return (count_eval,bb_outputs)\nendThe boolean count_eval defines whether the evaluation needs to be taken into account by NOMAD. Here, it is always equal to true so every evaluation will be considered.Then create an object of type parameters that will contain options for the optimization. You need to define at least the dimension of the problem, the initial point x0 and the types of the outputs contained in bb_outputs.param = parameters()\nparam.dimension = 2\nparam.output_types = [\"OBJ\",\"EB\"]\nparam.x0 = [3,3]Here, first element of bb_outputs is the objective function (f), second is a constraint treated with the Extreme Barrier method (c).Now call the function runopt with these arguments to launch a NOMAD optimization process.result = runopt(eval,param)The object of type results returned by runopt contains information about the run."
},

{
    "location": "parameters/#",
    "page": "Parameters",
    "title": "Parameters",
    "category": "page",
    "text": ""
},

{
    "location": "parameters/#NOMAD.parameters",
    "page": "Parameters",
    "title": "NOMAD.parameters",
    "category": "type",
    "text": "parameters\n\nmutable struct containing the options of the optimization process.\n\nAt least the attributes dimension, output_types and x0 need to be set before calling runopt.\n\nThe attributes of this Julia type correspond to those of the NOMAD class NOMAD::Parameters. Hence, to get more information about setting parameters in NOMAD.jl, you can refer to the NOMAD documentation.\n\nConstructors :\n\nClassic constructor :\np1 = parameters()\nCopy constructor :\np1 = parameters(p2)\n\nAttributes :\n\ndimension::Int64 :\n\nNumber of variables (n<=1000). No default value, needs to be set.\n\nx0::Vector{Float} :\n\nInitialization point for NOMAD. Its size needs to be equal to dimension. No default value, needs to be set.\n\noutput_types::Vector{String} :\n\nA vector containing String objects that define the types of outputs returned by eval (the order is important) :\n\nString Output type\n\"OBJ\" objective value to be minimized\n\"PB\" or \"CSTR\" progressive barrier constraint\n\"EB\" extreme barrier constraint\n\"F\" filter approach constraint\n\"PEB\" hybrid constraint EB/PB\n\"STAT_AVG\" Average of this value will be computed for all blackbox calls (must be unique)\n\"STAT_SUM\" Sum of this value will be computed for all blackbox calls (must be unique)\n\"NOTHING\" or \"-\" The output is ignored\n\nPlease note that F constraints are not compatible with CSTR, PB or PEB. However, EB can be combined with F, CSTR, PB or PEB. No default value, needs to be set.\n\nlower_bound::Vector{Number} :\n\nLower bound for each coordinate of the state. If empty, no bound is taken into account. [] by default.\n\nupper_bound::Vector{Number} :\n\nUpper bound for each coordinate of the state. If empty, no bound is taken into account. [] by default.\n\ndisplay_all_eval::Bool :\n\nIf false, only evaluations that allow to improve the current state are displayed. false by default.\n\ndisplay_stats::String :\n\nString defining the way outputs are displayed (it should not contain any quotes). Here are examples of keywords that can be used :\n\nKeyword Display\nbbe black box evaluations\nobj objective function value\nsol solution\nbbo black box outputs\nmesh_index mesh index parameter\nmesh_size mesh size parameter\ncons_h Infeasibility\npoll_size Poll size parameter\nsgte Number of surrogate evaluations\nstat_avg AVG statistic defined in output types\nstat_sum SUM statistic defined in output types\ntime Wall-clock time\n\n\"bbe ( sol ) obj\" by default.\n\ndisplay_degree::Int :\n\nInteger between 0 and 3 that sets the level of display. 2 by default.\n\nmax_bb_eval::Int :\n\nMaximum of calls to eval allowed. if equal to zero, no maximum is taken into account. 0 by default.\n\nmax_time::Int :\n\nmaximum wall-clock time (in seconds). if equal to zero, no maximum is taken into account. 0 by default.\n\noutput_types::Vector{String} :\n\nA vector containing String objects that define the types of inputs to be given to eval (the order is important) :\n\nString Input type\n\"R\" Real/Continuous\n\"B\" Binary\n\"I\" Integer\n\nall R by default.\n\n\n\n\n\n"
},

{
    "location": "parameters/#Parameters-setting-1",
    "page": "Parameters",
    "title": "Parameters setting",
    "category": "section",
    "text": "The settings of a NOMAD optimization process must be entered in an object of the type described below.parameters"
},

{
    "location": "runopt/#",
    "page": "Run Optimization",
    "title": "Run Optimization",
    "category": "page",
    "text": ""
},

{
    "location": "runopt/#NOMAD.runopt-Tuple{Function,parameters}",
    "page": "Run Optimization",
    "title": "NOMAD.runopt",
    "category": "method",
    "text": "runopt(eval::Function,param::parameters)\n\n-> Run NOMAD with settings defined by param and an optimization problem defined by eval(x).\n\n-> Display stats from NOMAD in the REPL.\n\n-> return an object of type results that contains info about the run.\n\nArguments :\n\neval::Function\n\na function of the form :\n\n(count_eval,bb_outputs)=eval(x::Vector{Float64})\n\nbb_outputs being a vector{Float64} containing the values of objective function and constraints for a given input vector x. NOMAD will seak for minimizing the objective function and keeping constraints inferior to 0. count_eval is a Bool equal to true if the evaluation has to be taken into account by NOMAD.\n\nparam::parameters\n\nAn object of type Parameters of which the attributes are the settings of the optimization process (dimension, output types, display options, bounds, etc.).\n\nExample :\n\nusing NOMAD\n\nfunction eval(x)\n    f=x[1]^2+x[2]^2\n    c=1-x[1]\n    count_eval=true\n	bb_outputs = [f,c]\n    return (count_eval,bb_outputs)\nend\n\nparam = parameters()\nparam.dimension = 2\nparam.output_types = [\"OBJ\",\"EB\"] #=first element of bb_outputs is the\n	objective function, second is a constraint treated with the Extreme\n	Barrier method=#\nparam.x0 = [3,3] #Initial state for the optimization process\n\nresult = runopt(eval,param)\n\n\n\n\n\n"
},

{
    "location": "runopt/#Run-the-optimization-1",
    "page": "Run Optimization",
    "title": "Run the optimization",
    "category": "section",
    "text": "A NOMAD optimization process can be run by using the runopt method described below.runopt(eval::Function,param::parameters)"
},

{
    "location": "results/#",
    "page": "Results",
    "title": "Results",
    "category": "page",
    "text": ""
},

{
    "location": "results/#NOMAD.results",
    "page": "Results",
    "title": "NOMAD.results",
    "category": "type",
    "text": "results\n\nmutable struct containing info about a NOMAD run, returned by the method runopt(eval,param).\n\nTo display the info contained in a object result, use :\n\ndisp(result)\n\nAttributes :\n\nbest_feasible::Vector{Float64} :\n\nFeasible point found by NOMAD that best minimizes the objective function.\n\nbbo_best_feasible::Vector{Float64} :\n\nOutputs of eval(x) for the best feasible point.\n\nbest_infeasible::Vector{Float64} :\n\nInfeasible point found by NOMAD that best minimizes the objective function.\n\nbbo_best_infeasible::Vector{Float64} :\n\noutputs of eval(x) for the best infeasible point.\n\nbb_eval::Int64 :\n\nNumber of eval(x) evaluations\n\n\n\n\n\n"
},

{
    "location": "results/#Results-1",
    "page": "Results",
    "title": "Results",
    "category": "section",
    "text": "Main results from a NOMAD optimization process are stored in an object of the type described below.results"
},

]}
