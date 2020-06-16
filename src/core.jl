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


mutable struct NomadOptions

    # display otions
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

    function NomadOptions(;display_degree::Int = 2,
                          display_all_eval::Bool = false,
                          display_infeasible::Bool = false,
                          display_unsuccessful::Bool = false,
                          max_bb_eval::Int = 20000,
                          opportunistic_eval::Bool = true,
                          use_cache::Bool = true,
                          lh_search::Tuple{Int, Int} =(0,0),
                          speculative_search::Bool=true,
                          nm_search::Bool=true)
        return new(display_degree,
                   display_all_eval,
                   display_infeasible,
                   display_unsuccessful,
                   max_bb_eval,
                   opportunistic_eval,
                   use_cache,
                   lh_search,
                   speculative_search,
                   nm_search)
    end
end

function check_options(options::NomadOptions)
    (0 <= options.display_degree <= 3) ? nothing : error("Nomad.jl error: display_degree must be comprised between 0 and 3")
    (options.max_bb_eval > 0) ? nothing : error("NOMAD.jl error: wrong parameters, max_bb_eval must be strictly positive")
    (options.lh_search[1] >= 0 && options.lh_search[2] >=0) ? nothing : error("NOMAD.jl error: the lh_search parameters must be positive or null")
end

struct NomadProblem

    nb_inputs::Int # number of variables
    nb_outputs::Int # number of outputs

    input_types::Vector{String}
    granularity::Vector{Float64}
    lower_bound::Vector{Float64}
    upper_bound::Vector{Float64}

    output_types::Vector{String}

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
                          upper_bound::Vector{Float64} = Inf * ones(Float64, nb_inputs))

        @assert nb_inputs > 0 "NOMAD.jl error : wrong parameters, the number of inputs must be strictly positive"
        @assert nb_inputs == length(lower_bound) "NOMAD.jl error: wrong parameters, lower bound is not consistent with the number of inputs"
        @assert nb_inputs == length(upper_bound) "NOMAD.jl error: wrong parameters, upper bound is not consistent with the number of inputs"
        @assert nb_inputs == length(input_types) "NOMAD.jl error: wrong parameters, input types is not consistent with the number of inputs"
        @assert nb_inputs == length(granularity) "NOMAD.jl error: wrong parameters, granularity is not consistent with the number of inputs"

        @assert nb_outputs > 0 "NOMAD.jl error : wrong parameters, the number of outputs must be strictly positive"
        @assert nb_outputs == length(output_types) "NOMAD.jl error : wrong parameters, output types is not consistent with the number of outputs"

        return new(nb_inputs, nb_outputs, input_types,
                   granularity, lower_bound, upper_bound,
                   output_types, eval_bb, NomadOptions())
    end
end

function check_problem(p::NomadProblem)
    @assert all(elt -> elt in BBInputTypes, p.input_types) "NOMAD.jl error: wrong parameters, at least one input is not a BBInputType"

    for i in 1:p.nb_inputs
        p.lower_bound[i] < p.upper_bound[i] ? nothing : error("NOMAD.jl error : wrong parameters, lower bounds should be inferior to upper bounds")
    end

    for i in 1:p.nb_inputs
        if p.input_types[i] == "R"
            p.granularity[i] >= 0 || error("NOMAD.jl error:  wrong parameters, $(i)th coordinate of granularity is negative")
        elseif p.input_types[i] in ["I","B"]
            p.granularity[i] in [0,1] || error("NOMAD.jl error : $(i)th coordinate of granularity is automatically set to 1")
        end
    end

    @assert all(elt -> elt in BBOutputTypes, p.output_types) "NOMAD.jl error: wrong parameters, at least one output is not a BBOutputType"
end

function solve(p::NomadProblem, x0::Vector{Float64})
    # 1- make a first check before manipulating the c library
    check_problem(p)
    check_options(p.options)
    @assert p.nb_inputs == length(x0) "NOMAD.jl error : wrong parameters, starting point size is not consistent with bb inputs"

    # 2- create c_nomad_problem
    input_types_wrapper = "( " * join(p.input_types, " ") * " )"
    output_types_wrapper = join(p.output_types, " ")

    c_nomad_problem = create_c_nomad_problem(p.eval_bb, p.nb_inputs, p.nb_outputs,
                                             p.lower_bound, p.upper_bound,
                                             input_types_wrapper, output_types_wrapper,
                                             p.options.max_bb_eval)

    # 3 - set options
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
    result = solve_problem(c_nomad_problem, x0)

    sols = Dict{Symbol, Any}()
    if (result[1])
        sols[:feasible_sol] = (result[2], result[3])
    end
    if (result[4])
        sols[:infeasible_sol] = (result[5], result[6])
    end
    return sols
end
