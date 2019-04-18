"""

    results

mutable struct containing info about a NOMAD run, returned
by the method `runopt(eval,param)`.

To display the info contained in a object `result`, use :

    disp(result)

# **Attributes** :

- `best_feasible::Vector{Float64}` :
Feasible point found by NOMAD that best minimizes the
objective function.

- `bbo_best_feasible::Vector{Float64}` :
Outputs of `eval(x)` for the best feasible point.

- `best_infeasible::Vector{Float64}` :
Infeasible point found by NOMAD that best minimizes the
objective function.

- `bbo_best_infeasible::Vector{Float64}` :
outputs of `eval(x)` for the best infeasible point.

- `bb_eval::Int64` :
Number of `eval(x)` evaluations

"""
mutable struct results

    success::Bool
    best_feasible::Vector{Float64}
    bbo_best_feasible::Vector{Float64}
    infeasible::Bool
    best_infeasible::Vector{Float64}
    bbo_best_infeasible::Vector{Float64}
    bb_eval::Int64

    function results(c_res,param)

        best_feasible=unsafe_wrap(DenseArray,icxx"return ($c_res).bf;")
        bbo_best_feasible=unsafe_wrap(DenseArray,icxx"return ($c_res).bbo_bf;")

        infeasible = icxx"return ($c_res).infeasible;"

        if infeasible
            best_infeasible=unsafe_wrap(DenseArray,icxx"return ($c_res).bi;")
            bbo_best_infeasible=unsafe_wrap(DenseArray,icxx"return ($c_res).bbo_bi;")
        else
            best_infeasible=Vector{Float64}(undef,1)
            bbo_best_infeasible=Vector{Float64}(undef,1)
        end

        bb_eval = convert(Int64,icxx"return ($c_res).stats.get_bb_eval();")

        success=icxx"return ($c_res).success;"

        new(success,best_feasible,bbo_best_feasible,infeasible,best_infeasible,bbo_best_infeasible,bb_eval)

    end


end


function disp(r::results)
    println("\nbest feasible point : $(r.best_feasible) \n")
    println("black box outputs for best feasible point : $(r.bbo_best_feasible) \n")
    if r.infeasible
            println("best infeasible point : $(r.best_infeasible) \n")
            println("black box outputs for best infeasible point : $(r.bbo_best_infeasible) \n")
    end
    println("black box evaluations : $(r.bb_eval) \n")
end
