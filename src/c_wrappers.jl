using NOMAD_jll

######################################################
#              NOMAD C low level types               #
######################################################
mutable struct C_NomadProblem
    ref::Ptr{Cvoid} # pointer to internal references

    nb_inputs::Int
    nb_outputs::Int

    eval_bb::Function # callback function

    function C_NomadProblem(ref::Ptr{Cvoid},
                            nb_inputs::Int,
                            nb_outputs::Int,
                            eval_bb::Function)
        p = new(ref, nb_inputs, nb_outputs, eval_bb)
        finalizer(free_c_nomad_problem, p)
        return p
    end
end

# C objectve function wrapper
function eval_bb_wrapper(nb_inputs::Cint, inputs_ptr::Ptr{Float64},
                         nb_outputs::Cint, outputs_ptr::Ptr{Float64},
                         count_eval_ptr::Ptr{Cint}, user_data_ptr::Ptr{Cvoid})
    # extract the Julia problem from pointer
    prob = unsafe_pointer_to_objref(user_data_ptr)::C_NomadProblem

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

    return Int32(success_flag)
end

function create_c_nomad_problem(eval_bb::Function,
                                nb_inputs::Int,
                                nb_outputs::Int,
                                lower_bound::Vector{Float64},
                                upper_bound::Vector{Float64},
                                type_inputs::String,
                                type_outputs::String,
                                max_bb_eval::Int)
    # check bounds
    lower_bound_wrapper = copy(lower_bound)
    if any(elt -> elt == Inf || elt == -Inf, lower_bound)
        lower_bound_wrapper = C_NULL
    end

    upper_bound_wrapper = copy(upper_bound)
    if any(elt -> elt == Inf || elt == -Inf, upper_bound)
        upper_bound_wrapper = C_NULL
    end

    # wrap callback function
    eval_bb_cb = @cfunction(eval_bb_wrapper, Cint, (Cint, Ptr{Float64}, Cint, Ptr{Float64}, Ptr{Cint}, Ptr{Cvoid}))

    internal_ref = ccall((:createNomadProblem, libnomadInterface), Ptr{Cvoid},
                         (Ptr{Cvoid}, Cint, Cint, # function, nb_inputs, nb_outputs
                          Ptr{Float64}, Ptr{Float64}, # lower bounds, upper bounds
                          Ptr{UInt8}, Ptr{UInt8}, Cint), # type inputs, type ouputs, max bb evaluations
                         eval_bb_cb, nb_inputs, nb_outputs, lower_bound_wrapper, upper_bound_wrapper,
                         type_inputs, type_outputs, max_bb_eval)

    if internal_ref == C_NULL
        error("NOMAD.jl: Failed to construct problem.")
    else
        return C_NomadProblem(internal_ref, nb_inputs, nb_outputs, eval_bb)
    end

end

function free_c_nomad_problem(prob::C_NomadProblem)
    if prob.ref != C_NULL
        ccall((:freeNomadProblem, libnomadInterface), Cvoid, (Ptr{Cvoid},), prob.ref)
        prob.ref = C_NULL
    end
end

function set_nomad_granularity_bb_inputs!(prob::C_NomadProblem, granularity::Vector{Float64})
    is_ok = ccall((:setNomadGranularityBBInputs, libnomadInterface), Cint, (Ptr{Cvoid}, Ptr{Float64}), prob.ref, granularity)
    return is_ok
end

function set_nomad_display_degree!(prob::C_NomadProblem, display_degree::Int)
    is_ok = ccall((:setNomadDisplayDegree, libnomadInterface), Cint, (Ptr{Cvoid}, Cint), prob.ref, display_degree)
    return is_ok
end

function set_nomad_display_all_eval!(prob::C_NomadProblem, display_all_eval::Bool)
    is_ok = ccall((:setNomadDisplayAllEval, libnomadInterface), Cint, (Ptr{Cvoid}, Cint), prob.ref, display_all_eval)
    return is_ok
end

function set_nomad_display_infeasible!(prob::C_NomadProblem, display_infeasible::Bool)
    is_ok = ccall((:setNomadDisplayInfeasible, libnomadInterface), Cint, (Ptr{Cvoid}, Cint), prob.ref, display_infeasible)
    return is_ok
end

function set_nomad_display_unsuccessful!(prob::C_NomadProblem, display_unsuccessful::Bool)
    is_ok = ccall((:setNomadDisplayUnsuccessful, libnomadInterface), Cint, (Ptr{Cvoid}, Cint), prob.ref, display_unsuccessful)
    return is_ok
end

function set_nomad_opportunistic_eval!(prob::C_NomadProblem, opportunistic_eval::Bool)
    is_ok = ccall((:setNomadOpportunisticEval, libnomadInterface), Cint, (Ptr{Cvoid}, Cint), prob.ref, opportunistic_eval)
    return is_ok
end

function set_nomad_use_cache!(prob::C_NomadProblem, use_cache::Bool)
    is_ok = ccall((:setNomadUseCache, libnomadInterface), Cint, (Ptr{Cvoid}, Cint), prob.ref, use_cache)
    return is_ok
end

function set_nomad_LH_search_params!(prob::C_NomadProblem, lh_search_init::Int, lh_search_iter::Int)
    is_ok = ccall((:setNomadLHSearchParams, libnomadInterface), Cint, (Ptr{Cvoid}, Cint, Cint), prob.ref, lh_search_init, lh_search_iter)
    return is_ok
end

function set_nomad_speculative_search!(prob::C_NomadProblem, speculative_search::Bool)
    is_ok = ccall((:setNomadUseCache, libnomadInterface), Cint, (Ptr{Cvoid}, Cint), prob.ref, speculative_search)
    return is_ok
end

function set_nomad_nm_search!(prob::C_NomadProblem, nm_search::Bool)
    is_ok = ccall((:setNomadUseCache, libnomadInterface), Cint, (Ptr{Cvoid}, Cint), prob.ref, nm_search)
    return is_ok
end

function solve_problem(prob::C_NomadProblem, x0::Vector{Float64})
    # will be used to check if the algorithm finds a feasible or infeasible solution
    exists_feas_sol = Ref{Cint}(0)
    exists_inf_sol = Ref{Cint}(0)

    # final values
    x_feas_sol = zeros(Float64, prob.nb_inputs)
    x_inf_sol = zeros(Float64, prob.nb_inputs)
    outputs_feas_sol = zeros(Float64, prob.nb_outputs)
    outputs_inf_sol = zeros(Float64, prob.nb_outputs)

    statusflag = ccall((:solveNomadProblem, libnomadInterface), Cint,
                       (Ptr{Cvoid}, Ptr{Float64}, # internal data, starting points
                        Ptr{Cint}, Ptr{Float64}, Ptr{Float64}, # feasible solution flag, x_feas, outputs feas
                        Ptr{Cint}, Ptr{Float64}, Ptr{Float64}, # infeasible solution flag, x_inf, output inf
                        Any),
                       prob.ref, x0, exists_feas_sol, x_feas_sol, outputs_feas_sol,
                       exists_inf_sol, x_inf_sol, outputs_inf_sol, prob)
    return (Bool(exists_feas_sol[]), x_feas_sol, outputs_feas_sol, 
            Bool(exists_inf_sol[]), x_inf_sol, outputs_inf_sol)
end
