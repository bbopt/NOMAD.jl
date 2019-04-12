"""

	check_eval_param(eval,param)

Check consistency of eval(x) and parameters given as arguments for runopt

"""
function check_eval_param(eval::Function,param::parameters)
	
	param.dimension > 0 ? nothing : error("NOMADjl error : wrong parameters, negative dimension")
	length(param.x0) == param.dimension ? nothing : error("NOMADjl error : wrong parameters, size of initial state x0 does not match dimension of the problem")
	length(param.lower_bound) == param.dimension ? nothing : error("NOMADjl error : wrong parameters, size of lower bound does not match dimension of the problem")
	length(param.upper_bound) == param.dimension ? nothing : error("NOMADjl error : wrong parameters, size of upper bound does not match dimension of the problem")
	param.max_bb_eval > 0 ? nothing : error("NOMADjl error : wrong parameters, negative max_bb_eval")
	(0<=param.display_degree<=3) ? nothing : error("NOMADjl error : wrong parameters, display degree should be between 0 and 3")

	for i=1:param.dimension
		param.lower_bound[i]<=param.x0[i]<=param.upper_bound[i] ? nothing : error("NOMADjl error : wrong parameters, initial state x0 is outside the bounds")
	end


	(count_eval,bb_outputs)=try
		eval(param.x0)
	catch
		error("NOMADjl error : ill-defined eval(x), try checking for dimension inconsistencies")
	end

	typeof(count_eval)==Bool ? nothing : error("NOMADjl error : count_eval returned by eval(x) is not a boolean")

	try
		bb_outputs=convert(Vector{Float64},bb_outputs)
	catch
		error("NOMADjl error : bb_outputs returned by eval(x) needs to be convertible to Vector{Float64}")
	end

	length(bb_outputs)==length(param.output_types) ? nothing : error("NOMADjl error : wrong parameters, dimension of bb_outputs returned by eval(x) does not match length of param.output_types")

end
