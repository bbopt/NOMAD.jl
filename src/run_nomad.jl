"""

	nomad(eval::Function,param::nomadParameters)

-> Run NOMAD with settings defined by `param` and an
optimization problem defined by `eval`.

-> Display stats from NOMAD in the REPL.

-> return an object of type *nomadResults* that contains
info about the run.

# **Arguments** :

- `eval::Function`

a function of the form :

	(success,count_eval,bb_outputs)=eval(x::Vector{Number})

`bb_outputs` being a *vector{Number}* containing
the values of objective function and constraints
for a given input vector `x`. NOMAD will seak to
minimize the objective function and keeping
constraints inferior to 0.

`success` is a *Bool* set to `false` if the evaluation failed.

`count_eval` is a *Bool* equal to `true` if the black
box evaluation counting has to be incremented. Note
that statistic sums and averages are updated only if
`count_eval` is equal to `true`.

- `param::nomadParameters`

An object of type *nomadParameters* of which the
attributes are the settings of the optimization
process (dimension, output types, display options,
bounds, etc.).

# **Example** :

	using NOMAD

	function eval(x)
	    f=x[1]^2+x[2]^2
	    c=1-x[1]
	    success=true
	    count_eval=true
	    bb_outputs = [f,c]
	    return (success,count_eval,bb_outputs)
	end

	param = nomadParameters([5,5],["OBJ","EB"])
	#=first element of bb_outputs is the objective function ("OBJ"), second is a
		constraint treated with the Extreme Barrier method ("EB"). Initial point
		for optimization is [5,5]=#

	result = nomad(eval,param)

	disp(result)

"""
function nomad(eval::Function,param::nomadParameters;surrogate=nothing)

	has_sgte = !isnothing(surrogate)

	#=
	This function first wraps eval with a julia function eval_wrap
	that takes a C-double[] as argument and returns a C-double[].
	Then it converts all param into a C++ NOMAD::Parameters instance
	and calls the C++ function cpp_runner previously defined by
	init.
	=#

	check_eval_param(eval,param,surrogate) #check consistency of nomadParameters with problem

	m=length(param.output_types)::Int64
	n=param.dimension::Int64

	#C++ wrapper for eval(x) and surrogate
	function eval_wrap(x::Ptr{Float64})

		j_x = convert_cdoublearray_to_jlvector(x,n+1)::Vector{Float64}

		if has_sgte && j_x[n+1]==1  #very last coordinate of julia vector decides if we call the surrogate or not
			(success,count_eval,bb_outputs)=surrogate(j_x[1:n]);
		else
			(success,count_eval,bb_outputs)=eval(j_x[1:n]);
		end;
		bb_outputs=convert(Vector{Float64},bb_outputs);

		return icxx"""
	    double * c_output = new double[$m+2];
	    $:(
			#converting from Vector{Float64} to C-double[]
			for j=1:m
			    icxx"c_output[$j-1]=$(bb_outputs[j]);";
			end;
			nothing
		);
		//last coordinates of c_ouput correspond to success and count_eval
		c_output[$m]=0.0;
		c_output[$m+1]=0.0;
		if ($success) {c_output[$m]=1.0;}
		if ($count_eval) {c_output[$m+1]=1.0;}
	    return c_output;
    	"""
	end

	#struct containing void pointer toward eval_wrap
	evalwrap_void_ptr_struct = @cfunction($eval_wrap, Ptr{Cdouble}, (Ptr{Cdouble},))::Base.CFunction
	#void pointer toward eval_wrap
	evalwrap_void_ptr = evalwrap_void_ptr_struct.ptr::Ptr{Nothing}

	c_out = icxx"""int argc;
					char ** argv;
					NOMAD::Display out ( std::cout );
					out.precision ( NOMAD::DISPLAY_PRECISION_STD );
					NOMAD::begin ( argc , argv );
					return out;"""

	c_parameter = convert_parameter(param,n,m,has_sgte,c_out)

	#calling cpp_runner
	c_result = @cxx cpp_runner(c_parameter,
								c_out,
								param.dimension,
								length(param.output_types),
								evalwrap_void_ptr,
								("STAT_AVG" in param.output_types),
								("STAT_SUM" in param.output_types),
								has_sgte)

	#creating nomadResults object to return
	jl_result = nomadResults(c_result,param)

	return 	jl_result

end #nomad



######################################################
		   		#CONVERSION METHODS#
######################################################

function convert_parameter(param,n,m,has_sgte,out)

	#converting param attributes into C++ variables
	c_input_types=convert_input_types(param.input_types,n)
	c_output_types=convert_output_types(param.output_types,m)
	c_display_stats=convert_string(param.display_stats)
	c_x0=convert_x0_to_nomadpoints_list(param.x0)
	c_lower_bound=convert_vector_to_nomadpoint(param.lower_bound)
	c_upper_bound=convert_vector_to_nomadpoint(param.upper_bound)
	c_granularity=convert_vector_to_nomadpoint(param.granularity)

	return icxx"""NOMAD::Parameters * p = new NOMAD::Parameters( $out );

			p->set_DIMENSION ($n);
			p->set_BB_INPUT_TYPE ( $c_input_types );
			p->set_BB_OUTPUT_TYPE ( $c_output_types );
			p->set_DISPLAY_ALL_EVAL( $(param.display_all_eval) );
			p->set_DISPLAY_STATS( $c_display_stats );
			for (int i = 0; i < ($c_x0).size(); ++i) {p->set_X0( ($c_x0)[i] );}  // starting points
			if (($c_lower_bound).size()>0) {p->set_LOWER_BOUND( $c_lower_bound );}
			if (($c_upper_bound).size()>0) {p->set_UPPER_BOUND( $c_upper_bound );}
			if ($(param.max_bb_eval)>0) {p->set_MAX_BB_EVAL($(param.max_bb_eval));}
			if ($(param.max_time)>0) {p->set_MAX_TIME($(param.max_time));}
			p->set_DISPLAY_DEGREE($(param.display_degree));
			p->set_HAS_SGTE($has_sgte);
			if ($has_sgte) {p->set_SGTE_COST($(param.sgte_cost));}
			p->set_STATS_FILE("temp.txt","bbe | sol | bbo");
			p->set_LH_SEARCH($(param.LH_init),$(param.LH_iter));
			p->set_OPPORTUNISTIC_LH($(param.opportunistic_LH));
			p->set_GRANULARITY($c_granularity);
			p->set_STOP_IF_FEASIBLE($(param.stop_if_feasible));
			p->set_VNS_SEARCH($(param.VNS_search));
			if ($(param.stat_sum_target)>0) {p->set_STAT_SUM_TARGET($(param.stat_sum_target));}
			p->set_SEED($(param.seed));

			return p;"""
end


function convert_cdoublearray_to_jlvector(c_vector,size)
	jl_vector = Vector{Float64}(undef,size)
	for i=1:size
		jl_vector[i]=icxx"return *($c_vector+$i-1);"
	end
	return jl_vector
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

function convert_x0_to_nomadpoints_list(jl_x0)
	return icxx"""std::vector<NOMAD::Point> c_x0;
				$:(
					for x0 in jl_x0
						xZero=convert_vector_to_nomadpoint(x0);
						icxx"c_x0.push_back($xZero);";
					end;
					nothing
				);
				return c_x0;"""
end

function convert_input_types(it,n)
	return icxx"""vector<NOMAD::bb_input_type> bbit ($n);
					$:(
						for i=1:n
							if it[i]=="B"
								icxx"bbit[$i-1]=NOMAD::BINARY;";
							elseif it[i]=="I"
								icxx"bbit[$i-1]=NOMAD::INTEGER;";
							elseif it[i]=="C"
								icxx"bbit[$i-1]=NOMAD::CATEGORICAL;";
							else
								icxx"bbit[$i-1]=NOMAD::CONTINUOUS;";
							end;
						end;
							nothing
					);
					return bbit;"""
end

function convert_output_types(ot,m)
	icxx"""vector<NOMAD::bb_output_type> bbot ($m);
			$:(
				for j=1:m
					if ot[j]=="OBJ"
						icxx"bbot[$j-1]=NOMAD::OBJ;";
					elseif ot[j]=="EB"
						icxx"bbot[$j-1]=NOMAD::EB;";
					elseif ot[j] in ["PB","CSTR"]
						icxx"bbot[$j-1]=NOMAD::PB;";
					elseif ot[j] in ["PEB","PEB_P"]
						icxx"bbot[$j-1]=NOMAD::PEB_P;";
					elseif ot[j]=="PEB_E"
						icxx"bbot[$j-1]=NOMAD::PEB_E;";
					elseif ot[j] in ["F","FILTER"]
						icxx"bbot[$j-1]=NOMAD::FILTER;";
					elseif ot[j]=="CNT_EVAL"
						icxx"bbot[$j-1]=NOMAD::CNT_EVAL;";
					elseif ot[j]=="STAT_AVG"
						icxx"bbot[$j-1]=NOMAD::STAT_AVG;";
					elseif ot[j]=="STAT_SUM"
						icxx"bbot[$j-1]=NOMAD::STAT_SUM;";
					else
						icxx"bbot[$j-1]=NOMAD::UNDEFINED_BBO;";
					end;
				end;
			);
			return bbot;"""
end
