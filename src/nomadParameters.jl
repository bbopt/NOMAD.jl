"""

    nomadParameters

mutable struct containing the options of the optimization
process.

# **Constructors** :

- Classic constructor :

    `p1 = nomadParameters(x0::AbstractVector,output_types::Vector{String})`

- Copy constructor (deepcopy):

    `p1 = nomadParameters(p2)`

# **Attributes** :

- `x0::AbstractVector` :
Initialization point for NOMAD. Needs to be
of dimension n<=1000.
It can be either a unique *Vector{Number}*
to provide only one initial point or a vector of
several *Vector{Number}* to provide several initial
points.
No default value, needs to be set.

- `output_types::Vector{String}` :
A vector containing *String* objects that define the
types of outputs returned by `eval` (the order is important) :

String              | Output type |
:-------------------|:------------|
`"OBJ"`             | objective value to be minimized |
`"PB"` or `"CSTR"`  | progressive barrier constraint |
`"EB"`              | extreme barrier constraint |
`"F"`               | filter approach constraint |
`"PEB"`             | hybrid constraint EB/PB |
`"STAT_AVG"`        | Average of this value will be computed for all blackbox calls (must be unique) |
`"STAT_SUM"`        | Sum of this value will be computed for all blackbox calls (must be unique) |
`"NOTHING"` or `"-"`| The output is ignored |

Please note that F constraints are not compatible with CSTR, PB or PEB.
However, EB can be combined with F, CSTR, PB or PEB.
No default value, needs to be set.

- `lower_bound::Vector{Number}` :
Lower bound for each coordinate of the state.
If empty, no bound is taken into account.
`[]` by default.

- `upper_bound::Vector{Number}` :
Upper bound for each coordinate of the state.
If empty, no bound is taken into account.
`[]` by default.

- `display_all_eval::Bool` :
If false, only evaluations that allow to improve the
current state are displayed.
`false` by default.

- `display_stats::String` :
*String* defining the way outputs are displayed (it should
not contain any quotes). Here are examples of keywords
that can be used :

Keyword     | Display |
:-----------|:--------|
`bbe`       | black box evaluations |
`obj`       | objective function value |
`sol`       | solution |
`bbo`       | black box outputs |
`mesh_index`| mesh index parameter |
`mesh_size` | mesh size parameter |
`cons_h`    | Infeasibility |
`poll_size` | Poll size parameter |
`sgte`      | Number of surrogate evaluations |
`stat_avg`  | AVG statistic defined in output types |
`stat_sum`  | SUM statistic defined in output types |
`time`      | Wall-clock time |

`"bbe ( sol ) obj"` by default.

- `display_degree::Int` :
Integer between 0 and 3 that sets the level of display.
`2` by default.

- `max_bb_eval::Int` :
Maximum of calls to eval allowed. if equal to
zero, no maximum is taken into account.
`0` by default.

- `max_time::Int` :
maximum wall-clock time (in seconds). if equal
to zero, no maximum is taken into account.
`0` by default.

- `output_types::Vector{String}` :
A vector containing *String* objects that define the
types of inputs to be given to eval (the order is important) :

String  | Input type |
:-------|:-----------|
`"R"`   | Real/Continuous |
`"B"`   | Binary |
`"I"`   | Integer |

all R by default.

-`sgte_cost::Int` :
number of surrogate evaluations costing as much as one black box evaluation.
If set to 0, a surrogate evaluation is considered as free.
0 by default.

- `LH_init::Int` :
number of initial search points performed with Latin-Hypercube method
0 by default.

- `LH_iter::Int` :
number of search points performed at each iteration with Latin-Hypercube method
0 by default.

- `VNS_search::Bool` :
The Variable Neighborhood Search (VNS) is a strategy to escape local minima.
It is based on the Variable Neighborhood Search metaheuristic.
VNS should only be used for problems with several such local optima. It will cost some additional
evaluations, since each search performs another MADS run from a perturbed starting point.
Though, it will be a lot cheaper if a surrogate is provided.
`false` by default

- `granularity::Vector{Float}` :
The granularity of input variables, that is to say the minimum variation
authorized for these variables. A granularity of 0 corresponds to a real
variable.
by default, `0` for real variables, `1` for integer and binary ones.

- `stop_if_feasible::Bool` :
If set to true, NOMAD terminates when it generates a first feasible solution.
`false` by default.

- `stat_sum_target::Number` :
NOMAD terminates if STAT_SUM reaches this value.
`Inf` by default.

"""
mutable struct nomadParameters

    dimension::Int64
    x0::AbstractVector
    input_types::Vector{String}
    output_types::Vector{String}
    lower_bound::Vector{Float64}
    upper_bound::Vector{Float64}
    display_all_eval::Bool
    display_stats::String
    display_degree::Int64
    max_bb_eval::Int64
    max_time::Int64
    LH_init::Int64
    LH_iter::Int64
    sgte_cost::Int64
    granularity::Vector{Float64}
    stop_if_feasible::Bool
    VNS_search::Bool
    stat_sum_target::Float64

    function nomadParameters(xZero::AbstractVector,outputTypes::Vector{String})
        if typeof(xZero[1])<:AbstractVector
            dimension=length(xZero[1])
        else
            dimension=length(xZero)
        end
        input_types=[]
        output_types=outputTypes
        lower_bound=[]
        upper_bound=[]
        display_all_eval=false
        display_stats="bbe ( sol ) obj"
        display_degree=2
        max_bb_eval=0
        max_time=0
        LH_init=0
        LH_iter=0
        sgte_cost=0
        granularity=zeros(Float64,dimension)
        stop_if_feasible=false
        VNS_search=false
        stat_sum_target=Inf
        new(dimension,xZero,input_types,output_types,lower_bound,upper_bound,display_all_eval,
        display_stats,display_degree,max_bb_eval,max_time,LH_init,LH_iter,sgte_cost,granularity,
        stop_if_feasible,VNS_search,stat_sum_target)
    end

    #copy constructor
    function nomadParameters(p::nomadParameters)
        new(p.dimension,copy(p.x0),copy(p.input_types),copy(p.output_types),copy(p.lower_bound),copy(p.upper_bound),
        p.display_all_eval, p.display_stats,p.display_degree,p.max_bb_eval,p.max_time,p.LH_init,p.LH_iter,p.sgte_cost,
        copy(p.granularity),p.stop_if_feasible,p.VNS_search,p.stat_sum_target)
    end
end
