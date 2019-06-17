"""

    nomadResults

mutable struct containing info about a NOMAD run, returned
by the method `nomad(eval,param)`.

To display the info contained in a object `result::nomadResults`, use :

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
optimization process. It is a matrix whose lines
correspond to successive states that are browsed.
Each column correspond to a dimension.

- `inter_bbo::Vector{Float64}` :
List of black box outputs corresponding to
intermediate states evaluated during the
optimization process. It is a matrix whose lines
correspond to successive states that are browsed.
Each column correspond to an output (same order as
defined in nomadParameters.output_types).

- `inter_bbe::Vector{Int64}` :
List of black box evaluations numbers required
to reach each of the states available in inter_states.

- `stat_avg::Float64` :
Statistic average computed during optimization

- `stat_sum::Float64` :
Statistic sum computed during optimization

"""
mutable struct nomadResults

    success::Bool
    best_feasible::Vector{Float64}
    bbo_best_feasible::Vector{Float64}
    has_feasible::Bool
    has_infeasible::Bool
    best_infeasible::Vector{Float64}
    bbo_best_infeasible::Vector{Float64}
    bb_eval::Int64
    inter_bbe::Vector{Int64}
    inter_states::Matrix{Float64}
    inter_bbo::Matrix{Float64}
    has_stat_avg::Bool
    stat_avg::Float64
    has_stat_sum::Bool
    stat_sum::Float64
    seed::Int64

    function nomadResults(c_res,param)


        has_feasible = icxx"return ($c_res).has_feasible;"

        if has_feasible
            best_feasible=unsafe_wrap(DenseArray,icxx"return ($c_res).bf;")
            for i=1:param.dimension
                if param.input_types[i] in ["I","B"]
                    best_feasible[i]=convert(Int64,best_feasible[i])
                end
            end
            bbo_best_feasible=unsafe_wrap(DenseArray,icxx"return ($c_res).bbo_bf;")
        else
            best_feasible=Vector{Float64}(undef,1)
            bbo_best_feasible=Vector{Float64}(undef,1)
        end

        has_infeasible = icxx"return ($c_res).has_infeasible;"

        if has_infeasible
            best_infeasible=unsafe_wrap(DenseArray,icxx"return ($c_res).bi;")
            for i=1:param.dimension
                if param.input_types[i] in ["I","B"]
                    best_infeasible[i]=convert(Int64,best_infeasible[i])
                end
            end
            bbo_best_infeasible=unsafe_wrap(DenseArray,icxx"return ($c_res).bbo_bi;")
        else
            best_infeasible=Vector{Float64}(undef,1)
            bbo_best_infeasible=Vector{Float64}(undef,1)
        end

        bb_eval = convert(Int64,icxx"return ($c_res).bb_eval;")

        success=icxx"return ($c_res).success;"

        seed=icxx"return ($c_res).seed;"
        rd_stats = open("temp." * string(seed) * ".txt")
        stat_lines = readlines(rd_stats)
        close(rd_stats)
        rm("temp." * string(seed) * ".txt")
        k = length(stat_lines)
        inter_bbe = Vector{Int64}(undef,k)
        inter_states = Matrix{Float64}(undef,k,param.dimension)
        inter_bbo = Matrix{Float64}(undef,k,length(param.output_types))
        try
            for index = 1:k
                data = split(stat_lines[index],"|",keepempty=false)
                inter_bbe[index] = parse(Int64,data[1])
                x=split(data[2]," ",keepempty=false)
                for i=1:param.dimension
                    inter_states[index,i]=parse(Float64,x[i])
                    if param.input_types[i] in ["I","B"]
                        inter_states[index,i]=convert(Int64,inter_states[index,i])
                    end
                end
                bbo=split(data[3]," ",keepempty=false)
                for i=1:length(param.output_types)
                    inter_bbo[index,i]=parse(Float64,bbo[i])
                end
                index += 1
            end
        catch
            @error("NOMAD.jl error : No solution found")
        end

        if "STAT_AVG" in param.output_types
            has_stat_avg=true
            stat_avg=icxx"return ($c_res).stat_avg;"
        else
            has_stat_avg=false
            stat_avg=0
        end

        if "STAT_SUM" in param.output_types
            has_stat_sum=true
            stat_sum=icxx"return ($c_res).stat_sum;"
        else
            has_stat_sum=false
            stat_sum=0
        end

        new(success,best_feasible,bbo_best_feasible,has_feasible,has_infeasible,best_infeasible,
        bbo_best_infeasible,bb_eval,inter_bbe,inter_states,inter_bbo,
        has_stat_avg,stat_avg,has_stat_sum,stat_sum,seed)

    end

end


function disp(r::nomadResults)

    if r.has_feasible
        println("\nbest feasible point : $(r.best_feasible) \n")
        println("black box outputs for best feasible point : $(r.bbo_best_feasible) \n")
    end
    if r.has_infeasible
        println("best infeasible point : $(r.best_infeasible) \n")
        println("black box outputs for best infeasible point : $(r.bbo_best_infeasible) \n")
    end
    println("black box evaluations : $(r.bb_eval) \n")
    if r.has_stat_avg
        println("average statistic : $(r.stat_avg) \n")
    end
    if r.has_stat_sum
        println("sum statistic : $(r.stat_sum) \n")
    end
    println("seed : $(r.seed) \n")

end
