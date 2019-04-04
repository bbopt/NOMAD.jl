function cost(x)
	y=(x[1]+2*x[2]-7)^2+(2*x[1]+x[2]-5)^2
	convert(Float64,y)
	return y
end

function constraint(x)
	y=2-x[1]
	convert(Float64,y)
	return y
end

function eval_(x) #l'utilisateur crée d'abord une fonction retournant le coût à optimiser et les contraintes
    f=cost(x)
    c=constraint(x)
    count_eval=true
	bb_outputs = [f,c]
    return (count_eval,bb_outputs)
end

path_to_nomad = "/home/pascpier/Documents/nomad.3.9.1-copy"

using Cxx
using Libdl
include("Parameters.jl")

addHeaderDir(path_to_nomad * "/lib", kind=C_System)
Libdl.dlopen(path_to_nomad * "/lib/libnomad.so", Libdl.RTLD_GLOBAL)
Libdl.dlopen(path_to_nomad * "/lib/libsgtelib.so", Libdl.RTLD_GLOBAL)
cxxinclude(path_to_nomad * "/ext/sgtelib/src/sgtelib.hpp")
cxxinclude(path_to_nomad * "/hpp/nomad.hpp")

param_=parameters()
param_.dimension=2
param_.output_types=["OBJ","EB"]
param_.display_stats="bbe ( sol ) obj"
param_.display_all_eval=false
param_.x0=[2,4]
param_.lower_bound=[-10,-10]
param_.upper_bound=[10,10]
param_.max_bb_eval=100
param_.display_degree=2
param_.solution_file="sol.txt"

function NOMAD(eval,param)

cxx"""
#include <string>

class My_Evaluator : public NOMAD::Evaluator {
public:
  My_Evaluator  ( const NOMAD::Parameters & p ) :
    NOMAD::Evaluator ( p ) {}

  ~My_Evaluator ( void ) {}

  bool eval_x ( NOMAD::Eval_Point   & x          ,
		const NOMAD::Double & h_max      ,
		bool                & count_eval   ) const
	{

	//from there, we need to evaluate the julia function "cost" for the point x.

	int n = x.get_n();
	std::vector<double> c_x;
	for (int i = 0; i < n; ++i) {
		c_x.push_back(x[i].value());
	} //first converting our NOMAD::Eval_Point to a vector<double>

	std::vector<double> c_bb_outputs;

	$:( #this syntax calls a julia expression

		j_x = unsafe_wrap(DenseArray, icxx"return c_x;"); #wrap C++ array to a julia vector
		(j_count_eval,j_bb_outputs)=eval(j_x);
		for i=1:length(j_bb_outputs)
			icxx"c_bb_outputs.push_back($(j_bb_outputs[i]));";
		end;
		icxx"count_eval=$j_count_eval;";
		nothing

	);

	for (int i = 0; i < c_bb_outputs.size(); ++i) {
		NOMAD::Double nomad_bb_output = c_bb_outputs[i];
    	x.set_bb_output  ( i , nomad_bb_output  );
	}

    return true;       // the evaluation succeeded
}

};
"""

cxx"""
#include <iostream>

int cpp_main() {

	//default main arguments, needs to be set for MPI
	int argc;
	char ** argv;

  // display:
  NOMAD::Display out ( std::cout );
  out.precision ( NOMAD::DISPLAY_PRECISION_STD );

  try {

    // NOMAD initializations:
    NOMAD::begin ( argc , argv );

    // parameters creation:
    NOMAD::Parameters p ( out );

    p.set_DIMENSION ($(param.dimension));             // number of variables

	int m = $(length(param.output_types));
    vector<NOMAD::bb_output_type> bbot (m); // definition of
	for (int i = 0; i < m; ++i) {
		$:(
			if param.output_types[icxx"return (i+1);"]=="OBJ"
				icxx"bbot[i]=NOMAD::OBJ;";
			elseif param.output_types[icxx"return (i+1);"]=="EB"
				icxx"bbot[i]=NOMAD::EB;";
			elseif param.output_types[icxx"return (i+1);"]=="PB"
				icxx"bbot[i]=NOMAD::PB;";
			else
				error("output type unknown")
			end;
			nothing
		);
	}
    p.set_BB_OUTPUT_TYPE ( bbot );

	$:(
		if param.display_all_eval
			icxx"p.set_DISPLAY_ALL_EVAL(true);";
		end;
		nothing
	);

    p.set_DISPLAY_STATS ($(pointer(param.display_stats)));

	int n = $(length(param.x0));
	NOMAD::Double X0_tab [n];
	NOMAD::Double LB_tab [n];
	NOMAD::Double UB_tab [n];
	for (int i = 0; i < n; ++i) {
	    $:(
	        tempx0=param.x0[icxx"return (i+1);"];
	        icxx"*(X0_tab+i)=$tempx0;";
			templb=param.lower_bound[icxx"return (i+1);"];
			icxx"*(LB_tab+i)=$templb;";
			tempub=param.upper_bound[icxx"return (i+1);"];
			icxx"*(UB_tab+i)=$tempub;";
	        nothing
	    );
	}

	NOMAD::Point X0_point;
	X0_point.set(n,X0_tab);
	p.set_X0 ( X0_point );  // starting point

	NOMAD::Point LB_point;
	LB_point.set(n,LB_tab);
	p.set_LOWER_BOUND ( LB_point );

	NOMAD::Point UB_point;
	UB_point.set(n,UB_tab);
	p.set_UPPER_BOUND ( UB_point );

    p.set_MAX_BB_EVAL ($(param.max_bb_eval));     // the algorithm terminates after
                                 // 100 black-box evaluations
    p.set_DISPLAY_DEGREE($(param.display_degree));
    p.set_SOLUTION_FILE($(pointer(param.solution_file)));

    // parameters validation:
    p.check();

    // custom evaluator creation:
    My_Evaluator ev   ( p );

    // algorithm creation and execution:
    NOMAD::Mads mads ( p , &ev );
    mads.run();
	mads.reset();
  }
  catch ( exception & e ) {
    cerr << "\nNOMAD has been interrupted (" << e.what() << ")\n\n";
  }

  NOMAD::Slave::stop_slaves ( out );
  NOMAD::end();

  return EXIT_SUCCESS;
}
"""

@cxx cpp_main()

end

NOMAD(eval_,param_)

#WARNING => modified Cxx code at /home/pascpier/.julia/dev/Cxx/src/cxxstr.jl:217 to avoid error : pointer from objref cannot be used on immutable objects
