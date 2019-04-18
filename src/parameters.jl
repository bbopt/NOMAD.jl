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
Dimension of the problem and size of the argument given
to `eval`.
No default value, needs to be set.

- `output_types::Vector{String}` :
A vector containing *String* objects that define the
types of outputs returned by `eval` (the order is important) :

String      | Output type
------------|-------------------------------
`"OBJ"`     | objective value to be minimized
`"EB"`      | extreme barrier constraint
`"PB"`      | progressive barrier constraint
`"F"`       | filter approach constraint
`"PEB"`     | hybrid constraint EB/PB

For more output types, please refer to the NOMAD documentation.
No default value, needs to be set.

- `x0::Vector{Float}` :
Initialization point for NOMAD. Its size needs to
be equal to dimension.
No default value, needs to be set.

- `display_all_eval::Bool` :
If false, only evaluations that allow to improve the
current state are displayed.
`false` by default.

- `display_stats::String` :
*String* defining the way outputs are displayed (it should
not contain any quotes). Here are examples of keywords
that can be used :

Keyword     | Display
------------|-------------------------------
`bbe`       | black box evaluations
`obj`       | objective function value
`sol`       | solution
`bbo`       | black box outputs
`mesh_index`| mesh index parameter
`mesh_size` | mesh size parameter

For more keywords, please refer to the NOMAD documentation.
`"bbe ( sol ) obj"` by default.

- `lower_bound::Vector{Number}` :
Lower bound for each coordinate of the state.
If empty, no bound is taken into account.
`[]` by default.

- `upper_bound::Vector{Number}` :
Upper bound for each coordinate of the state.
If empty, no bound is taken into account.
`[]` by default.

- `max_bb_eval::Int` :
Maximum of calls to eval allowed. if equal to
zero, no maximum is taken into account.
`0` by default.

- `display_degree::Int` :
Integer between 0 and 3 that sets the level of display.
`2` by default.

- `solution_file::String` :
Name of the generated output file containing the
returned minimum.
`"sol.txt"` by default.

"""
mutable struct parameters

    dimension::Int64
    output_types::Vector{String}
    display_all_eval::Bool
    display_stats::String
    x0::Vector{Float64}
    lower_bound::Vector{Float64}
    upper_bound::Vector{Float64}
    max_bb_eval::Int64
    display_degree::Int64
    solution_file::String

    function parameters()
        dimension=0
        output_types=[]
        display_all_eval=false
        display_stats="bbe ( sol ) obj"
        x0=[]
        lower_bound=[]
        upper_bound=[]
        max_bb_eval=0
        display_degree=2
        solution_file="sol.txt"
        reset=true
        new(dimension,output_types,display_all_eval,display_stats,x0,
        lower_bound,upper_bound,max_bb_eval,display_degree,solution_file)
    end

    #copy constructor
    function parameters(p::parameters)
        new(p.dimension,p.output_types,p.display_all_eval, p.display_stats,
        p.x0,p.lower_bound,p.upper_bound, p.max_bb_eval,p.display_degree,
        p.solution_file)
    end
end
