function NOMAD(eval,param)

	m=length(param.output_types) #nombre de sorties de eval (fonctions objectif et contraintes)
	n=param.dimension #dimension du problème

	function eval_wrap(x) #C-wrapper pour la fonction eval (prend en entrée un C-double[] et renvoie un C-double[])
		return icxx"""
	    double * c_output = new double[$m+1]; //déclaration du tableau à retourner (valeurs de la fonction objectives, des contraintes et count_eval sous forme de double)
	    $:(

	        j_x = Vector{Float64}(undef,n); #conversion du C-double[] en vecteur julia
	        for i=1:n
	            j_x[i]=icxx"return *($x+$i-1);";
	        end;

			(count_eval,bb_outputs)=eval(j_x);

	        for j=1:m #conversion du vecteur retournée par eval en C-double[]
	            icxx"*(c_output+$j-1)=$(bb_outputs[j]);";
	        end;

			icxx"*(c_output+$m)=0.0;";
			if count_eval
				icxx"*(c_output+$m)=1.0;";
			end;

	        nothing
	    );
	    return c_output;
	    """
	end

	f_void_ptr = @cfunction($eval_wrap, Ptr{Cdouble}, (Ptr{Cdouble},)) # struct contenant un void-pointeur vers eval_wrap
	f_void_ptr2 = f_void_ptr.ptr #void-pointeur vers eval_wrap

	#conversion des attributs de l'instance julia parameters en objets C++
	c_output_types=icxx"""std::vector<std::string> types;
						$:(
							for i=1:m
								icxx"types.push_back($(pointer(param.output_types[i])));";
							end;
							nothing
						);
						return types;"""
	c_display_stats=pointer(param.display_stats)
	c_x0=icxx"""NOMAD::Double d;
				NOMAD::Point x0($n,d);
				$:(
					for i=1:n
						icxx"x0[int($i-1)]=$(param.x0[i]);";
					end;
					nothing
				);
				return x0;"""
	c_lower_bound=icxx"""NOMAD::Double d;
						NOMAD::Point lb($n,d);
						$:(
							for i=1:n
								icxx"lb[int($i-1)]=$(param.lower_bound[i]);";
							end;
							nothing
						);
						return lb;"""
	c_upper_bound=icxx"""NOMAD::Double d;
						NOMAD::Point ub($n,d);
						$:(
							for i=1:n
								icxx"ub[int($i-1)]=$(param.upper_bound[i]);";
							end;
							nothing
						);
						return ub;"""
	c_solution_file=pointer(param.solution_file)

	#on veut empêcher le gc de supprimer eval_wrap trop tôt
	GC.enable(false)

	@cxx cpp_main(param.dimension,
					length(param.output_types),
					f_void_ptr2,
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

end

#WARNING => modified Cxx code at /home/pascpier/.julia/dev/Cxx/src/cxxstr.jl:217 to avoid error : pointer from objref cannot be used on immutable objects
