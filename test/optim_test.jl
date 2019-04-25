using NOMAD
using Test

function test_results_consistency(res::results,param::parameters,eval::Function)

	@test length(res.best_feasible)==param.dimension
	@test length(res.bbo_best_feasible)==length(param.output_types)
	(count_eval,bbo_bf) = eval(res.best_feasible)
	@test bbo_bf ≈ res.bbo_best_feasible

	if res.infeasible
		@test length(res.best_infeasible)==param.dimension
		@test length(res.bbo_best_infeasible)==length(param.output_types)
		(count_eval,bbo_bi) = eval(res.best_infeasible)
		@test bbo_bi ≈ res.bbo_best_infeasible
	end

	@test result1.bb_eval <= param1.max_bb_eval

end

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
param2.output_types[2]="PB"
param2.max_bb_eval=120
param2.display_degree=1

result1 = NOMAD.runopt(eval1,param1)
@test result1.success
test_results_consistency(result1,param1,eval1)
@test result1.best_feasible ≈ [1.0, 3.0] #get the correct minimum

result2 = NOMAD.runopt(eval2,param1)
@test result2.success
test_results_consistency(result2,param1,eval2)
@test result2.best_feasible ≈ [2.0, 2.2]

result3 = NOMAD.runopt(eval2,param2)
@test result3.success
test_results_consistency(result3,param2,eval2)
@test result3.best_feasible ≈ [2.0, 2.2]
