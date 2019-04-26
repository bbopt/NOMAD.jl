"""

    parameters

mutable struct containing the options of the optimization
process.

At least the attributes `dimension`, `output_types` and
`x0` need to be set before calling `runopt`.

The attributes of this Julia type correspond to those of the
NOMAD class `NOMAD::Parameters`. Hence, to get more information
about setting parameters in NOMAD.jl, you can refer to the
NOMAD documentation.

# **Constructors** :

- Classic constructor :

    `p1 = parameters()`

- Copy constructor :

    `p1 = parameters(p2)`

# **Attributes** :

- `dimension::Int64` :
Number of variables (n<=1000).
No default value, needs to be set.

- `x0::Vector{Float}` :
Initialization point for NOMAD. Its size needs to
be equal to dimension.
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

"""
mutable struct parameters

    dimension::Int64
    x0::Vector{Float64}
    input_types::Vector{String}
    output_types::Vector{String}
    lower_bound::Vector{Float64}
    upper_bound::Vector{Float64}
    display_all_eval::Bool
    display_stats::String
    display_degree::Int64
    max_bb_eval::Int64
    max_time::Int64

    function parameters()
        dimension=0
        x0=[]
        input_types=[]
        output_types=[]
        lower_bound=[]
        upper_bound=[]
        display_all_eval=false
        display_stats="bbe ( sol ) obj"
        display_degree=2
        max_bb_eval=0
        max_time=0
        new(dimension,x0,input_types,output_types,lower_bound,upper_bound,display_all_eval,
        display_stats,display_degree,max_bb_eval,max_time)
    end

    #copy constructor
    function parameters(p::parameters)
        new(p.dimension,copy(p.x0),copy(p.input_types),copy(p.output_types),copy(p.lower_bound),copy(p.upper_bound),
        p.display_all_eval, p.display_stats,p.display_degree,p.max_bb_eval,p.max_time)
    end
end
