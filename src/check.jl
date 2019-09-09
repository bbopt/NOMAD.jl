"""

	check_eval_param(eval,param)

Check consistency of eval(x) and nomadParameters given as arguments for `nomad()`

"""
function check_eval_param(eval::Function,param::nomadParameters,sgte)

	check_x0(param)
	check_everything_set(param)
	check_ranges(param)
	check_bounds(param)
	check_input_types(param)
	check_granularity(param)
	check_output_types(param.output_types)
	check_eval(eval,param)
	if !isnothing(sgte)
		try
			sgte::Function
		catch
			error("NOMAD.jl error : wrong nomad() inputs, sgte needs to be a Function")
		end
		check_sgte(sgte,eval,param)
	end

end

######################################################
		   	  	  #CHECKING METHODS#
######################################################

function check_x0(p)
	if typeof(p.x0[1])<:AbstractVector
		p.dimension==length(p.x0[1]) || error("NOMAD.jl error : wrong parameters, first initial point size is not consistent with dimension")
		for i=1:length(p.x0)
			length(p.x0[i])==p.dimension || error("NOMAD.jl error : wrong parameters, initial points must have the same length")
			p.x0[i]=try
				Float64.(p.x0[i])
			catch
				error("NOMAD.jl error : wrong parameters, initial points x0 should be vectors of numbers")
			end
		end
	else
		p.dimension==length(p.x0) || error("NOMAD.jl error : wrong parameters, initial point size is not consistent with dimension")
		x0=try
			Float64.(p.x0)
		catch
			error("NOMAD.jl error : wrong parameters, initial point x0 should be a vector of numbers")
		end
		p.x0=[x0]
	end
end

function check_everything_set(p)
	p.dimension > 0 ? nothing : error("NOMAD.jl error : wrong parameters, empty initial point x0")
	length(p.output_types) > 0 ? nothing : error("NOMAD.jl error : wrong parameters, empty output types vector")
	if p.stat_sum_target<Inf
		("STAT_SUM" in p.output_types) || @warn("NOMAD.jl warning : wrong parameters, no stat_sum defined to reach the target")
	end
end

function check_ranges(p)
	p.dimension <= 1000 ? nothing : error("NOMAD.jl error : dimension needs to be inferior to 1000")
	p.max_bb_eval >= 0 ? nothing : error("NOMAD.jl error : wrong parameters, negative max_bb_eval")
	p.max_time >= 0 ? nothing : error("NOMAD.jl error : wrong parameters, negative max_time")
	(0<=p.display_degree<=3) ? nothing : error("NOMAD.jl error : wrong parameters, display degree should be between 0 and 3")
end

function check_bounds(p)
	if length(p.lower_bound)>0
		length(p.lower_bound) == p.dimension ? nothing : error("NOMAD.jl error : wrong parameters, size of lower bound does not match dimension of the problem")
		for x0 in p.x0
			for i=1:p.dimension
				p.lower_bound[i]<=x0[i] ? nothing : error("NOMAD.jl error : wrong parameters, an initial state x0 is outside the bounds")
			end
		end
	end

	if length(p.upper_bound)>0
		length(p.upper_bound) == p.dimension ? nothing : error("NOMAD.jl error : wrong parameters, size of upper bound does not match dimension of the problem")
		for x0 in p.x0
			for i=1:p.dimension
				x0[i]<=p.upper_bound[i] ? nothing : error("NOMAD.jl error : wrong parameters, an initial state x0 is outside the bounds")
			end
		end
	end

	if (length(p.lower_bound)>0) && (length(p.upper_bound)>0)
		for i=1:p.dimension
			p.lower_bound[i]<p.upper_bound[i] ? nothing : error("NOMAD.jl error : wrong parameters, lower bounds should be inferior to upper bounds")
		end
	end
end

function check_input_types(p)
	if length(p.input_types)==0
		p.input_types=fill("R",p.dimension)
	elseif length(p.input_types)==p.dimension
		for x0 in p.x0
			for i=1:p.dimension
				if p.input_types[i]=="I"
					try
						convert(Int64,x0[i])
					catch
						error("NOMAD.jl error : wrong parameters, coordinate $i of an inital point x0 is not an integer as specified in nomadParameters.input_types")
					end
				elseif p.input_types[i]=="B"
					x0[i] in [0,1] ? nothing : error("NOMAD.jl error : wrong parameters, coordinate $i of an inital point x0 is not binary as specified in nomadParameters.input_types")
				elseif p.input_types[i]=="C"
					error("NOMAD.jl error : Categorical variables are not available in this version.")
				elseif p.input_types[i] != "R"
					error("NOMAD.jl error : wrong parameters, unknown input type $(p.input_types[i])")
				end
			end
		end
	else
		error("NOMAD.jl error : wrong parameters, number of input types does not match problem dimension")
	end
end

function check_granularity(p)
	length(p.granularity)==p.dimension || error("NOMAD.jl error : wrong parameters, nomadParameters.granularity does not have the same dimension as the initial point")
	for i=1:p.dimension
		if p.input_types[i]=="R"
			p.granularity[i]>=0 || error("NOMAD.jl error : wrong parameters, $(i)th coordinate of nomadParameters.granularity is negative")
			for x0 in p.x0
				try
					p.granularity[i]==0 || Int(x0[i]/p.granularity[i])
				catch
					error("NOMAD.jl error : wrong parameters, $(i)th coordinate of initial point is not a multiple of $(i)th granularity")
				end
			end
		elseif p.input_types[i] in ["I","B"]
			p.granularity[i] in [0,1] || @warn("NOMAD.jl warning : $(i)th coordinate of nomadParameters.granularity is automatically set to 1")
			p.granularity[i]=1
		end
	end
end

function check_output_types(ot)
	count_obj = 0
	count_avg = 0
	count_sum = 0
	for  i=1:length(ot)
		if ot[i]=="OBJ"
			count_obj = count_obj + 1
		elseif ot[i]=="STAT_AVG"
			count_obj = count_avg + 1
		elseif ot[i]=="STAT_SUM"
			count_obj = count_sum + 1
		end
		if !(ot[i] in ["OBJ","EB","PB","CNT_EVAL","NOTHING","-","UNDEFINED_BBO","CSTR","PEB","STAT_AVG","STAT_SUM","F","FILTER","PEB_E","PEB_P"])
			error("NOMAD.jl error : wrong parameters, unknown output type $(ot[i])")
		end
	end
	count_obj > 0 ? nothing : error("NOMAD.jl error : wrong parameters, at least one objective function is needed (set one OBJ in nomadParameters.output_types)")
	count_obj <= 1 ? nothing : error("NOMAD.jl error : multi-objective MADS is not supported by NOMAD.jl (do not set more than one OBJ in nomadParameters.output_types)")
	count_avg <= 1 ? nothing : error("NOMAD.jl error : wrong parameters, cannot set more than one STAT_AVG in nomadParameters.output_types")
	count_sum <= 1 ? nothing : error("NOMAD.jl error : wrong parameters, cannot set more than one STAT_SUM in nomadParameters.output_types")

	if ("F" in ot) && (("PEB" in ot) || ("PEB_E" in ot) || ("PEB_P" in ot) || ("PB" in ot) || ("CSTR" in ot))
		error("NOMAD.jl error : F constraint is not compatible with PB and PEB constraints")
	end
end

function check_eval(ev,p)

	(success,count_eval,bb_outputs) = try
		(success,count_eval,bb_outputs)=ev(p.x0[1])
	catch e
		@warn "eval(x) error with first initial point"
		error(e)
	end

	typeof(success)==Bool || error("NOMAD.jl error : first argument (success) returned by eval(x) is not a boolean")
	typeof(count_eval)==Bool || error("NOMAD.jl error : second argument (count_eval) returned by eval(x) is not a boolean")
	typeof(bb_outputs)<:AbstractVector || error("NOMAD.jl error : thirs argument (bb_ouputs) returned by eval(x) is not a vector")
	success ? nothing : error("NOMAD.jl error : success needs to be true for first initial point x0")

	try
		bb_outputs=Float64.(bb_outputs)
	catch
		error("NOMAD.jl error : bb_outputs returned by eval(x) needs to be convertible to Vector{Float64}")
	end

	length(bb_outputs)==length(p.output_types) ? nothing : error("NOMAD.jl error : wrong parameters, dimension of bb_outputs returned by eval(x) does not match number of output types set in parameters")
end

function check_sgte(sg,ev,p)

	(success,count_eval,bb_outputs)=sg(p.x0[1])

	if !isnothing(bb_outputs)
		typeof(success)==Bool ? nothing : error("NOMAD.jl error : success returned by surrogate(x) is not a boolean")
		typeof(count_eval)==Bool ? nothing : error("NOMAD.jl error : count_eval returned by surrogate(x) is not a boolean")

		try
			bb_outputs=Float64.(bb_outputs)
		catch
			error("NOMAD.jl error : bb_outputs returned by surrogate(x) needs to be convertible to Vector{Float64}")
		end

		length(bb_outputs)==length(p.output_types) ? nothing : error("NOMAD.jl error : wrong parameters, dimension of bb_outputs returned by surrogate(x) does not match number of output types set in parameters")
	end
end
