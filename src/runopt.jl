"""

	runopt(eval::Function,param::nomadParameters)

-> Run NOMAD with settings defined by param and an
optimization problem defined by eval(x).

-> Display stats from NOMAD in the REPL.

-> return an object of type *nomadResults* that contains
info about the run.

# **Arguments** :

- `eval::Function`

a function of the form :
		@test param.lower_bound<xi<param.upper_bound

	(count_eval,bb_outputs)=eval(x::Vector{Float64})

`bb_outputs` being a *vector{Float64}* containing
the values of objective function and constraints
for a given input vector `x`. NOMAD will seak for
minimizing the objective function and keeping
constraints inferior to 0. `count_eval` is a
*Bool* equal to true if the evaluation has
to be taken into account by NOMAD.

- `param::nomadParameters`

An object of type *Parameters* of which the
attributes are the settings of the optimization
process (dimension, output types, display options,
bounds, etc.).

# **Example** :

	using NOMAD

	function eval(x)
	    f=x[1]^2+x[2]^2
	    c=1-x[1]
	    count_eval=true
		bb_outputs = [f,c]
	    return (count_eval,bb_outputs)
	end

	param = nomadParameters()
	param.dimension = 2
	param.output_types = ["OBJ","EB"] #=first element of bb_outputs is the
		objective function, second is a constraint treated with the Extreme
		Barrier method=#
	param.x0 = [3,3] #Initial state for the optimization process

	result = runopt(eval,param)

"""
function runopt(eval::Function,param::nomadParameters)

	#=
	This function first wraps eval with a julia function eval wrap
	that takes a C-double[] as argument and returns a C-double[].
	Then it converts all param attributes into C++ variables and
	calls the C++ function cpp main previously defined by
	init.

	check consistency of nomadParameters with problem
	=#

	check_eval_param(eval,param)

	m=length(param.output_types)::Int64
	n=param.dimension::Int64


	#C++ wrapper for eval(x)
	function eval_wrap(x::Ptr{Float64})
		return icxx"""
	    double * c_output = new double[$m+1];
	    $:(

			j_x = convert_cdoublearray_to_jlvector(x,n)::Vector{Float64};

			(count_eval,bb_outputs)=eval(j_x);
			bb_outputs=convert(Vector{Float64},bb_outputs);

			#converting from Vector{Float64} to C-double[]
			for j=1:m
			    icxx"c_output[$j-1]=$(bb_outputs[j]);";
			end;

			#last coordinate of c_ouput corresponds to count_eval
			icxx"c_output[$m]=0.0;";
			if count_eval
				icxx"c_output[$m]=1.0;";
			end;

			nothing
	    );
	    return c_output;
	    """
	end


	#struct containing void pointer toward eval_wrap
	evalwrap_void_ptr_struct = @cfunction($eval_wrap, Ptr{Cdouble}, (Ptr{Cdouble},))::Base.CFunction
	#void pointer toward eval_wrap
	evalwrap_void_ptr = evalwrap_void_ptr_struct.ptr::Ptr{Nothing}


	#converting param attributes into C++ variables
	c_input_types=convert_vectorstring(param.input_types,n)::CvectorString
	c_output_types=convert_vectorstring(param.output_types,m)::CvectorString
	c_display_stats=convert_string(param.display_stats)::Cstring
	c_x0=convert_vector_to_nomadpoint(param.x0)::CnomadPoint
	c_lower_bound=convert_vector_to_nomadpoint(param.lower_bound)::CnomadPoint
	c_upper_bound=convert_vector_to_nomadpoint(param.upper_bound)::CnomadPoint

	#prevent julia GC from removing eval_wrap during NOMAD routine
	#GC.enable(false)

	c_result::Cresults = @cxx cpp_runner(param.dimension,
										length(param.output_types),
										evalwrap_void_ptr,
										c_input_types,
										c_output_types,
										param.display_all_eval,
										c_display_stats,
										c_x0,
										c_lower_bound,
										c_upper_bound,
										param.max_bb_eval,
										param.max_time,
										param.display_degree,
										false)


	#GC.enable(true)

	jl_result = nomadResults(c_result,param)

	return 	jl_result

end #runopt

#version with surrogate
function runopt(eval::Function,param::nomadParameters,sgte::Function)

	check_eval_param(eval,param)
	m=length(param.output_types)::Int64
	n=param.dimension::Int64

	#C++ wrapper for eval(x) and surrogate
	function eval_sgte_wrap(x::Ptr{Float64})
		return icxx"""
	    double * c_output = new double[$m+1];
	    $:(

			j_x = convert_cdoublearray_to_jlvector(x,n+1)::Vector{Float64};

			if convert(Bool,j_x[n+1]) #last coordinate of input decides if we call the surrogate or not
				(count_eval,bb_outputs)=sgte(j_x[1:n]);
			else
				(count_eval,bb_outputs)=eval(j_x[1:n]);
			end;
			bb_outputs=convert(Vector{Float64},bb_outputs);

			#converting from Vector{Float64} to C-double[]
			for j=1:m
			    icxx"c_output[$j-1]=$(bb_outputs[j]);";
			end;

			#last coordinate of c_ouput corresponds to count_eval
			icxx"c_output[$m]=0.0;";
			if count_eval
				icxx"c_output[$m]=1.0;";
			end;

			nothing
	    );
	    return c_output;
	    """
	end

	evalwrap_void_ptr_struct = @cfunction($eval_sgte_wrap, Ptr{Cdouble}, (Ptr{Cdouble},))::Base.CFunction
	evalwrap_void_ptr = evalwrap_void_ptr_struct.ptr::Ptr{Nothing}
	c_input_types=convert_vectorstring(param.input_types,n)::CvectorString
	c_output_types=convert_vectorstring(param.output_types,m)::CvectorString
	c_display_stats=convert_string(param.display_stats)::Cstring
	c_x0=convert_vector_to_nomadpoint(param.x0)::CnomadPoint
	c_lower_bound=convert_vector_to_nomadpoint(param.lower_bound)::CnomadPoint
	c_upper_bound=convert_vector_to_nomadpoint(param.upper_bound)::CnomadPoint
	#prevent julia GC from removing eval_wrap during NOMAD routine
	#GC.enable(false)
	c_result::Cresults = @cxx cpp_runner(param.dimension,
										length(param.output_types),
										evalwrap_void_ptr,
										c_input_types,
										c_output_types,
										param.display_all_eval,
										c_display_stats,
										c_x0,
										c_lower_bound,
										c_upper_bound,
										param.max_bb_eval,
										param.max_time,
										param.display_degree,
										true)

	#GC.enable(true)

	jl_result = nomadResults(c_result,param)

	return 	jl_result

end #runopt



######################################################
		   		#CONVERSION METHODS#
######################################################

function convert_cdoublearray_to_jlvector(c_vector,size)
	jl_vector = Vector{Float64}(undef,size)
	for i=1:size
		jl_vector[i]=icxx"return *($c_vector+$i-1);"
	end
	return jl_vector
end

function convert_vectorstring(jl_vectorstring,size)
	return icxx"""std::vector<std::string> c_vectorstring;
					$:(
						for i=1:size
							icxx"c_vectorstring.push_back($(pointer(jl_vectorstring[i])));";
						end;
						nothing
					);
					return c_vectorstring;"""
end

function convert_string(jl_string)
	return pointer(jl_string)
end

function convert_vector_to_nomadpoint(jl_vector)
	size = length(jl_vector)
	return icxx"""NOMAD::Double d;
				NOMAD::Point nomadpoint($size,d);
				$:(
					for i=1:size
						icxx"nomadpoint[int($i-1)]=$(jl_vector[i]);";
					end;
					nothing
				);
				return nomadpoint;"""
end
