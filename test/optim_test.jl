using NOMADjl

path_to_nomad = "/home/pascpier/Documents/nomad.3.9.1-copy"

init(path_to_nomad)

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

function eval1(x)
    f=cost(x)
    c=constraint2(x)
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

param=NOMADjl.parameters()
param.dimension=2
param.output_types=["OBJ","EB"]
param.display_stats="bbe ( sol ) obj"
param.display_all_eval=false
param.x0=[2,4]
param.lower_bound=[-10,-10]
param.upper_bound=[10,10]
param.max_bb_eval=100
param.display_degree=2
param.solution_file="sol.txt"

result1=NOMADjl.runopt(eval1,param)

result2=NOMADjl.runopt(eval2,param)

param.x0=[9,9]

result3=NOMADjl.runopt(eval2,param)
