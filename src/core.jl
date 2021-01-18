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

mutable struct NomadOptions

    # display options
    display_degree::Int # display degree: between 0 and 3
    display_all_eval::Bool # display all evaluations
    display_infeasible::Bool # display infeasible
    display_unsuccessful::Bool # display unsuccessful

    # eval options
    max_bb_eval::Int # maximum number of evaluations allowed
    opportunistic_eval::Bool
    use_cache::Bool

    # run options
    lh_search::Tuple{Int, Int} # lh_search_init, lh_search_iter
    speculative_search::Bool
    nm_search::Bool

    # linear constrained optimization options
    linear_converter::String
    linear_constraints_atol::Float64

    function NomadOptions(;display_degree::Int = 2,
                          display_all_eval::Bool = false,
                          display_infeasible::Bool = false,
                          display_unsuccessful::Bool = false,
                          max_bb_eval::Int = 20000,
                          opportunistic_eval::Bool = true,
                          use_cache::Bool = true,
                          lh_search::Tuple{Int, Int} =(0,0),
                          speculative_search::Bool=true,
                          nm_search::Bool=true,
                          linear_converter::String="SVD",
                          linear_constraints_atol::Float64=0.0)
        return new(display_degree,
                   display_all_eval,
                   display_infeasible,
                   display_unsuccessful,
                   max_bb_eval,
                   opportunistic_eval,
                   use_cache,
                   lh_search,
                   speculative_search,
                   nm_search,
                   linear_converter,
                   linear_constraints_atol)
    end
end

function check_options(options::NomadOptions)
    (0 <= options.display_degree <= 3) ? nothing : error("Nomad.jl error: display_degree must be comprised between 0 and 3")
    (options.max_bb_eval > 0) ? nothing : error("NOMAD.jl error: wrong parameters, max_bb_eval must be strictly positive")
    (options.lh_search[1] >= 0 && options.lh_search[2] >=0) ? nothing : error("NOMAD.jl error: the lh_search parameters must be positive or null")
    (options.linear_converter in BBLinearConverterTypes) ? nothing : error("NOMAD.jl error: the linear_converter type is not defined")
    (options.linear_constraints_atol >= 0) ? nothing : error("NOMAD.jl error: the linear_constraints_atol parameter must be positive or null")
end

"""
    NomadProblem(nb_inputs::Int, nb_outputs::Int, output_types::Vector{String}, eval_bb::Function;
                 input_types::Vector{String} = ["R" for i in 1:nb_inputs],
                 granularity::Vector{Float64} = zeros(Float64, nb_inputs),
                 lower_bound::Vector{Float64} = -Inf * ones(Float64, nb_inputs),
                 upper_bound::Vector{Float64} = Inf * ones(Float64, nb_inputs))

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

String  | Input type |
 :-------|:-----------|
`"R"`   | Real/Continuous |
`"B"`   | Binary |
`"I"`   | Integer |
all R by default.

- `granularity::Vector{Float64}`:
The granularity of input variables, that is to say the minimum variation
authorized for these variables. A granularity of 0 corresponds to a real
variable.

By default, `0` for real variables, `1` for integer and binary ones.

- `lower_bound::Vector{Float64}`:
Lower bound for each coordinate of the blackbox input.
`-Inf * ones(Float64, nb_inputs)`, by default.

- `upper_bound::Vector{Float64}`:
Upper bound for each coordinate of the blackbox input.

`Inf * ones(Float64, nb_inputs)`, by default.

- `options::NomadOptions`
Nomad options that can be set before running the optimization process.

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

-> `max_bb_eval::Int`:

Maximum of calls to eval_bb allowed. Must be positive.

`20000` by default.

-> `opportunistic_eval::Bool`

If true, the algorithm performs an opportunistic strategy
at each iteration.

`true` by default.

-> `use_cache::Bool`:

If true, the algorithm only evaluates one time a given input.
Avoids to recalculate a blackbox value if this last one has
already be computed.

`true` by default.

-> `lh_search::Tuple{Int, Int}`:

LH search parameters.

`lh_search[1]` is the `lh_search_init` parameter, i.e.
the number of initial search points performed with Latin-Hypercube method.

`0` by default.

`lh_search[2]` is the  `lh_search_iter` parameter, i.e.
the number of search points performed at each iteration with Latin-Hypercube method.

`0` by default.

-> `speculative_search::Bool`:

If true, the algorithm executes a speculative search strategy at each iteration.

`true` by default.

-> `nm_search::Bool`:

If true, the algorithm executes a speculative search strategy at each iteration.

`true` by default.
"""
struct NomadProblem

    nb_inputs::Int # number of variables
    nb_outputs::Int # number of outputs

    input_types::Vector{String}
    granularity::Vector{Float64}
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
                          A::Union{Nothing, Array{Float64, 2}} = nothing,
                          b::Union{Nothing, Vector{Float64}} = nothing)

        @assert nb_inputs > 0 "NOMAD.jl error : wrong parameters, the number of inputs must be strictly positive"
        @assert nb_inputs == length(lower_bound) "NOMAD.jl error: wrong parameters, lower bound is not consistent with the number of inputs"
        @assert nb_inputs == length(upper_bound) "NOMAD.jl error: wrong parameters, upper bound is not consistent with the number of inputs"
        @assert nb_inputs == length(input_types) "NOMAD.jl error: wrong parameters, input types is not consistent with the number of inputs"
        @assert nb_inputs == length(granularity) "NOMAD.jl error: wrong parameters, granularity is not consistent with the number of inputs"

        @assert nb_outputs > 0 "NOMAD.jl error : wrong parameters, the number of outputs must be strictly positive"
        @assert nb_outputs == length(output_types) "NOMAD.jl error : wrong parameters, output types is not consistent with the number of outputs"

        if (A != nothing) || (b != nothing)
            @assert A != nothing && b != nothing "NOMAD.jl error: wrong parameter, A and b must be initialized together"
        end

        if A != nothing
            @assert size(A, 2) == nb_inputs "NOMAD.jl error: wrong parameters, dimensions of A is not consistent with the number of inputs"
            @assert size(A, 1) == length(b) "NOMAD.jl error: wrong parameters, dimensions of A are not consistent with dimensions of b"
            @assert size(A, 1) < size(A, 2) "NOMAD.jl error: wrong parameters, A ∈ Rᵐˣⁿ must satisfy m < n"
        end

        return new(nb_inputs, nb_outputs, input_types,
                   granularity, lower_bound, upper_bound,
                   output_types, A, b, eval_bb, NomadOptions())
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

    # The resolution of a linear-constrained blackbox problem requires real and non granular variables.
    if p.A != nothing
        all(p.input_types .== "R") || error("NOMAD.jl error: wrong parameters, all blackbox inputs must be real when solving a linear constrained blackbox optimization problem")
        for i in 1:p.nb_inputs
            p.granularity[i] == 0 || error("NOMAD.jl error: wrong parameters, $(i)th coordinate of granularity must be set to 0 when solving a linear constrained blackbox optimization problem") 
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
of the NomadProblem p.

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
    # 1- make a first check before manipulating the c library
    check_problem(p)
    check_options(p.options)
    @assert p.nb_inputs == length(x0) "NOMAD.jl error : wrong parameters, starting point size is not consistent with bb inputs"

    # verify starting point satisfies approximately the linear constraints 
    if p.A != nothing
        isapprox(p.A * x0, p.b, atol=p.options.linear_constraints_atol) || error("NOMAD.jl error : starting point x0 does does not satisfy the linear constraints")
    end

    # 2- create c_nomad_problem
    # identity converter in case there are no linear constraints
    converter = identity

    # TODO refactorize
    c_nomad_problem = begin
        if p.A == nothing # no linear constraints
            input_types_wrapper = "( " * join(p.input_types, " ") * " )"
            output_types_wrapper = join(p.output_types, " ")
            create_c_nomad_problem(p.eval_bb ∘ converter, p.nb_inputs, p.nb_outputs,
                                   p.lower_bound, p.upper_bound,
                                   input_types_wrapper, output_types_wrapper,
                                   p.options.max_bb_eval)
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
                                   input_types_wrapper, output_types_wrapper,
                                   p.options.max_bb_eval)
        end
    end

    # 3- set options
    set_nomad_granularity_bb_inputs!(c_nomad_problem, p.granularity)

    set_nomad_display_degree!(c_nomad_problem, p.options.display_degree)
    set_nomad_display_all_eval!(c_nomad_problem, p.options.display_all_eval)
    set_nomad_display_infeasible!(c_nomad_problem, p.options.display_infeasible)
    set_nomad_display_unsuccessful!(c_nomad_problem, p.options.display_unsuccessful)

    set_nomad_opportunistic_eval!(c_nomad_problem, p.options.opportunistic_eval)
    set_nomad_use_cache!(c_nomad_problem, p.options.use_cache)

    set_nomad_LH_search_params!(c_nomad_problem, p.options.lh_search[1], p.options.lh_search[2])
    set_nomad_speculative_search!(c_nomad_problem, p.options.speculative_search)
    set_nomad_nm_search!(c_nomad_problem, p.options.nm_search)

    # 4- solve problem
    result = begin
        if p.A == nothing
            solve_problem(c_nomad_problem, x0)
        else
            z0 = convert_to_z(converter, x0)
            solve_problem(c_nomad_problem, z0)
        end
    end

    sols = begin
        if p.A == nothing
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
    end
    return sols
end
