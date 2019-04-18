#surrogates
#valgrind ou équivalent : fuites de mémoire
#juliasmoothoptimizers, NLPmodels, ex Documenter

using NOMAD
using Test

function cost(x)
	y=(x[1]+2*x[2]-7)^2+(2*x[1]+x[2]-5)^2
	return y
end

function constraint1(x)
	y=0
	return y
end

function constraint2(x)
	y=2-x[1]
	return y
end

function eval1(x)
    f=cost(x)
    c=constraint1(x)
    count_eval=true
	bb_outputs = [f,c]
    return (count_eval,bb_outputs)
end

function eval2(x)
    f=cost(x)
    c=constraint2(x)
    count_eval=true
	bb_outputs = [f,c]
    return (count_eval,bb_outputs)
end

param1=NOMAD.parameters()
param1.dimension=2
param1.output_types=["OBJ","EB"]
param1.display_stats="bbe ( sol ) obj"
param1.display_all_eval=false
param1.x0=[2,3]
param1.max_bb_eval=100
param1.display_degree=2
param1.solution_file="sol.txt"

param2=NOMAD.parameters(param1)
param2.x0=[9,9]
param2.max_bb_eval=120
param2.display_degree=1

result1 = NOMAD.runopt(eval1,param1)
@test result1.success
@test result1.best_feasible ≈ [1.0, 3.0]
@test result1.bb_eval == param1.max_bb_eval

result2 = NOMAD.runopt(eval2,param1)
@test result2.success
@test result2.best_feasible ≈ [2.0, 2.2]
@test result2.bb_eval == param1.max_bb_eval

result3 = NOMAD.runopt(eval2,param2)
@test result3.success
@test result3.best_feasible ≈ [2.0, 2.2]
@test result3.bb_eval == param2.max_bb_eval
