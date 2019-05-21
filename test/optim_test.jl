function cost1(x)
	y=(x[1]+2*x[2]-7)^2+(2*x[1]+x[2]-5)^2
	return y
end

function cost2(x)
	y=(x[1]+2.12*x[2]-7.02)^2+(2.04*x[1]+x[2]-5.11)^2
	return y
end

function cost3(x)
	y=(x[1]^2+x[2]^2+x[3]^2)
	return y
end

function constraint(x)
	y=2-x[1]
	return y
end

function eval1(x)
    f=cost1(x)
	success=true
    count_eval=true
	bb_outputs = [f]
    return (success,count_eval,bb_outputs)
end

function eval2(x)
    f=cost1(x)
    c=constraint(x)
	success=true
    count_eval=true
	bb_outputs = [f,c]
    return (success,count_eval,bb_outputs)
end

function eval3(x)
	f=cost2(x)
	success=true
	count_eval=true
	bb_outputs = [f]
	return (success,count_eval,bb_outputs)
end

function eval4(x)
	f=cost3(x)
	c=constraint(x)
	success=true
	count_eval=true
	bb_outputs = [f,c,f,f]
	return (success,count_eval,bb_outputs)
end

param1=nomadParameters([5,5],["OBJ"])
param1.max_bb_eval=100

param2=nomadParameters(param1)
param2.output_types=["OBJ","PB"]
param2.x0=[9,9]
param2.lower_bound=[1,1]
param2.upper_bound=[10,10]
param2.max_bb_eval=50
param2.LH_init=20

param3=nomadParameters([5,5,5],["OBJ","EB","STAT_SUM","STAT_AVG"])
param3.max_time=10
param3.LH_iter=3
param3.display_stats="bbe ( sol ) obj ; stat_avg ; stat_sum"

param4=nomadParameters([5,1],["OBJ"])
param4.input_types=["I","B"]

#classic run
result1 = nomad(eval1,param1)
@test result1.success
test_results_consistency(result1,param1,eval1)
@test result1.best_feasible ≈ [1.0, 3.0]
disp(result1)

#PB constraint + LH initialization + bounding box
result2 = nomad(eval2,param2)
@test result2.success
test_results_consistency(result2,param2,eval2)
disp(result2)

#surrogate
result3 = nomad(eval3,param1,eval1) #eval1 as a surrogate of eval3
@test result3.success
test_results_consistency(result3,param1,eval3)
disp(result3)

#EB constraint + statistic sum + statistic average + LH iterations
result4 = nomad(eval4,param3)
@test result4.success
test_results_consistency(result4,param3,eval4)
disp(result4)

#Binary and integer variables
result5 = nomad(eval1,param4)
@test result5.success
test_results_consistency(result5,param4,eval1)
disp(result5)
