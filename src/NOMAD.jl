module NOMAD

using NOMAD_jll

export NomadProblem, eval_bb_wrapper, createNomadProblem, freeNomadProblem, solveProblem

# must never be manipulated directly
mutable struct NomadProblem

    ref::Ptr{Cvoid} # pointer to internal references

    nb_inputs::Int # Number of variables
    nb_outputs::Int # number of outputs of the black box

    type_bb_outputs::Vector{String} #contains bb_outputs

    x0::Vector{Float64} # starting point

    max_bb_eval::Int # maximum number of evaluations allowed

    # callbacks
    eval_bb::Function

    function NomadProblem(ref::Ptr{Cvoid}, 
                          nb_inputs::Int, 
                          nb_outputs::Int,
                          type_bb_outputs::Vector{String},
                          eval_bb::Function,
                          max_bb_eval::Int)
        prob = new(ref,
                   nb_inputs,
                   nb_outputs,
                   type_bb_outputs,
                   zeros(Float64, nb_inputs),
                   max_bb_eval,
                   eval_bb)
        finalizer(freeNomadProblem, prob)
        return prob
    end

end

# C function wrappers
function eval_bb_wrapper(nb_inputs::Cint, inputs_ptr::Ptr{Float64}, nb_outputs::Cint, outputs_ptr::Ptr{Float64}, user_data_ptr::Ptr{Cvoid})
    # extract the Julia problem from pointer
    prob = unsafe_pointer_to_objref(user_data_ptr)::NomadProblem
    # get the new outputs from the black box
    new_bb_outputs = unsafe_wrap(Array, outputs_ptr, Int(nb_outputs))
    # collect the boolean indicated if it is working
    is_worked = prob.eval_bb(unsafe_wrap(Array, inputs_ptr, Int(nb_inputs)), new_bb_outputs)
    return Int32(is_worked)
end

function createNomadProblem(nb_inputs::Int,
                            nb_outputs::Int,
                            eval_bb,
                            type_bb_outputs::Vector{String}, 
                            max_bb_eval;
                            x_lb::Vector{Float64} = -Inf * ones(Float64, nb_inputs),
                            x_ub::Vector{Float64} = Inf * ones(Float64, nb_inputs))


    @assert nb_inputs == length(x_lb) == length(x_ub)
    @assert nb_outputs == length(type_bb_outputs)
    @assert max_bb_eval > 0

    # TODO add specific type for type_bb_outputs

    # convert type_bb_outputs in character chains
    type_bb_outputs_wrapper = join(type_bb_outputs, " ")

    # check bounds
    x_lb_wrapper = copy(x_lb)
    if any(elt -> elt == Inf || elt == -Inf, x_lb)
        x_lb_wrapper = C_NULL
    end

    x_ub_wrapper = copy(x_ub)
    if any(elt -> elt == Inf || elt == -Inf, x_ub)
        x_ub_wrapper = C_NULL
    end

    # wrap callback function
    eval_bb_cb = @cfunction(eval_bb_wrapper, Cint, (Cint, Ptr{Float64}, Cint, Ptr{Float64}, Ptr{Cvoid}))

    internal_ref = ccall((:createNomadProblem, libnomadInterface), Ptr{Cvoid},
                         (Ptr{Cvoid}, Cint, Cint, # function, nb_inputs, nb_outputs
                          Ptr{Float64}, Ptr{Float64}, # lower bounds, upper bounds
                          Ptr{UInt8}, Cint), # type bb ouputs, max bb evaluations
                         eval_bb_cb, nb_inputs, nb_outputs, x_lb_wrapper, x_ub_wrapper, 
                         type_bb_outputs_wrapper, max_bb_eval)

    if internal_ref == C_NULL
        error("NOMAD: Failed to construct problem.")
    else
        return NomadProblem(internal_ref, nb_inputs, nb_outputs, type_bb_outputs, eval_bb, max_bb_eval)
    end

end


function freeNomadProblem(prob::NomadProblem)
    if prob.ref != C_NULL
        ccall((:freeNomadProblem, libnomadInterface), Cvoid, (Ptr{Cvoid},), prob.ref)
        prob.ref = C_NULL
    end
end

function solveProblem(prob::NomadProblem)
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
                       prob.ref, prob.x0, exists_feas_sol, x_feas_sol, outputs_feas_sol,
                       exists_inf_sol, x_inf_sol, outputs_inf_sol, prob)
    return (Bool(exists_feas_sol[]), x_feas_sol, outputs_feas_sol, 
            Bool(exists_inf_sol[]), x_inf_sol, outputs_inf_sol)
end
end # module
