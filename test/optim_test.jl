function cost1(x)
	y=(x[1]+2*x[2]-7)^2+(2*x[1]+x[2]-5)^2
	return y
end

function cost2(x)
	y=(x[1]+2.12*x[2]-7.02)^2+(2.04*x[1]+x[2]-5.11)^2
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
    f=cost1(x)
    c=constraint1(x)
    count_eval=true
	bb_outputs = [f,c]
    return (count_eval,bb_outputs)
end

function eval2(x)
    f=cost1(x)
    c=constraint2(x)
    count_eval=true
	bb_outputs = [f,c]
    return (count_eval,bb_outputs)
end

function eval3(x)
	f=cost2(x)
	c=constraint1(x)
	count_eval=true
	bb_outputs = [f,c]
	return (count_eval,bb_outputs)
end

param1=nomadParameters([5,5],["OBJ","EB"])
param1.display_stats="bbe ( sol ) obj"
param1.display_all_eval=false
param1.max_bb_eval=100
param1.display_degree=2

param2=nomadParameters(param1)
param2.x0=[9,9]
param2.lower_bound=[1,1]
param2.upper_bound=[10,10]
param2.max_bb_eval=120


result1 = nomad(eval1,param1)
@test result1.success
test_results_consistency(result1,param1,eval1)
@test result1.best_feasible ≈ [1.0, 3.0]

result2 = nomad(eval2,param1)
@test result2.success
test_results_consistency(result2,param1,eval2)
@test result2.best_feasible ≈ [2.0, 2.2]

result3 = nomad(eval3,param2,eval1) #eval1 as a surrogate of eval3
@test result3.success
test_results_consistency(result3,param2,eval3)
