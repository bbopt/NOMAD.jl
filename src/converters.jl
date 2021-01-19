# Contains different implementations of linear converters
# to solve linear equalities constrained blackbox problems
# as described in the following article
#
# Audet, C., Le Digabel, S. & Peyrega, M.
# Linear equalities in blackbox optimization.
# Comput Optim Appl 61, 1–23 (2015). https://doi.org/10.1007/s10589-014-9708-2
#

import LinearAlgebra
import SparseArrays

######################################################
#     NOMAD Linear Bound reducers functions          #
######################################################
# The choice of these linear solvers relies on several criteria:
# - they are free (no need to get a professional licence).
# - they are implemented in pure Julia (no need to install some binaries).
# - they detect infeasibility.
# - they have a native interface (not JuMP or MOI)
# For the support of other solvers, please raise an issue on Github.
import Tulip

function tulip_solve_lower_bound_subproblem(ind::Int, φ_matrix::Matrix{Float64},
                                            initial_lower_bound::Vector{Float64},
                                            initial_upper_bound::Vector{Float64};
                                            display_level::Int = 0)::Float64
    @assert length(initial_lower_bound) == length(initial_upper_bound) == size(φ_matrix, 1) "NOMAD.jl error : wrong parameters, φ_matrix dimensions are not consistent with initial lower and upper bound dimensions" 
    @assert ind in 1:size(φ_matrix, 2) "NOMAD.jl error : wrong parameters, bound index is not consistent with  φ_matrix dimensions"

    # Initialize the model 
    linear_model = Tulip.Model{Float64}()

    m, n = size(φ_matrix)

    # objective vector
    c = zeros(n)
    c[ind] = 1.0

    # define problem 
    Tulip.load_problem!(linear_model.pbdata,
                        "LP", # problem name
                        true, c, 0.0,  # objective
                        SparseArrays.sparse(φ_matrix), initial_lower_bound, initial_upper_bound, # rows
                        fill(-Inf, n), fill(Inf, n),  # variable bounds
                        fill("", m), fill("", n)      # row and column names
    )

    # Set some parameters
    Tulip.set_parameter(linear_model, "OutputLevel", display_level)
    Tulip.set_parameter(linear_model, "Presolve_Level", 0) # disable presolve

    # Solve the problem
    Tulip.optimize!(linear_model)

    # Check termination status
    st = Tulip.get_attribute(linear_model, Tulip.Status())

    # Query objective value
    li = Tulip.get_attribute(linear_model, Tulip.ObjectiveValue())

    return li

end

function tulip_solve_upper_bound_subproblem(ind::Int, φ_matrix::Matrix{Float64},
                                            initial_lower_bound::Vector{Float64},
                                            initial_upper_bound::Vector{Float64};
                                            display_level::Int = 0)::Float64
    @assert length(initial_lower_bound) == length(initial_upper_bound) == size(φ_matrix, 1) "NOMAD.jl error : wrong parameters, φ_matrix dimensions are not consistent with initial lower and upper bound dimensions" 
    @assert ind in 1:size(φ_matrix, 2) "NOMAD.jl error : wrong parameters, bound index is not consistent with  φ_matrix dimensions"

    # Initialize the model 
    linear_model = Tulip.Model{Float64}()

    m, n = size(φ_matrix)

    # objective vector
    c = zeros(n)
    c[ind] = -1.0

    # define problem 
    Tulip.load_problem!(linear_model.pbdata,
                        "LP", # problem name
                        true, c, 0.0,  # objective
                        SparseArrays.sparse(φ_matrix), initial_lower_bound, initial_upper_bound, # rows
                        fill(-Inf, n), fill(Inf, n),  # variable bounds
                        fill("", m), fill("", n)      # row and column names
    )

    # Set some parameters
    Tulip.set_parameter(linear_model, "OutputLevel", display_level)
    Tulip.set_parameter(linear_model, "Presolve_Level", 0) # disable presolve

    # Solve the problem
    Tulip.optimize!(linear_model)

    # Check termination status
    st = Tulip.get_attribute(linear_model, Tulip.Status())

    # Query objective value
    ui = Tulip.get_attribute(linear_model, Tulip.ObjectiveValue())

    return -ui

end

######################################################
#              NOMAD linear converters               #
######################################################
abstract type AbstractConverter end

function convert_to_x(c::AbstractConverter, z::Vector{Float64})::Vector{Float64} end

function convert_to_z(c::AbstractConverter, x::Vector{Float64})::Vector{Float64} end

function get_nz_dimension(c::AbstractConverter)::Int end

struct SVDConverter <: AbstractConverter

    U::Matrix{Float64} # U factor
    S::Vector{Float64} # Singular values
    Vt::Matrix{Float64} # V factor

    b::Vector{Float64} # problem b vector

    function SVDConverter(A::Matrix{Float64}, b::Vector{Float64})
        @assert size(A, 1) == length(b) "NOMAD.jl error: wrong parameters, A and b dimensions are not consistent"
        F = LinearAlgebra.svd(A, full=true)
        return new(F.U, F.S, F.Vt, b)
    end
end

# Converter φ_SVD(z) = Vtᵀ × ⌈ S⁻¹ × Uᵀ × b ⌉
#                            ⌊      z       ⌋ 
function convert_to_x(c::SVDConverter, z::Vector{Float64})::Vector{Float64}
    m = length(c.S)

    b_intermediate = LinearAlgebra.transpose(c.U) * c.b

    x_intermediate = zeros(size(c.Vt, 2))
    x_intermediate[1:m] .= b_intermediate ./ c.S
    x_intermediate[m+1:end] .= z

    return LinearAlgebra.transpose(c.Vt) * x_intermediate
end

# Converter φ_SVD⁻¹(z) = (Vt × x)[m+1:end]
function convert_to_z(c::SVDConverter, x::Vector{Float64})::Vector{Float64}
    m = length(c.S)
    x_tmp = c.Vt * x
    return x_tmp[m+1:end]
end

function get_nz_dimension(c::SVDConverter)::Int
    return size(c.Vt, 2) - length(c.b)
end

function get_lower_bound(c::SVDConverter, initial_lower_bound::Vector{Float64}, initial_upper_bound::Vector{Float64};
                         display_level::Int = 0)::Vector{Float64}
    m = length(c.S)
    nz = get_nz_dimension(c)

    b_intermediate = LinearAlgebra.transpose(c.U) * c.b
    b_intermediate .= b_intermediate ./ c.S
    shiftvector = LinearAlgebra.transpose(c.Vt)[:, 1:m] * b_intermediate

    φ_matrix = LinearAlgebra.transpose(c.Vt)[:, m+1:end]

    lb = zeros(nz)
    # TODO maybe use a try catch
    for ind in 1:nz
        lb[ind] = tulip_solve_lower_bound_subproblem(ind, φ_matrix,
                                                     initial_lower_bound - shiftvector,
                                                     initial_upper_bound - shiftvector,
                                                     display_level = display_level)
    end
    return lb
end

function get_upper_bound(c::SVDConverter, initial_lower_bound::Vector{Float64}, initial_upper_bound::Vector{Float64};
                         display_level::Int = 0)::Vector{Float64}
    m = length(c.S)
    nz = length(initial_lower_bound) - m

    b_intermediate = LinearAlgebra.transpose(c.U) * c.b
    b_intermediate .= b_intermediate ./ c.S
    shiftvector = LinearAlgebra.transpose(c.Vt)[:, 1:m] * b_intermediate

    φ_matrix = LinearAlgebra.transpose(c.Vt)[:, m+1:end] 

    ub = zeros(nz)
    # TODO maybe use a try catch
    for ind in 1:nz
        ub[ind] = tulip_solve_upper_bound_subproblem(ind, φ_matrix,
                                                     initial_lower_bound - shiftvector,
                                                     initial_upper_bound - shiftvector,
                                                     display_level = display_level)
    end
    return ub
end

struct QRConverter <: AbstractConverter

    Q1::Matrix{Float64} # First part of the Q matrix
    Q2::Matrix{Float64} # Second part of the Q matrix

    P::Matrix{Float64} # intermediate matrix used in the conversion
    v_intermediate::BitArray # intermediate vector used in the conversion

    A::Matrix{Float64} # problem A matrix
    b::Vector{Float64} # problem b vector

    function QRConverter(A::Matrix{Float64}, b::Vector{Float64})
        @assert size(A, 1) == length(b) "NOMAD.jl error: wrong parameters, A and b dimensions are not consistent"
        m = size(A, 1)
        n = size(A, 2)

        F = LinearAlgebra.qr(transpose(A))
        Q1 = F.Q[:, 1:m]
        Q2 = F.Q[:, m+1:end]

        # construction of P, which is a inversible submatrix of Q2 of size (n - m) × (n - m)
        rk = 1
        v_intermediate = falses(n)
        P = zeros(n - m, n - m)
        for i in 1:n
            P[rk, :] .= Q2[i, :]
            if LinearAlgebra.rank(P) == rk
                v_intermediate[i] = 1
                rk += 1
            else
                P[rk, :] .= 0
            end
            if rk > n - m
                break
            end
        end

        return new(Q1, Q2, P, v_intermediate, A, b)
    end
end

# Converter φ_QR(z) = Aᵀ × (A Aᵀ)⁻¹ × b + Q₂ × z 
function convert_to_x(c::QRConverter, z::Vector{Float64})::Vector{Float64}
    M_tmp = c.A * transpose(c.A)
    return transpose(c.A) * inv(M_tmp) * c.b + c.Q2 * z
end

function convert_to_z(c::QRConverter, x::Vector{Float64})::Vector{Float64}
    nz = size(c.Q2, 2)
    v_tmp = x - transpose(c.A) * inv(c.A * transpose(c.A)) * c.b

    z_intermediate = zeros(nz)
    current_ind = 1 
    for ind in 1:length(c.v_intermediate)
        if c.v_intermediate == 1
            z_intermediate[current_ind] = v_tmp[ind]
            current_ind += 1
        end
    end
    return inv(c.P) * z_intermediate
end

function get_nz_dimension(c::QRConverter)::Int
    return size(c.Q2, 2)
end

function get_lower_bound(c::QRConverter, initial_lower_bound::Vector{Float64}, initial_upper_bound::Vector{Float64};
                         display_level::Int = 0)::Vector{Float64}
    nz = size(c.Q2, 2)

    M_tmp = c.A * transpose(c.A)

    shiftvector = transpose(c.A) * inv(M_tmp) * c.b 
    φ_matrix = c.Q2

    lb = zeros(nz)
    # TODO maybe use a try catch
    for ind in 1:nz
        lb[ind] = tulip_solve_lower_bound_subproblem(ind, φ_matrix,
                                                     initial_lower_bound - shiftvector,
                                                     initial_upper_bound - shiftvector,
                                                     display_level = display_level)
    end
    return lb
end

function get_upper_bound(c::QRConverter, initial_lower_bound::Vector{Float64}, initial_upper_bound::Vector{Float64};
                         display_level::Int = 0)::Vector{Float64}
    nz = size(c.Q2, 2)

    M_tmp = c.A * transpose(c.A)
    shiftvector = transpose(c.A) * inv(M_tmp) * c.b 

    φ_matrix = c.Q2

    ub = zeros(nz)
    # TODO maybe use a try catch
    for ind in 1:nz
        ub[ind] = tulip_solve_upper_bound_subproblem(ind, φ_matrix,
                                                     initial_lower_bound - shiftvector,
                                                     initial_upper_bound - shiftvector,
                                                     display_level = display_level)
    end
    return ub
end

# TODO : add BN abstract converter, but the implementation seems tricky
