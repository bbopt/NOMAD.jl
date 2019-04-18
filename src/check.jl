"""

	check_eval_param(eval,param)

Check consistency of eval(x) and parameters given as arguments for runopt

"""
function check_eval_param(eval::Function,param::parameters)

	param.dimension > 0 ? nothing : error("NOMAD.jl error : dimension needs to be set in parameters (and > 0), type ? and parameters for help")
	length(param.output_types) > 0 ? nothing : error("NOMAD.jl error : output types needs to be set in parameters, type ? and parameters for help")
	length(param.x0) > 0 ? nothing : error("NOMAD.jl error : initial point x0 needs to be set in parameters, type ? and parameters for help")


	length(param.x0) == param.dimension ? nothing : error("NOMAD.jl error : wrong parameters, size of initial state x0 does not match dimension of the problem")
	param.max_bb_eval >= 0 ? nothing : error("NOMAD.jl error : wrong parameters, negative max_bb_eval")
	(0<=param.display_degree<=3) ? nothing : error("NOMAD.jl error : wrong parameters, display degree should be between 0 and 3")

	if length(param.lower_bound)>0
		length(param.lower_bound) == param.dimension ? nothing : error("NOMAD.jl error : wrong parameters, size of lower bound does not match dimension of the problem")
		param.lower_bound[i]<=param.x0[i] ? nothing : error("NOMAD.jl error : wrong parameters, initial state x0 is outside the bounds")
	end

	if length(param.upper_bound)>0
		length(param.upper_bound) == param.dimension ? nothing : error("NOMAD.jl error : wrong parameters, size of upper bound does not match dimension of the problem")
		param.x0[i]<=param.upper_bound[i] ? nothing : error("NOMAD.jl error : wrong parameters, initial state x0 is outside the bounds")
	end

	if (length(param.lower_bound)>0) && (length(param.upper_bound)>0)
		for i=1:param.dimension
			param.lower_bound[i]<param.upper_bound[i] ? nothing : error("NOMAD.jl error : wrong parameters, lower bounds should be inferior to upper bounds")
		end
	end


	(count_eval,bb_outputs)=try
		eval(param.x0)
	catch
		error("NOMAD.jl error : ill-defined eval(x), try checking for dimension inconsistencies")
	end

	typeof(count_eval)==Bool ? nothing : error("NOMAD.jl error : count_eval returned by eval(x) is not a boolean")

	try
		bb_outputs=convert(Vector{Float64},bb_outputs)
	catch
		error("NOMAD.jl error : bb_outputs returned by eval(x) needs to be convertible to Vector{Float64}")
	end

	length(bb_outputs)==length(param.output_types) ? nothing : error("NOMAD.jl error : wrong parameters, dimension of bb_outputs returned by eval(x) does not match number of output types set in parameters")

end
