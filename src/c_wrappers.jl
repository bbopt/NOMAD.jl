const SIGNALS = [2, 11]

function sigsegv_handler(new=C_NULL, old=zeros(UInt8, 256); signal)
    @static if Sys.isunix()
        @ccall sigaction(
            signal::Cint,
            new::Ptr{Cvoid},
            old::Ptr{Cvoid})::Cint
    end
    return old
end

######################################################
#              NOMAD C low level types               #
######################################################
mutable struct C_NomadResult
    ref::Ptr{Cvoid} # pointer to internal references
    function C_NomadResult(ref::Ptr{Cvoid})
        res = new(ref)
        finalizer(free_c_nomad_result, res)
        return res
    end
end

function create_c_nomad_result()
    internal_ref = ccall((:createNomadResult, libnomadCInterface), Ptr{Cvoid}, ())
    if internal_ref == C_NULL
        error("NOMAD.jl: Failed to construct C_NomadResult instance.")
    end
    return C_NomadResult(internal_ref)
end

function free_c_nomad_result(res::C_NomadResult)
    if res.ref != C_NULL
        ccall((:freeNomadResult, libnomadCInterface), Cvoid, (Ptr{Cvoid},), res.ref)
        res.ref = C_NULL
    end
end

function nb_solutions_c_nomad_result(res::C_NomadResult)
    if res.ref != C_NULL
        return ccall((:nbSolutionsNomadResult, libnomadCInterface), Cint, (Ptr{Cvoid},), res.ref)
    end
    return 0
end

function feasible_solutions_found_c_nomad_result(res::C_NomadResult)::Bool
    if res.ref != C_NULL
        return ccall((:feasibleSolutionsFoundNomadResult, libnomadCInterface), Cint, (Ptr{Cvoid},), res.ref)
    end
    return false
end

function nb_inputs_c_nomad_result(res::C_NomadResult)
    if res.ref != C_NULL
        return ccall((:nbInputsNomadResult, libnomadCInterface), Cint, (Ptr{Cvoid},), res.ref)
    end
    return 0
end

function nb_outputs_c_nomad_result(res::C_NomadResult)
    if res.ref != C_NULL
        return ccall((:nbOutputsNomadResult, libnomadCInterface), Cint, (Ptr{Cvoid},), res.ref)
    end
    return 0
end

function load_inputs_c_nomad_result(inputs::Array{Float64},
                                    res::C_NomadResult)::Bool
    if res.ref != C_NULL
        nb_solutions = nb_solutions_c_nomad_result(res)
        if nb_solutions <= 0
            return false
        end
        return ccall((:loadInputSolutionsNomadResult, libnomadCInterface), Cint, (Ptr{Cdouble}, Cint, Ptr{Cvoid}), inputs, nb_solutions, res.ref)
    end
    return false
end

function load_outputs_c_nomad_result(outputs::Array{Float64},
                                     res::C_NomadResult)::Bool
    if res.ref != C_NULL
        nb_solutions = nb_solutions_c_nomad_result(res)
        if nb_solutions <= 0
            return false
        end
        return ccall((:loadOutputSolutionsNomadResult, libnomadCInterface), Cint, (Ptr{Cdouble}, Cint, Ptr{Cvoid}), outputs, nb_solutions, res.ref)
    end
    return false
end

mutable struct C_NomadProblem
    ref::Ptr{Cvoid} # pointer to internal references

    nb_inputs::Int
    nb_outputs::Int

    eval_bb::Function # callback function
    handlers::Vector{Vector{UInt8}}
    function C_NomadProblem(ref::Ptr{Cvoid},
                            nb_inputs::Int,
                            nb_outputs::Int,
                            eval_bb::Function,
                            handlers)
        p = new(ref, nb_inputs, nb_outputs, eval_bb, handlers)
        finalizer(free_c_nomad_problem, p)
        return p
    end
end

# C objective function wrapper
function eval_bb_wrapper(nb_inputs::Cint, inputs_ptr::Ptr{Float64},
                         nb_outputs::Cint, outputs_ptr::Ptr{Float64},
                         count_eval_ptr::Ptr{Cint}, user_data_ptr::Ptr{Cvoid})
    # extract the Julia problem from pointer
    prob = unsafe_pointer_to_objref(user_data_ptr)::C_NomadProblem
    nomad_handlers = map(zip(SIGNALS, prob.handlers)) do (signal, handler)
        sigsegv_handler(handler; signal)
    end
    success_flag = try
        # get the new outputs from the black box
        new_bb_outputs = unsafe_wrap(Array, outputs_ptr, Int(nb_outputs))

        # eval black box
        success_flag, count_eval, bb_outputs = prob.eval_bb(unsafe_wrap(Array, inputs_ptr, Int(nb_inputs)))

        # affect values to C array outputs
        for i in 1:nb_outputs
            new_bb_outputs[i] = bb_outputs[i]
        end

        # affect count eval to count_eval flag
        unsafe_store!(count_eval_ptr, count_eval)
        success_flag
    finally
        foreach(flush, (stdout, stderr))
        foreach(zip(SIGNALS, nomad_handlers)) do (signal, old_handler)
            sigsegv_handler(old_handler, C_NULL; signal)
        end
    end

    return Int32(success_flag)
end

function create_c_nomad_problem(eval_bb::Function,
                                nb_inputs::Int,
                                nb_outputs::Int,
                                lower_bound::Vector{Float64},
                                upper_bound::Vector{Float64},
                                type_inputs::String,
                                type_outputs::String,
                                handlers)
    # wrap callback function
    eval_bb_cb = @cfunction(eval_bb_wrapper, Cint, (Cint, Ptr{Float64}, Cint, Ptr{Float64}, Ptr{Cint}, Ptr{Cvoid}))

    internal_ref = ccall((:createNomadProblem, libnomadCInterface), Ptr{Cvoid},
                         (Ptr{Cvoid}, Ptr{Cvoid}, Cint, Cint),
                         eval_bb_cb, C_NULL, nb_inputs, nb_outputs) # function, no evaluation per batch, nb_inputs, nb_outputs

    if internal_ref == C_NULL
        error("NOMAD.jl: Failed to construct problem.")
    else

        # Must fix dimensions before other parameters
        ccall((:addNomadValParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Cint), internal_ref, "DIMENSION", nb_inputs)

        # Use the non safe api function addNomadParam; enable to be more precise on the bounds according to Nomad.
        # Lower bound
        lower_bound_wrapper = "( " * join(map(elt -> elt == Inf || elt == -Inf ? "-" : string(elt), lower_bound), " ") * " )"
        ccall((:addNomadParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}), internal_ref, "LOWER_BOUND " * lower_bound_wrapper)

        # Upper bound
        upper_bound_wrapper = "( " * join(map(elt -> elt == Inf || elt == -Inf ? "-" : string(elt), upper_bound), " ") * " )"
        ccall((:addNomadParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}), internal_ref, "UPPER_BOUND " * upper_bound_wrapper)

        # Input types
        ccall((:addNomadStringParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{UInt8}), internal_ref, "BB_INPUT_TYPE", type_inputs)

        # Output types
        ccall((:addNomadStringParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{UInt8}), internal_ref, "BB_OUTPUT_TYPE", type_outputs)

        return C_NomadProblem(internal_ref, nb_inputs, nb_outputs, eval_bb, handlers)
    end

end

function free_c_nomad_problem(prob::C_NomadProblem)
    if prob.ref != C_NULL
        ccall((:freeNomadProblem, libnomadCInterface), Cvoid, (Ptr{Cvoid},), prob.ref)
        prob.ref = C_NULL
    end
end

function add_nomad_param!(prob::C_NomadProblem, keyword_instruction::String)
    is_ok = ccall((:addNomadParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}), prob.ref, keyword_instruction)
    return is_ok
end

function add_nomad_val_param!(prob::C_NomadProblem, keyword::String, value::Int)
    is_ok = ccall((:addNomadValParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Cint), prob.ref, keyword, value)
    return is_ok
end

function add_nomad_bool_param!(prob::C_NomadProblem, keyword::String, value::Bool)
    is_ok = ccall((:addNomadBoolParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Cint), prob.ref, keyword, value)
    return is_ok
end

function add_nomad_string_param!(prob::C_NomadProblem, keyword::String, param_str::String)
    is_ok = ccall((:addNomadStringParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{UInt8}), prob.ref, keyword, param_str)
    return is_ok
end

function add_nomad_array_of_double_param!(prob::C_NomadProblem, keyword::String, a::Vector{Float64})
    is_ok = ccall((:addNomadArrayOfDoubleParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Float64}), prob.ref, keyword, a)
    return is_ok
end

function solve_nomad_problem(prob::C_NomadProblem, x0s::Vector{Float64}, nb_starting_points::Int)
    c_result = create_c_nomad_result()

    # Solve problem
    statusflag = ccall((:solveNomadProblem, libnomadCInterface), Cint,
                       (Ptr{Cvoid}, Ptr{Cvoid}, # C_NomadResult internal data, C_NomadProblem internal data
                        Cint, Ptr{Float64}, # number of starting points, starting points,
                        Any),
                       c_result.ref, prob.ref, nb_starting_points, x0s, prob)

    # Collect information
    result_infos = Dict()
    result_infos[:status] = statusflag
    result_infos[:x_sol] = nothing
    result_infos[:bbo_sol] = nothing
    result_infos[:feasible] = nothing

    # The optimization has failed
    if statusflag in [-3, -7, -8]
        finalize(c_result)
        return result_infos
    end

    nb_solutions = nb_solutions_c_nomad_result(c_result)
    if nb_solutions == 0
        finalize(c_result)
        # Something has gone wrong. Indicates it.
        result_infos[:status] = -8
        return result_infos
    end

    # Collect solutions
    x_sol = zeros(Float64, nb_solutions * prob.nb_inputs)
    load_x_sol = load_inputs_c_nomad_result(x_sol, c_result)
    if !load_x_sol
        finalize(c_result)
        # Something has gone wrong. Indicates it.
        result_infos[:status] = -8
        return result_infos
    end

    outputs_sol = zeros(Float64, nb_solutions * prob.nb_outputs)
    load_outputs_sol = load_outputs_c_nomad_result(outputs_sol, c_result)
    if !load_outputs_sol
        finalize(c_result)
        # Something has gone wrong. Indicates it.
        result_infos[:status] = -8
        return result_infos
    end

    x_sol = reshape(x_sol, (prob.nb_inputs, nb_solutions))
    outputs_sol = reshape(outputs_sol, (prob.nb_outputs, nb_solutions))
    is_feasible = feasible_solutions_found_c_nomad_result(c_result)
    result_infos[:x_sol] = x_sol
    result_infos[:bbo_sol] = outputs_sol
    result_infos[:feasible] = is_feasible

    finalize(c_result)
    return result_infos
end
