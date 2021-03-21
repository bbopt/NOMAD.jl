using Libdl

if haskey(ENV, "JULIA_NOMAD_LIBRARY_PATH")
    const libnomadCInterface = joinpath(ENV["JULIA_NOMAD_LIBRARY_PATH"], "libnomadCInterface.$dlext")
    const libnomadAlgos = joinpath(ENV["JULIA_NOMAD_LIBRARY_PATH"], "libnomadAlgos.$dlext")
    const libnomadEval = joinpath(ENV["JULIA_NOMAD_LIBRARY_PATH"], "libnomadEval.$dlext")
    const libnomadUtils = joinpath(ENV["JULIA_NOMAD_LIBRARY_PATH"], "libnomadUtils.$dlext")
    const libsgtelib = joinpath(ENV["JULIA_NOMAD_LIBRARY_PATH"], "libsgtelib.$dlext")
else
    using NOMAD_jll
end

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
                                type_outputs::String)
    # wrap callback function
    eval_bb_cb = @cfunction(eval_bb_wrapper, Cint, (Cint, Ptr{Float64}, Cint, Ptr{Float64}, Ptr{Cint}, Ptr{Cvoid}))

    internal_ref = ccall((:createNomadProblem, libnomadCInterface), Ptr{Cvoid},
                        (Ptr{Cvoid}, Cint, Cint), eval_bb_cb, nb_inputs, nb_outputs) # function, nb_inputs, nb_outputs

    if internal_ref == C_NULL
        error("NOMAD.jl: Failed to construct problem.")
    else

        # TODO redundant with the main api functions: to clean later

        # Must fix dimensions before other parameters
        ccall((:addNomadValParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Cint), internal_ref, "DIMENSION", nb_inputs)

        # Use the non safe api function addNomadParam; enable to be more precise on the bounds according to Nomad.
        # Lower bound
        #  lower_bound_wrapper = "( " * join(map(elt -> elt == Inf || elt == -Inf ? "-" : string(elt), lower_bound), " ") * " )"
        #  ccall((:addNomadParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}), internal_ref, "LOWER_BOUND " * lower_bound_wrapper)
        if !any(elt-> elt == Inf || elt ==-Inf, lower_bound)
            ccall((:addNomadArrayOfDoubleParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Float64}), internal_ref, "LOWER_BOUND", lower_bound)
        end

        # Upper bound
        #  upper_bound_wrapper = "( " * join(map(elt -> elt == Inf || elt == -Inf ? "-" : string(elt), upper_bound), " ") * " )"
        #  ccall((:addNomadParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}), internal_ref, "UPPER_BOUND " * upper_bound_wrapper)
        if !any(elt-> elt == Inf || elt ==-Inf, upper_bound)
            ccall((:addNomadArrayOfDoubleParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Float64}), internal_ref, "UPPER_BOUND", upper_bound)
        end

        # Input types
        ccall((:addNomadStringParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{UInt8}), internal_ref, "BB_INPUT_TYPE", type_inputs)

        # Output types
        ccall((:addNomadStringParam, libnomadCInterface), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{UInt8}), internal_ref, "BB_OUTPUT_TYPE", type_outputs)

        return C_NomadProblem(internal_ref, nb_inputs, nb_outputs, eval_bb)
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
    # will be used to check if the algorithm finds a feasible or infeasible solution
    exists_feas_sol = Ref{Cint}(0)
    exists_inf_sol = Ref{Cint}(0)

    # final values
    x_feas_sol = zeros(Float64, prob.nb_inputs)
    x_inf_sol = zeros(Float64, prob.nb_inputs)
    outputs_feas_sol = zeros(Float64, prob.nb_outputs)
    outputs_inf_sol = zeros(Float64, prob.nb_outputs)

    statusflag = ccall((:solveNomadProblem, libnomadCInterface), Cint,
                       (Ptr{Cvoid}, Cint, Ptr{Float64}, # internal data, number of starting points, starting points,
                        Ptr{Cint}, Ptr{Float64}, Ptr{Float64}, # feasible solution flag, x_feas, outputs feas
                        Ptr{Cint}, Ptr{Float64}, Ptr{Float64}, # infeasible solution flag, x_inf, output inf
                        Any),
                       prob.ref, nb_starting_points, x0s,
                       exists_feas_sol, x_feas_sol, outputs_feas_sol,
                       exists_inf_sol, x_inf_sol, outputs_inf_sol, prob)
    return (Bool(exists_feas_sol[]), x_feas_sol, outputs_feas_sol,
            Bool(exists_inf_sol[]), x_inf_sol, outputs_inf_sol)
end
