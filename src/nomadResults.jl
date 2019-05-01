"""

    nomadResults

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

- `inter_states::Matrix{Float64}` :
List of intermediate states evaluated during the
optimization process. Lines correspond to successive
states that are browsed and each column correspond to
a dimension.

- `inter_bbo::Vector{Float64}` :
List of black box outputs corresponding to
intermediate states evaluated during the
optimization process. Lines correspond to successive
states that are browsed and each column correspond
to  an output (same order as defined in
nomadParameters.output_types).

- `inter_bbo::Vector{Int64}` :
List of black box evaluations numbers required
to reach each of the states available in inter_states.

"""
mutable struct nomadResults

    success::Bool
    best_feasible::Vector{Float64}
    bbo_best_feasible::Vector{Float64}
    infeasible::Bool
    best_infeasible::Vector{Float64}
    bbo_best_infeasible::Vector{Float64}
    bb_eval::Int64
    inter_bbe::Vector{Int64}
    inter_states::Matrix{Float64}
    inter_bbo::Matrix{Float64}

    function nomadResults(c_res,param)

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

        rd_stats = open("temp.0.txt")
        stat_lines = readlines(rd_stats)
        close(rd_stats)
        rm("temp.0.txt")
        k = length(stat_lines)
        inter_bbe = Vector{Int64}(undef,k)
        inter_states = Matrix{Float64}(undef,k,param.dimension)
        inter_bbo = Matrix{Float64}(undef,k,length(param.output_types))
        for index = 1:k
            data = split(stat_lines[index],"|",keepempty=false)
            inter_bbe[index] = parse(Int64,data[1])
            x=split(data[2]," ",keepempty=false)
            for i=1:param.dimension
                inter_states[index,i]=parse(Float64,x[i])
            end
            bbo=split(data[3]," ",keepempty=false)
            for i=1:length(param.output_types)
                inter_bbo[index,i]=parse(Float64,bbo[i])
            end
            index += 1
        end

        new(success,best_feasible,bbo_best_feasible,infeasible,best_infeasible,
        bbo_best_infeasible,bb_eval,inter_bbe,inter_states,inter_bbo)

    end

end


function disp(r::nomadResults)
    println("\nbest feasible point : $(r.best_feasible) \n")
    println("black box outputs for best feasible point : $(r.bbo_best_feasible) \n")
    if r.infeasible
            println("best infeasible point : $(r.best_infeasible) \n")
            println("black box outputs for best infeasible point : $(r.bbo_best_infeasible) \n")
    end
    println("black box evaluations : $(r.bb_eval) \n")
end
