function eval1(x)
    f=(x[1]+2*x[2]-7)^2+(2*x[1]+x[2]-5)^2
	success=true
    count_eval=true
	bb_outputs = [f]
    return (success,count_eval,bb_outputs)
end

function eval2(x)
    f=(x[1]+2*x[2]-7)^2+(2*x[1]+x[2]-5)^2
    c=2-x[1]
	success=true
    count_eval=true
	bb_outputs = [f,c]
    return (success,count_eval,bb_outputs)
end

function eval3(x)
	f=(x[1]+2.12*x[2]-7.02)^2+(2.04*x[1]+x[2]-5.11)^2
	success=true
	count_eval=true
	bb_outputs = [f]
	return (success,count_eval,bb_outputs)
end

function eval4(x)
	f=(x[1]^2+x[2]^2+x[3]^2)
	c=2-x[1]
	success=true
	count_eval=true
	bb_outputs = [f,c,f,f]
	return (success,count_eval,bb_outputs)
end

function eval5(x)
	f=(x[1]^2+x[2]^2+x[3]^2)
	success=true
	count_eval=true
	bb_outputs = [f]
	return (success,count_eval,bb_outputs)
end

param1=nomadParameters([5,5],["OBJ"])
param1.max_bb_eval=100

param2=nomadParameters([5,5],["OBJ","PB"])
param2.max_bb_eval=50
param2.LH_init=20

param3=nomadParameters(param1)
param3.max_time=2
param3.sgte_cost=10
param3.lower_bound=[1,1]
param3.upper_bound=[10,10]
param3.VNS_search=true

param4=nomadParameters([5,5,5],["OBJ","EB","STAT_SUM","STAT_AVG"])
param4.LH_iter=3
param4.display_stats="bbe ( sol ) obj ; stat_avg ; stat_sum"
param4.stat_sum_target=50000

param5=nomadParameters([5,1,5.2],["OBJ"])
param5.input_types = ["I","B","R"]
param5.granularity[3]=0.2

param6=nomadParameters([[-14,70],[1,2]],["OBJ","PB"])
param6.display_all_eval=true
param6.stop_if_feasible=true

#classic run
result1 = nomad(eval1,param1)
@test result1.success
test_results_consistency(result1,param1,eval1)
@test result1.best_feasible ≈ [1.0, 3.0]
disp(result1)

#PB constraint + LH initialization
result2 = nomad(eval2,param2)
@test result2.success
test_results_consistency(result2,param2,eval2)
disp(result2)

#surrogate + VNS search + bounding box
result3 = nomad(eval3,param3;surrogate=eval1) #eval1 as a surrogate of eval3
@test result3.success
test_results_consistency(result3,param3,eval3)
disp(result3)

#EB constraint + statistic sum + statistic average + LH iterations
result4 = nomad(eval4,param4)
@test result4.success
test_results_consistency(result4,param4,eval4)
disp(result4)

#Binary and integer variables + granularity
result5 = nomad(eval5,param5)
@test result5.success
test_results_consistency(result5,param5,eval5)
disp(result5)

#stop if feasible + several initial points
result6 = nomad(eval2,param6)
@test result6.success
test_results_consistency(result6,param6,eval2)
disp(result6)
