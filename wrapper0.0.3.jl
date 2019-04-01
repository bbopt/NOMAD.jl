function cost(x) #test function to optimize
	y=(x[1]+2*x[2]-7)^2+(2*x[1]+x[2]-5)^2
	convert(Float64,y)
	return y
end

function constraint(x) #random constraint for testing
	y=2-x[1]
	convert(Float64,y)
	return y
end

function eval(x) #function created by the user
    f=cost(x)
    c=constraint(x)
    count_eval=true
	bb_outputs = [f,c]
    return (count_eval,bb_outputs)
end

const path_to_nomad = "/home/pascpier/Documents/nomad.3.9.1-copy"

using Cxx
using Libdl

### Loading libraries and headers ###
addHeaderDir(path_to_nomad * "/lib", kind=C_System)
Libdl.dlopen(path_to_nomad * "/lib/libnomad.so", Libdl.RTLD_GLOBAL)
Libdl.dlopen(path_to_nomad * "/lib/libsgtelib.so", Libdl.RTLD_GLOBAL)
cxxinclude(path_to_nomad * "/ext/sgtelib/src/sgtelib.hpp")
cxxinclude(path_to_nomad * "/hpp/nomad.hpp")

### Creation of the evaluator class in C++
cxx"""
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

	std::vector<double> c_bb_outputs; //Declaring the array that will host bb outputs

	$:( #this syntax calls a julia expression

		j_x = unsafe_wrap(DenseArray, icxx"return c_x;"); #converting the C++ point to evaluate into a julia vector
		(j_count_eval,j_bb_outputs)=eval(j_x); #evaluating the bb
		for i=1:length(j_bb_outputs)
			icxx"c_bb_outputs.push_back($(j_bb_outputs[i]));";
		end; #converting the result into a C++ array
		icxx"count_eval=$j_count_eval;";
		nothing

	);

	for (int i = 0; i < c_bb_outputs.size(); ++i) {
		NOMAD::Double nomad_bb_output = c_bb_outputs[i];
    	x.set_bb_output  ( i , nomad_bb_output  ); #setting the bb outputs
	}

    return true;       // the evaluation succeeded
}

};
"""

### Define the parameters and launch the optimization ###
cxx"""
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

    p.set_DIMENSION (2);             // number of variables

    vector<NOMAD::bb_output_type> bbot (2); // definition of
    bbot[0] = NOMAD::OBJ;                   // output types
    bbot[1] = NOMAD::EB;
    p.set_BB_OUTPUT_TYPE ( bbot );

//    p.set_DISPLAY_ALL_EVAL(true);   // displays all evaluations.
    p.set_DISPLAY_STATS ( "bbe ( sol ) obj" );

    p.set_X0 ( NOMAD::Point(2,5) );  // starting point

    p.set_LOWER_BOUND ( NOMAD::Point ( 2 , -10 ) );
    p.set_UPPER_BOUND ( NOMAD::Point ( 2 , 10 ) );

    p.set_MAX_BB_EVAL (100);     // the algorithm terminates after
                                 // 100 black-box evaluations
    p.set_DISPLAY_DEGREE(2);
    p.set_SOLUTION_FILE("sol.txt");

    // parameters validation:
    p.check();

    // custom evaluator creation:
    My_Evaluator ev   ( p );

    // algorithm creation and execution:
    NOMAD::Mads mads ( p , &ev );
    mads.run();
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
