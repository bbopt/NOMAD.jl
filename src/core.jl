export NomadProblem, solve

######################################################
#                NOMAD Main types                    #
######################################################
const BBInputTypes = ["R" # Real
                      "I" # Integer
                      "B" # Binary
                     ]

const BBOutputTypes = ["OBJ" # objective type
                       "EB"  # extreme barrier constraint
                       "PB"  # progressive barrier constraint
                      ]

const BBLinearConverterTypes = ["QR" # QR Linear converter
                                "SVD" # SVD Linear converter
                               ]

const DisplayStatsInputs = ["BBE" # Blackbox evaluations
                            "BBO" # Blackbox outputs
                            "CACHE_HITS" # Cache hits
                            "CACHE_SIZE" # Cache size
                            "CONS_H" # Constraint barrier value
                            "EVAL" # Evaluations (include cache hits)
                            "FEAS_BBE" # Feasible evaluations
                            "GEN_STEP" # Name of the step that generated point to evaluate
                            "H_MAX"   # max infeasibility (h) acceptable
                            "INF_BBE" # infeasible blackbox evaluations
                            "ITER_NUM" # iteration number in which this evaluation was done
                            "MESH_INDEX" # mesh index
                            "OBJ" # objective function value
                            "PHASE_ONE_SUCC" # success evaluations during phase one phase
                            "SGTE" # number of surrogate evaluations since last reset
                            "SOL"  # current feasible iterate
                            "SUCCESS_TYPE" # success type for thisevaluation, compared with the frame center
                            "TIME"       # real time in seconds
                            "TOTAL_SGTE" # total number of surrogate evaluations
                            ]

const DirectionTypes = ["ORTHO 2N" # 2n directions, no quadratic models
                        "ORTHO N+1 NEG" # n directions, the (n+1)th is the negative sum of the n first.
                        "ORTHO N+1 QUAD" # n directions, the (n+1)th is found by solving a quadratic subproblem
                        "ORTHO N+1 QUAD" # n directions, the (n+1)th is found by solving a quadratic subproblem
                        "N+1 UNI" # n+1 uniformly distributed directions
                        "SINGLE" # one direction
                        "DOUBLE" # two opposed direction
                        ]

const EvalSortTypes = ["DIR_LAST_SUCCESS" # Sort according to direction of last success
                       "LEXICOGRAPHICAL" # Sort using lexicographic ordering
                       "RANDOM" # Do not sort
                       "QUADRATIC_MODEL" # Sort using quadratic models
                       ]

mutable struct NomadOptions

    # cache options
    cache_size_max::Int

    # display options
    display_degree::Int # display degree: between 0 and 3
    display_all_eval::Bool # display all evaluations
    display_infeasible::Bool # display infeasible
    display_unsuccessful::Bool # display unsuccessful
    display_stats::Vector{String} # display_stats

    # eval options
    max_bb_eval::Int # maximum number of evaluations allowed
    sgtelib_model_max_eval::Int # sgtelib model maximum number of evaluations
    eval_opportunistic::Bool
    eval_use_cache::Bool
    eval_queue_sort::String

    # run options
    # Barrier options
    h_max_0::Float64

    # Direction options # TODO for the moment, do not allow several executions of polls
    direction_type::String
    direction_type_secondary_poll::String

    # Mesh options
    anisotropic_mesh::Bool
    anisotropy_factor::Float64

    # Search options
    # LH search options
    lh_search::Tuple{Int, Int} # lh_search_init, lh_search_iter

    # Quad model search options
    quad_model_search::Bool

    # Sgtelib model search options
    sgtelib_model_search::Bool

    # Speculative search options
    speculative_search::Bool
    speculative_search_base_factor::Float64
    speculative_search_max::Int

    # NM search options
    nm_search::Bool
    nm_delta_e::Float64 # Expansion
    nm_delta_ic::Float64 # Inside contraction
    nm_delta_oc::Float64 # Outside contraction
    nm_gamma::Float64 # Shrink parameter
    nm_search_rank_eps::Float64
    nm_search_max_trial_pts_nfactor::Int
    nm_search_stop_on_success::Bool

    # VNS search options
    vns_mads_search::Bool
    vns_mads_search_max_trial_pts_nfactor::Int
    vns_mads_search_trigger::Float64

    stop_if_feasible::Bool
    max_time::Union{Nothing, Int}

    # linear constrained optimization options
    linear_converter::String
    linear_constraints_atol::Float64

    seed::Union{Int, Nothing}
    function NomadOptions(;
                          cache_size_max::Int = typemax(Int64),
                          display_degree::Int = 2,
                          display_all_eval::Bool = false,
                          display_infeasible::Bool = false,
                          display_unsuccessful::Bool = false,
                          display_stats::Vector{String} = String[],
                          max_bb_eval::Int = 20000,
                          sgtelib_model_max_eval::Int=1000,
                          eval_opportunistic::Bool=true,
                          eval_use_cache::Bool=true,
                          eval_queue_sort::String = "QUADRATIC_MODEL",
                          h_max_0::Float64=Inf,
                          direction_type::String = "",
                          direction_type_secondary_poll::String = "",
                          anisotropic_mesh::Bool=true,
                          anisotropy_factor::Float64=0.1,
                          lh_search::Tuple{Int, Int} =(0,0),
                          quad_model_search::Bool=true,
                          sgtelib_model_search::Bool=false,
                          speculative_search::Bool = true,
                          speculative_search_base_factor::Float64 = 4.0,
                          speculative_search_max::Int = 1,
                          nm_search::Bool=true,
                          nm_delta_e::Float64 = 2.0,
                          nm_delta_ic::Float64 = -0.5,
                          nm_delta_oc::Float64 = 0.5,
                          nm_gamma::Float64 = 0.5,
                          nm_search_rank_eps::Float64 = 0.01,
                          nm_search_max_trial_pts_nfactor::Int = 80,
                          nm_search_stop_on_success::Bool=false,
                          vns_mads_search::Bool=false,
                          vns_mads_search_max_trial_pts_nfactor::Int=100,
                          vns_mads_search_trigger::Float64 = 0.75,
                          stop_if_feasible::Bool=false,
                          max_time::Union{Nothing, Int}=nothing,
                          linear_converter::String="SVD",
                          linear_constraints_atol::Float64=0.0,
                          seed=nothing)
        return new(cache_size_max,
                   display_degree,
                   display_all_eval,
                   display_infeasible,
                   display_unsuccessful,
                   display_stats,
                   max_bb_eval,
                   sgtelib_model_max_eval,
                   eval_opportunistic,
                   eval_use_cache,
                   eval_queue_sort,
                   h_max_0,
                   direction_type,
                   direction_type_secondary_poll,
                   anisotropic_mesh,
                   anisotropy_factor,
                   lh_search,
                   quad_model_search,
                   sgtelib_model_search,
                   speculative_search,
                   speculative_search_base_factor,
                   speculative_search_max,
                   nm_search,
                   nm_delta_e,
                   nm_delta_ic,
                   nm_delta_oc,
                   nm_gamma,
                   nm_search_rank_eps,
                   nm_search_max_trial_pts_nfactor,
                   nm_search_stop_on_success,
                   vns_mads_search,
                   vns_mads_search_max_trial_pts_nfactor,
                   vns_mads_search_trigger,
                   stop_if_feasible,
                   max_time,
                   linear_converter,
                   linear_constraints_atol,
                   seed)
    end
end

function check_options(options::NomadOptions)
    (0 < options.cache_size_max) ? nothing : error("NOMAD.jl error: max_cache_size must be strictly positive")
    (0 <= options.display_degree <= 3) ? nothing : error("NOMAD.jl error: display_degree must be comprised between 0 and 3")
    if !isempty(options.display_stats)
        for elt in options.display_stats
            if !(elt in DisplayStatsInputs)
                error("NOMAD.jl error: $(elt) is not a valid parameter for display_stats: see the documentation.")
            end
        end
    end
    (options.max_bb_eval > 0) || error("NOMAD.jl error: wrong parameters, max_bb_eval must be strictly positive")
    (options.eval_queue_sort ∈ EvalSortTypes) || error("NOMAD.jl error: wrong parameters, eval_queue_sort must belong to EvalSortTypes, i.e. $(EvalSortTypes)")
    (options.sgtelib_model_max_eval > 0) || error("NOMAD.jl error: wrong parameters, sgtelib_model_max_eval must be strictly positive")
    (options.h_max_0 > 0) || error("NOMAD.jl error: wrong parameters, h_max_0 must be strictly positive")
    (isempty(options.direction_type) || options.direction_type ∈ DirectionTypes) || error("NOMAD.jl error: wrong parameters, direction_type is either empty, or must belong to DirectionTypes, i.e. $(DirectionTypes)")
    (isempty(options.direction_type_secondary_poll) || options.direction_type_secondary_poll ∈ DirectionTypes) || error("NOMAD.jl error: wrong parameters, direction_type_secondary_poll is either empty, or must belong to DirectionTypes, i.e. $(DirectionTypes)")
    (options.anisotropy_factor > 0) || error("NOMAD.jl error: wrong parameters, anisotropy_factor must be strictly positive")
    (options.lh_search[1] >= 0 && options.lh_search[2] >=0) || error("NOMAD.jl error: the lh_search parameters must be positive or null")
    (options.speculative_search_base_factor > 1) || error("NOMAD.jl error: wrong parameters, speculative_search_base_factor must be > 1")
    (options.speculative_search_max >= 0) || error("NOMAD.jl error: wrong parameters, speculative_search_max must be positive")
    (options.nm_delta_e > 1) || error("NOMAD.jl error: wrong parameters, nm_delta_e must belong to ]1, + ∞[")
    (-1 < options.nm_delta_ic < 0) || error("NOMAD.jl error: wrong parameters, nm_delta_ic must belong to ]-1, 0[")
    (0 < options.nm_delta_oc < 1) || error("NOMAD.jl error: wrong parameters, nm_delta_oc must belong to ]0, 1[")
    (0 < options.nm_gamma < 1) || error("NOMAD.jl error: wrong parameters, nm_gamma must belong to ]0, 1[")
    (0 < options.nm_search_rank_eps) || error("NOMAD.jl error: wrong parameters, nm_search_rank_eps must be positive")
    (0 < options.nm_search_max_trial_pts_nfactor) || error("NOMAD.jl error: wrong parameters, nm_search_max_trial_pts_nfactor must be positive")
    (options.vns_mads_search_max_trial_pts_nfactor >= 0) || error("NOMAD.jl error: wrong parameters, vns_mads_search_max_trial_pts_nfactor must be positive")
    (0 <= options.vns_mads_search_trigger <= 1) || error("NOMAD.jl error: wrong parameters, vns_mads_search_trigger is a ratio which must be comprised between 0 and 1")
    (!isnothing(options.max_time) && options.max_time > 0) || (isnothing(options.max_time)) || error("NOMAD.jl error: wrong parameters, max_time must be strictly positive if defined")
    (options.linear_converter in BBLinearConverterTypes) || error("NOMAD.jl error: the linear_converter type is not defined")
    (options.linear_constraints_atol >= 0) || error("NOMAD.jl error: the linear_constraints_atol parameter must be positive or null")
end

"""
    NomadProblem(nb_inputs::Int, nb_outputs::Int, output_types::Vector{String}, eval_bb::Function;
                 input_types::Vector{String} = ["R" for i in 1:nb_inputs],
                 granularity::Vector{Float64} = zeros(Float64, nb_inputs),
                 lower_bound::Vector{Float64} = -Inf * ones(Float64, nb_inputs),
                 upper_bound::Vector{Float64} = Inf * ones(Float64, nb_inputs),
                 A::Union{Nothing, Matrix{Float64}} = nothing,
                 b::Union{Nothing, Vector{Float64}} = nothing,
                 min_mesh_size::Vector{Float64} = zeros(Float64, nb_inputs),
                 b::Union{Nothing, Vector{Float64}} = nothing,
                 initial_mesh_size::Vector{Float64} = Float64[])

Struct containing the main information needed to solve a blackbox problem by the Nomad Software.

# **Attributes**:

- `nb_inputs::Int`:
Number of inputs of the blackbox. Is required to be > 0.

No default, needs to be set.

- `nb_outputs::Int`:
Number of outputs of the blackbox. Is required to be > 0.

No default, needs to be set.

- `output_types::Vector{String}`:
A vector containing *String* objects that define the
types of outputs returned by `eval_bb` (the order is important) :

String              | Output type |
 :------------------|:------------|
`"OBJ"`             | objective value to be minimized |
`"PB"`              | progressive barrier constraint |
`"EB"`              | extreme barrier constraint |
No default value, needs to be set.

- `eval_bb::Function`:
A function of the form :
```julia
    (success, count_eval, bb_outputs) = eval(x::Vector{Float64})
```
`bb_outputs` being a `Vector{Float64}` containing
the values of objective function and constraints
for a given input vector `x`. NOMAD will seek to
minimize the objective function and keeping
constraints inferior to 0.

`success` is a *Bool* set to `false` if the evaluation failed.

`count_eval` is a *Bool* equal to `true` if the blackbox
evaluation counting has to be incremented.

- `input_types::Vector{String}`:
A vector containing `String` objects that define the
types of inputs to be given to eval_bb (the order is important) :

|String  | Input type      |
|:------ |:--------------- |
|`"R"`   | Real/Continuous |
|`"B"`   | Binary          |
|`"I"`   | Integer         |
all R by default.

- `granularity::Vector{Float64}`:
The granularity of input variables, that is to say the minimum variation
authorized for these variables. A granularity of 0 corresponds to a real
variable.

By default, `0` for real variables, `1` for integer and binary ones.

- `min_mesh_size::Vector{Float64}`:
The minimum mesh size to reach allowed by each input variable. When a
variable decreases below the threshold, the algorithm stops.

By default, `0` (which corresponds to the Nomad software tolerance).

- `initial_mesh_size::Vector{Float64}`:
The initial mesh size set for each input variable. Can be adjusted if the
granularity is set.

Empty by default.

- `lower_bound::Vector{Float64}`:
Lower bound for each coordinate of the blackbox input.
`-Inf * ones(Float64, nb_inputs)`, by default.

- `upper_bound::Vector{Float64}`:
Upper bound for each coordinate of the blackbox input.

`Inf * ones(Float64, nb_inputs)`, by default.

- `A::Union{Nothing, Matrix{Float64}}`:
Matrix A in the potential equality constraints Ax = b, where x are the inputs
of the blackbox. A must have more columns than lines. If defined, the granularity
parameters should be set to default value, i.e. 0.

`nothing`, by default.

- `b::Union{Nothing, Vector{Float64}}`:
Vector b in the potential equality constraints Ax=b, where x are the inputs
of the blackbox. b must be defined when A is defined. In this case, dimensions
must match.

`nothing`, by default.

- `options::NomadOptions`
Nomad options that can be set before running the optimization process.

-> `cache_size_max::Int`

Maximum number of points stored in the cache.

Inf` by default.

-> `display_degree::Int`:

Integer between 0 and 3 that sets the level of display.

-> `display_all_eval::Bool`:

If false, only evaluations that allow to improve the
current state are displayed.

`false` by default.

-> `display_infeasible::Bool`:

If true, display best infeasible values reached by Nomad
until the current step.

`false` by default.

-> `display_unsuccessful::Bool`:

If true, display evaluations that are unsuccessful.

`false` by default.

-> `display_stats::Bool`:

A vector containing `String` objects that define the
statistics to display when the algorithm is running.

|     String       | Display Statistics Arguments          |
|:---------------- |:------------------------------------- |
|`"BBE"`           | Blackbox evaluations                  |
|`"BBO"`           | Blackbox outputs                      |
|`"CACHE_HITS"`    | Cache hits                            |
|`"CACHE_SIZE"`    | Cache size                            |
|`"CONS_H"`        | Infeasibility (h) value               |
|`"EVAL"`          | Evaluations (includes cache hits)     |
|`"FEAS_BBE"`      | Feasible blackbox evaluations         |
|`"GEN_STEP"`      | Name of the step that generated       |
|                  | this point to evaluate                |
|`"H_MAX"`         | Max infeasibility (h) acceptable      |
|`"INF_BBE"`       | Infeasible blackbox evaluations       |
|`"ITER_NUM"`      | Iteration number in which this        |
|                  | evaluation was done                   |
|`"MESH_INDEX"`    | Mesh index                            |
|`"OBJ"`           | Objective function value              |
|`"PHASE_ONE_SUCC"`| Success evaluations during phase one  |
|                  | phase                                 |
|`"SGTE"`          | Number of surrogate evaluations since |
|                  | last reset                            |
|`"SOL"`           | Current feasible iterate (displayed   |
|                  | in ())                                |
|`"SUCCESS_TYPE"`  | Success type for this evaluation,     |
|                  | compared with the frame center        |
|`"TIME"`          | Real time in seconds                  |
|`"TOTAL_SGTE"`    | Total number of surrogate evaluations |

Empty by default.

-> `max_bb_eval::Int`:

Maximum of calls to eval_bb allowed. Must be positive.

`20000` by default.

-> `sgtelib_model_max_eval::Int`:

Maximum number of calls to surrogate models for each optimization of
surrogate problem allowed. Must be positive.

`1000` by default.

-> `eval_opportunistic::Bool`

If true, the algorithm performs an opportunistic strategy
at each iteration.

`true` by default.

-> `eval_use_cache::Bool`:

If true, the algorithm only evaluates one time a given input.
Avoids to recalculate a blackbox value if this last one has
already be computed.

`true` by default.

-> `eval_sort_type::String`:

Order points before evaluation according to one of the following
strategies

|     String          | Eval Sort strategy                         |
|:------------------- |:------------------------------------------ |
|`"DIR_LAST_SUCCESS"` | Use last success direction                 |
|`"LEXICOGRAPHICAL"`  | Use lexicographical ordering (coordinates) |
|`"RANDOM"`           | Do not sort                                |
|`"QUADRATIC_MODEL"`  | Use quadratic models                       |

`"QUADRATIC_MODEL"` by default.

-> `h_max_0::Float64`:

Initial value of the barrier threshold for progressive barrier (PB).
Must be positive.

`Inf` by default.

-> `direction_type::String`:

Direction type for Mads poll. The following direction types are
available

|     String        | Direction type                             |
|:----------------- |:------------------------------------------ |
|`"ORTHO 2N"`       | OrthoMads with 2n directions               |
|`"ORTHO N+1 NEG"`  | OrthoMads with n+1 directions. The (n+1)e  |
|                   | is the negative sum of the n first.        |
|`"ORTHO N+1 QUAD"` | OrthoMads with n+1 directions. The (n+1)e  |
|                   | is found by solving a quadratic subproblem |
| `"N+1 UNI"`       | n+1 uniform distribution of directions     |
| `"SINGLE"`        | Single direction                           |
| `"DOUBLE"`        | Two opposed directions                     |

Empty by default (the NOMAD software adopts a `"ORTHO N+1 QUAD"`
strategy by default).

-> `direction_type_secondary_poll::String`

Direction type for secondary Mads poll for the progressive barrier
(PB). The same direction types than `direction_type` are available.

Empty by default (by default, the NOMAD software adopts a `"DOUBLE"`
strategy if `direction_type` is set to `"ORTHO 2N"` or `"ORTHO N+1"`
or a `"SINGLE"` strategy otherwise).

-> `anisotropic_mesh::Bool`:

Use anisotropic mesh to generate directions for MADS.

`true` by default.

-> `anisotropy_factor::Float64`:

The MADS anisotropy factor for mesh size change. Must be strictly positive.

`0.1` by default.

-> `lh_search::Tuple{Int, Int}`:

LH search parameters.

`lh_search[1]` is the `lh_search_init` parameter, i.e.
the number of initial search points performed with Latin-Hypercube method.

`0` by default.

`lh_search[2]` is the  `lh_search_iter` parameter, i.e.
the number of search points performed at each iteration with Latin-Hypercube method.

`0` by default.

-> `quad_model_search::Bool`:

If true, the algorithm executes a quadratic model search strategy at each iteration.
Deactivated when the number of variables is greater than 50.

`true` by default.

-> `sgtelib_model_search::Bool`:

If true, the algorithm executes a model search strategy using Sgtelib at each iteration.
Deactivated when the number of variables is greater than 50.

`false` by default.

-> `speculative_search::Bool`:

If true, the algorithm executes a speculative search strategy at each iteration.

`true` by default.

-> `speculative_search_base_factor::Float64`:

The factor distance to the current incumbent for the MADS speculative search.
Must be strictly superior to 1.

`4.0` by default.

-> `speculative_search_max::Int`:

Number of points to generate using the Mads speculative search (when opportunistic
strategy). Must be positive.

`1` by default.

-> `nm_search::Bool`:

If true, the algorithm executes a Nelder-Mead search strategy at each iteration.

`true` by default.

-> `nm_delta_e::Float64`:

The expansion parameter of the Nelder-Mead search. Must be > 1.

`2.0` by default.

-> `nm_delta_ic::Float64`:

The inside contraction parameter of the Nelder-Mead search. Must be strictly comprised
between -1 and 0.

`-0.5` by default.

-> `nm_delta_oc::Float64`:

The outside contraction parameter of the Nelder-Mead search. Must be strictly comprised
between 0 and 1.

`0.5` by default.

-> `nm_gamma::Float64`:

The shrink parameter of the Nelder-Mead search. Must be strictly comprised
between 0 and 1.

`0.5` by default.

-> `nm_search_rank_eps::Float64`:

The tolerance parameter on the rank of the initial simplex built in the Nelder-Mead
search. Must be strictly positive.

`0.01` by default.

-> `nm_search_max_trial_pts_nfactor::Int`:

Nelder-Mead search stops when `nm_search_max_trial_pts_nfactor` * n evaluations
are reached, n being the number of variables of the problem.

`80` by default.

-> `nm_search_stop_on_success::Bool`:

If true, the nm_search strategy stops opportunistically (as soon as a better point
is found).

`false` by default.

-> `vns_mads_search::Bool`:

If true, the algorithm executes a Variable Neighbourhoold search strategy at each iteration.

`false` by default.

-> `vns_mads_search_max_trial_pts_nfactor::Int`:

The VNS strategy, when triggered, stops when this parameter is reached.

`100` by default.

-> `vns_mads_search_trigger::Float64`

Maximum desired ratio of VNS blackbox evaluations over the total number of blackbox evaluations.
When 0, the VNS search is never executed; when 1, a search is launched at each iteration.

`0.75` by default.

-> `stop_if_feasible::Bool`:

Stop algorithm as soon as a feasible solution is found.

`false` by default.

-> `max_time::Union{Nothing, Int}`:

If defined, maximum clock time (in seconds) execution of the algorithm.

`false` by default.

-> `linear_converter::String`:

The type of converter to deal with linear equality constraints. Can be `SVD` or
`QR`.

`SVD` by default.

-> `linear_constraints_atol::Float64`:

The tolerance accuracy that x0 must satisfy, when there are linear equality
constraints, i.e. A * x0 = b.

`0` by default.

"""
struct NomadProblem

    nb_inputs::Int # number of variables
    nb_outputs::Int # number of outputs

    input_types::Vector{String}
    granularity::Vector{Float64}
    min_mesh_size::Vector{Float64}
    initial_mesh_size::Vector{Float64}
    lower_bound::Vector{Float64}
    upper_bound::Vector{Float64}

    output_types::Vector{String}

    # optional matrix A
    A::Union{Nothing, Array{Float64, 2}}

    # optional vector b
    b::Union{Nothing, Vector{Float64}}

    # callback
    eval_bb::Function

    # parameters
    options::NomadOptions
    function NomadProblem(nb_inputs::Int,
        nb_outputs::Int,
        output_types::Vector{String},
        eval_bb::Function;
        input_types::Vector{String} = ["R" for i in 1:nb_inputs],
        granularity::Vector{Float64} = zeros(Float64, nb_inputs),
        lower_bound::Vector{Float64} = -Inf * ones(Float64, nb_inputs),
        upper_bound::Vector{Float64} = Inf * ones(Float64, nb_inputs),
        A::Union{Nothing, Matrix{Float64}} = nothing,
        b::Union{Nothing, Vector{Float64}} = nothing,
        min_mesh_size::Vector{Float64} = zeros(Float64, nb_inputs),
        initial_mesh_size::Vector{Float64} = Float64[],
        options=NomadOptions())

        @assert nb_inputs > 0 "NOMAD.jl error : wrong parameters, the number of inputs must be strictly positive"
        @assert nb_inputs == length(lower_bound) "NOMAD.jl error: wrong parameters, lower bound is not consistent with the number of inputs"
        @assert nb_inputs == length(upper_bound) "NOMAD.jl error: wrong parameters, upper bound is not consistent with the number of inputs"
        @assert nb_inputs == length(input_types) "NOMAD.jl error: wrong parameters, input types is not consistent with the number of inputs"
        @assert nb_inputs == length(granularity) "NOMAD.jl error: wrong parameters, granularity is not consistent with the number of inputs"
        @assert nb_inputs == length(min_mesh_size) "NOMAD.jl error: wrong parameters, min_mesh_size is not consistent with the number of inputs"
        if !isempty(initial_mesh_size)
            @assert nb_inputs == length(initial_mesh_size) "NOMAD.jl error: wrong parameters, initial_mesh_size is not consistent with the number of inputs"
        end

        @assert nb_outputs > 0 "NOMAD.jl error : wrong parameters, the number of outputs must be strictly positive"
        @assert nb_outputs == length(output_types) "NOMAD.jl error : wrong parameters, output types is not consistent with the number of outputs"

        if (A !== nothing) || (b !== nothing)
            @assert A !== nothing && b !== nothing "NOMAD.jl error: wrong parameter, A and b must be initialized together"
        end

        if A !== nothing
            @assert size(A, 2) == nb_inputs "NOMAD.jl error: wrong parameters, dimensions of A is not consistent with the number of inputs"
            @assert size(A, 1) == length(b) "NOMAD.jl error: wrong parameters, dimensions of A are not consistent with dimensions of b"
            @assert size(A, 1) < size(A, 2) "NOMAD.jl error: wrong parameters, A ∈ Rᵐˣⁿ must satisfy m < n"
        end

        return new(nb_inputs, nb_outputs, input_types,
                   granularity, min_mesh_size, initial_mesh_size,
                   lower_bound, upper_bound,
                   output_types, A, b, eval_bb, options)
    end
end

function check_problem(p::NomadProblem)
    @assert all(elt -> elt in BBInputTypes, p.input_types) "NOMAD.jl error: wrong parameters, at least one input is not a BBInputType"

    for i in 1:p.nb_inputs
        p.lower_bound[i] < p.upper_bound[i] ? nothing : error("NOMAD.jl error : wrong parameters, lower bounds should be inferior to upper bounds")
    end

    for i in 1:p.nb_inputs
        if p.input_types[i] == "R"
            p.granularity[i] >= 0 || error("NOMAD.jl error: wrong parameters, $(i)th coordinate of granularity is negative")
        elseif p.input_types[i] in ["I","B"]
            p.granularity[i] in [0,1] || error("NOMAD.jl error: $(i)th coordinate of granularity is automatically set to 1")
        end
    end

    # TODO tricky according to the type of inputs and variables
    for i in 1:p.nb_inputs
        p.min_mesh_size[i] >= 0 || error("NOMAD.jl error: wrong parameters, $(i)th coordinate of min_mesh_size is negative")
    end

    if !isempty(p.initial_mesh_size)
        for i in 1:p.nb_inputs
            p.initial_mesh_size[i] >= 0 || error("NOMAD.jl error: wrong parameters, $(i)th coordinate of initial_mesh_size is negative")
        end
        for i in 1:p.nb_inputs
            p.initial_mesh_size[i] >= p.min_mesh_size[i] || error("NOMAD.jl error: wrong parameters, $(i)th  coordinate of initial_mesh_size is smaller than $(i)th coordinate of min_mesh_size")
        end
    end

    # The resolution of a linear-constrained blackbox problem requires real and non granular variables.
    if p.A !== nothing
        all(p.input_types .== "R") || error("NOMAD.jl error: wrong parameters, all blackbox inputs must be real when solving a linear constrained blackbox optimization problem")
        isempty(p.initial_mesh_size) || error("NOMAD.jl error: wrong parameters, initial mesh size must be set to nothing when solving a linear constrained blackbox optimization problem")
        for i in 1:p.nb_inputs
            p.granularity[i] == 0 || error("NOMAD.jl error: wrong parameters, $(i)th coordinate of granularity must be set to 0 when solving a linear constrained blackbox optimization problem")
            p.min_mesh_size[i] == 0 || error("NOMAD.jl error: wrong parameters, $(i)th coordinate of min_mesh_size must be set to 0 when solving a linear constrained blackbox problem")
        end
    end

    @assert all(elt -> elt in BBOutputTypes, p.output_types) "NOMAD.jl error: wrong parameters, at least one output is not a BBOutputType"
end


"""
    solve(p::NomadProblem, x0::Vector{Float64})

-> Run NOMAD with settings defined by `NomadProblem` p from starting point `x0`.

-> Display stats from NOMAD in the REPL.

-> Return a NamedTuple that contains
info about the run.

# **Arguments**:
- `p::NomadProblem`
The problem to solve.

- `x0::Vector{Float64}`
The starting point. Must satisfy lb <= x0 <= ub
where lb and ub are respectively the lower and upper bounds
of the NomadProblem p. When A and b are defined, it must satisfy
A * x0 = b.

# **Example**:

```julia
using NOMAD

function eval_fct(x)
    f = x[1]^2 + x[2]^2
    c = 1 - x[1]
    success = true
    count_eval = true
    bb_outputs = [f,c]
    return (success, count_eval, bb_outputs)
end

# creation of a blackbox of dimensions 2*2 with one objective ("OBJ")
# and a constraint treated with the extreme barrier approach ("EB")
p = NomadProblem(2, 2, ["OBJ", "EB"], eval_fct)

# solve problem starting from the point [5.0;5.0]
result = solve(p, [5.0;5.0])
```

"""
function solve(p::NomadProblem, x0::Vector{Float64})
    handlers = map(SIGNALS) do signal
        sigsegv_handler(; signal)
    end
    sols = try
        # 1- make a first check before manipulating the c library
        check_problem(p)
        check_options(p.options)
        @assert p.nb_inputs == length(x0) "NOMAD.jl error : wrong parameters, starting point size is not consistent with bb inputs"

        # verify starting point satisfies approximately the linear constraints
        if p.A !== nothing
            isapprox(p.A * x0, p.b, atol=p.options.linear_constraints_atol) || error("NOMAD.jl error : starting point x0 does does not satisfy the linear constraints")
        end

        # 2- create c_nomad_problem
        # identity converter in case there are no linear constraints
        converter = identity

        # TODO refactorize
        c_nomad_problem = begin
            if p.A === nothing # no linear constraints
                input_types_wrapper = "( " * join(p.input_types, " ") * " )"
                output_types_wrapper = join(p.output_types, " ")
                create_c_nomad_problem(p.eval_bb ∘ converter, p.nb_inputs, p.nb_outputs,
                                    p.lower_bound, p.upper_bound,
                                    input_types_wrapper, output_types_wrapper, handlers)
            else # linear constraints
                # TODO to change with new converters
                converter = p.options.linear_converter == "SVD" ? SVDConverter(p.A, p.b) : QRConverter(p.A, p.b)

                nz = get_nz_dimension(converter)

                # fix blackbox new dimensions
                input_types_wrapper = "( " * join(["R" for i in 1:nz], " ") * " )"
                output_types_wrapper = join(p.output_types, " ")

                # fix new problem bounds
                print("Computing variable bounds for the reduced problem ...")
                lower_bound = get_lower_bound(converter, p.lower_bound, p.upper_bound)
                upper_bound = get_upper_bound(converter, p.lower_bound, p.upper_bound)
                println("Done")

                # x0 satisfies the equality constraints and the bounds constraints
                is_x0_evaluated = false


                new_eval_bb = z -> begin
                    if !is_x0_evaluated
                        is_x0_evaluated = true
                        return p.eval_bb(x0)
                    end
                    φ_x = convert_to_x(converter, z)
                    if all(p.lower_bound .<= φ_x .<= p.upper_bound)
                        return p.eval_bb(φ_x)
                    else # in this case, the function is not evaluated
                        return (false, false, [Inf for i in 1:p.nb_outputs])
                    end
                end

                create_c_nomad_problem(new_eval_bb, nz, p.nb_outputs,
                                    lower_bound, upper_bound,
                                    input_types_wrapper, output_types_wrapper, handlers)
            end
        end

        # 3- set options

        if p.A === nothing
            add_nomad_array_of_double_param!(c_nomad_problem, "GRANULARITY", p.granularity)
            if any(p.min_mesh_size .> 0)
                # conversion to Nomad tolerance to avoid warnings.
                add_nomad_array_of_double_param!(c_nomad_problem, "MIN_MESH_SIZE", max.(1e-26, p.min_mesh_size))
            end
            if !isempty(p.initial_mesh_size)
                add_nomad_array_of_double_param!(c_nomad_problem, "INITIAL_MESH_SIZE", p.initial_mesh_size)
            end

        end

        p.options.seed !== nothing && add_nomad_val_param!(c_nomad_problem, "SEED", p.options.seed)

        p.options.cache_size_max != typemax(Int64) && add_nomad_val_param!(c_nomad_problem, "CACHE_SIZE_MAX", p.options.cache_size_max)

        add_nomad_val_param!(c_nomad_problem, "DISPLAY_DEGREE", p.options.display_degree)
        add_nomad_bool_param!(c_nomad_problem, "DISPLAY_ALL_EVAL", p.options.display_all_eval)
        add_nomad_bool_param!(c_nomad_problem, "DISPLAY_INFEASIBLE", p.options.display_infeasible)
        add_nomad_bool_param!(c_nomad_problem, "DISPLAY_UNSUCCESSFUL", p.options.display_unsuccessful)

        if !isempty(p.options.display_stats)
            display_stats_wrapper = join(map(elt -> elt == "SOL" ? "( " * elt * " )" : elt, p.options.display_stats), " ")
            add_nomad_string_param!(c_nomad_problem, "DISPLAY_STATS", display_stats_wrapper)
        end

        add_nomad_val_param!(c_nomad_problem, "MAX_BB_EVAL", p.options.max_bb_eval)
        add_nomad_val_param!(c_nomad_problem, "SGTELIB_MODEL_MAX_EVAL", p.options.sgtelib_model_max_eval)
        add_nomad_bool_param!(c_nomad_problem, "EVAL_OPPORTUNISTIC", p.options.eval_opportunistic)
        add_nomad_bool_param!(c_nomad_problem, "EVAL_USE_CACHE", p.options.eval_use_cache)
        add_nomad_param!(c_nomad_problem, "EVAL_QUEUE_SORT " * p.options.eval_queue_sort)
        p.options.h_max_0 != Inf && add_nomad_param!(c_nomad_problem, "H_MAX_0 " * string(p.options.h_max_0))
        add_nomad_bool_param!(c_nomad_problem, "ANISOTROPIC_MESH", p.options.anisotropic_mesh)
        if !isempty(p.options.direction_type)
            add_nomad_string_param!(c_nomad_problem, "DIRECTION_TYPE", p.options.direction_type)
        end
        if !isempty(p.options.direction_type_secondary_poll)
            add_nomad_string_param!(c_nomad_problem, "DIRECTION_TYPE_SECONDARY_POLL", p.options.direction_type_secondary_poll)
        end
        add_nomad_param!(c_nomad_problem, "ANISOTROPY_FACTOR " * string(p.options.anisotropy_factor))
        add_nomad_string_param!(c_nomad_problem, "LH_SEARCH", string(p.options.lh_search[1]) * " " * string(p.options.lh_search[2]))
        add_nomad_bool_param!(c_nomad_problem, "QUAD_MODEL_SEARCH", p.options.quad_model_search)
        add_nomad_bool_param!(c_nomad_problem, "SGTELIB_MODEL_SEARCH", p.options.sgtelib_model_search)
        if p.options.speculative_search
            add_nomad_bool_param!(c_nomad_problem, "SPECULATIVE_SEARCH", p.options.speculative_search)
            add_nomad_param!(c_nomad_problem, "SPECULATIVE_SEARCH_BASE_FACTOR " * string(p.options.speculative_search_base_factor))
            add_nomad_val_param!(c_nomad_problem, "SPECULATIVE_SEARCH_MAX", p.options.speculative_search_max)
        end
        if p.options.nm_search
            add_nomad_bool_param!(c_nomad_problem, "NM_SEARCH", p.options.nm_search)
            add_nomad_param!(c_nomad_problem, "NM_DELTA_E " * string(p.options.nm_delta_e))
            add_nomad_param!(c_nomad_problem, "NM_DELTA_IC " * string(p.options.nm_delta_ic))
            add_nomad_param!(c_nomad_problem, "NM_DELTA_OC " * string(p.options.nm_delta_oc))
            add_nomad_param!(c_nomad_problem, "NM_GAMMA " * string(p.options.nm_gamma))
            add_nomad_param!(c_nomad_problem, "NM_SEARCH_RANK_EPS " * string(p.options.nm_search_rank_eps))
            add_nomad_val_param!(c_nomad_problem, "NM_SEARCH_MAX_TRIAL_PTS_NFACTOR", p.options.nm_search_max_trial_pts_nfactor)
            add_nomad_bool_param!(c_nomad_problem, "NM_SEARCH_STOP_ON_SUCCESS", p.options.nm_search_stop_on_success)
        end
        if p.options.vns_mads_search
            add_nomad_bool_param!(c_nomad_problem, "VNS_MADS_SEARCH", p.options.vns_mads_search)
            add_nomad_val_param!(c_nomad_problem, "VNS_MADS_SEARCH_MAX_TRIAL_PTS_NFACTOR", p.options.vns_mads_search_max_trial_pts_nfactor)
            add_nomad_param!(c_nomad_problem, "VNS_MADS_SEARCH_TRIGGER " * string(p.options.vns_mads_search_trigger))
        end

        if p.options.max_time !== nothing
            add_nomad_val_param!(c_nomad_problem, "MAX_TIME", p.options.max_time)
        end

        add_nomad_bool_param!(c_nomad_problem, "STOP_IF_FEASIBLE", p.options.stop_if_feasible)

        # 4- solve problem
        result = if p.A === nothing
                solve_nomad_problem(c_nomad_problem, x0, 1)
            else
                z0 = convert_to_z(converter, x0)
                solve_nomad_problem(c_nomad_problem, z0, 1)
            end

        sols = if p.A === nothing
                (x_best_feas = result[1] ? result[2] : nothing,
                bbo_best_feas = result[1] ? result[3] : nothing,
                x_best_inf = result[4] ? result[5] : nothing,
                bbo_best_inf = result[4] ? result[6] : nothing)
            else
                (x_best_feas = result[1] ? convert_to_x(converter, result[2]) : nothing,
                bbo_best_feas = result[1] ? result[3] : nothing,
                x_best_inf = result[4] ? convert_to_x(converter, result[5]) : nothing,
                bbo_best_inf = result[4] ? result[6] : nothing)
            end

        finalize(c_nomad_problem)
        sols
    finally
        foreach(zip(SIGNALS, handlers)) do (signal, handler)
            sigsegv_handler(handler, C_NULL; signal)
        end
    end

    return sols
end
