"""

	runopt(eval,param)

Run NOMAD with settings defined by param and an
optimization problem defined by eval.

It returns an instance of the julia class "results"
that contains info about the run.

init has to be called before using runopt.

#Arguments :

	- eval::Function : a function of the form :

		(count_eval,bb_outputs)=eval(x)

		bb_outputs being a vector{Float64} containing
		the values of objectives functions and constraints
		for a given input vector x. NOMAD will seak for
		minimizing the objective functions and keeping
		constraints inferior to 0. count_eval is a
		boolean equal to true if the evaluation has
		to be taken into account by NOMAD.

	- param::Parameters : an instance of the julia mutable
		struct Parameters of which the attributes are the
		settings of the optimization process (dimension,
		output types, display options, bounds, etc.).

This function first wraps eval with a julia function eval wrap
that takes a C-double[] as argument and returns a C-double[].
Then it converts all param attributes into C++ variables and
calls the C++ function cpp main previously defined by
init_NOMADjl.


"""
function runopt(eval::Function,param::parameters)

	#check consistency of parameters with problem
	check_eval_param(eval,param)

	m=length(param.output_types)
	n=param.dimension

	#C++ wrapper for eval(x)
	function eval_wrap(x)
		return icxx"""
	    double * c_output = new double[$m+1];
	    $:(

			j_x = convert_cdoublearray_to_jlvector(x,n);

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
	evalwrap_void_ptr_struct = @cfunction($eval_wrap, Ptr{Cdouble}, (Ptr{Cdouble},))
	#void pointer toward eval_wrap
	evalwrap_void_ptr = evalwrap_void_ptr_struct.ptr

	#converting param attributes into C++ variables
	c_output_types=convert_vectorstring(param.output_types,m)
	c_display_stats=convert_string(param.display_stats)
	c_x0=convert_vector_to_nomadpoint(param.x0,n)
	c_lower_bound=convert_vector_to_nomadpoint(param.lower_bound,n)
	c_upper_bound=convert_vector_to_nomadpoint(param.upper_bound,n)
	c_solution_file=convert_string(param.solution_file)

	#prevent julia GC from removing eval_wrap during NOMAD routine
	GC.enable(false)

	c_result = @cxx cpp_runner(param.dimension,
					length(param.output_types),
					evalwrap_void_ptr,
					c_output_types,
					param.display_all_eval,
					c_display_stats,
					c_x0,
					c_lower_bound,
					c_upper_bound,
					param.max_bb_eval,
					param.display_degree,
					c_solution_file)

	GC.enable(true)

	return 	results(c_result,param)


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

function convert_vector_to_nomadpoint(jl_vector,size)
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
