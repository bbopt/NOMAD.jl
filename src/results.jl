"""

        results

mutable struct containing info about a NOMAD run.

It is returned by the method runopt(eval,param).
The method disp(r::results) allows to display info.

#Attributes :

        - best_feasible::Vector{Float64} : feasible point found by NOMAD
        that best minimizes the objective function.

        - bbo_best_feasible::Vector{Float64} : outputs of eval(x) for
        the best feasible point.

        - best_infeasible::Vector{Float64} : infeasible point found by NOMAD
        that best minimizes the objective function.

        - bbo_best_infeasible::Vector{Float64} : outputs of eval(x) for
        the best infeasible point.

        - bb_eval::Int64 : Number of eval(x) evaluations +
        cache hits (can be superior to max_bb_eval defined in
        parameters)

"""
mutable struct results

    best_feasible::Vector{Float64}
    bbo_best_feasible::Vector{Float64}
    infeasible::Bool
    best_infeasible::Vector{Float64}
    bbo_best_infeasible::Vector{Float64}
    bb_eval::Int64

    function results(c_res,param)

        best_feasible=Vector{Float64}(undef,param.dimension)
        for i=1:param.dimension
                best_feasible[i]=convert(Float64,icxx"return ($c_res).best_feasible->value($i-1);")
        end

        bbo_best_feasible=Vector{Float64}(undef,param.dimension)
        for i=1:param.dimension
                bbo_best_feasible[i]=convert(Float64,icxx"return (($c_res).best_feasible->get_bb_outputs())[int($i-1)].value();")
        end

        best_infeasible=Vector{Float64}(undef,param.dimension)
        bbo_best_infeasible=Vector{Float64}(undef,param.dimension)

        infeasible = icxx"return (($c_res).best_infeasible != NULL);"

        if infeasible
                for i=1:param.dimension
                        best_infeasible[i]=convert(Float64,icxx"return ($c_res).best_infeasible->value($i-1);")
                end

                for i=1:param.dimension
                        bbo_best_infeasible[i]=convert(Float64,icxx"return (($c_res).best_infeasible->get_bb_outputs())[int($i-1)].value();")
                end
        end


        bb_eval = convert(Int64,icxx"return ($c_res).stats.get_eval();")

        new(best_feasible,bbo_best_feasible,infeasible,best_infeasible,bbo_best_infeasible,bb_eval)

    end


end


function disp(r::results)
    println("\nbest feasible point : $(r.best_feasible) \n")
    println("black box outputs for best feasible point : $(r.bbo_best_feasible) \n")
    if r.infeasible
            println("best infeasible point : $(r.best_infeasible) \n")
            println("black box outputs for best infeasible point : $(r.bbo_best_infeasible) \n")
    end
    println("black box evaluations + cache hits : $(r.bb_eval) \n")
end
