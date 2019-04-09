using Libdl
using Cxx
include("wrapper0.1.0.jl")
include("Parameters0.1.0.jl")

function init_nomad(path_to_nomad)

addHeaderDir(path_to_nomad * "/lib", kind=C_System)
Libdl.dlopen(path_to_nomad * "/lib/libnomad.so", Libdl.RTLD_GLOBAL)
Libdl.dlopen(path_to_nomad * "/lib/libsgtelib.so", Libdl.RTLD_GLOBAL)
cxxinclude(path_to_nomad * "/ext/sgtelib/src/sgtelib.hpp")
cxxinclude(path_to_nomad * "/hpp/nomad.hpp")

cxx"""
#include <string>

class My_Evaluator : public NOMAD::Evaluator {
public:

	double * (*evalwrap)(double * input); //C-pointeur vers la fonction julia eval_wrap
	int n;
	int m;

  My_Evaluator  ( const NOMAD::Parameters & p, double * (*f)(double * input), int input_dim, int output_dim) : //le constructeur prend en argument un C-pointeur vers la fonction eval_wrap

    NOMAD::Evaluator ( p ) {evalwrap=f; n=input_dim; m=output_dim;}

  ~My_Evaluator ( void ) {evalwrap=nullptr;}

  bool eval_x ( NOMAD::Eval_Point   & x  ,
		const NOMAD::Double & h_max      ,
		bool                & count_eval   ) const
	{

	//from there, we need to evaluate the julia function "cost" for the point x.

	double c_x[n];
	for (int i = 0; i < n; ++i) {
		*(c_x+i)=x[i].value();
	} //first converting our NOMAD::Eval_Point to a double[]


	double * c_bb_outputs = evalwrap(c_x);

	for (int i = 0; i < m; ++i) {
		NOMAD::Double nomad_bb_output = *(c_bb_outputs+i);
    	x.set_bb_output  ( i , nomad_bb_output  );
	} //conversion des C-double retournés par evalwrap en NOMAD::Double et rentrée des données dans NOMAD

	count_eval = false;
	if (*(c_bb_outputs+m)==1.0) {
		count_eval=true;
	}

	delete[] c_bb_outputs;

    return true;
}

};
"""

cxx"""
#include <iostream>
#include <string>

int cpp_main(int n,
			int m,
			void * f_ptr,
			std::vector<std::string> output_types_,
			bool display_all_eval_,
			const char * display_stats_char,
			NOMAD::Point x0_,
			NOMAD::Point lower_bound_,
			NOMAD::Point upper_bound_,
			int max_bb_eval_,
			int display_degree_,
			const char * solution_file_char) { //le C-main prend en entrée les attributs de l'instance julia parameters

	std::string display_stats_ = display_stats_char; //conversion des char* en std::string
	std::string solution_file_ = solution_file_char;

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

    p.set_DIMENSION (n);             // number of variables

    vector<NOMAD::bb_output_type> bbot (m); // definition of
	for (int i = 0; i < m; ++i) {
		if (output_types_[i]=="OBJ")
			{bbot[i]=NOMAD::OBJ;}
		else if (output_types_[i]=="EB")
			{bbot[i]=NOMAD::EB;}
		else if (output_types_[i]=="PB")
			{bbot[i]=NOMAD::PB;}
		else
			{std::cout << "error : unknown output type" << std::endl;
		}
	}
    p.set_BB_OUTPUT_TYPE ( bbot );

	p.set_DISPLAY_ALL_EVAL(display_all_eval_);

    p.set_DISPLAY_STATS (display_stats_);

	p.set_X0 ( x0_ );  // starting point

	p.set_LOWER_BOUND ( lower_bound_ );

	p.set_UPPER_BOUND ( upper_bound_ );

    p.set_MAX_BB_EVAL (max_bb_eval_);

    p.set_DISPLAY_DEGREE(display_degree_);

    p.set_SOLUTION_FILE(solution_file_);

    // parameters validation:
    p.check();

	//conversion du void-pointeur vers eval_wrap en pointeur approprié
	typedef double * (*fptr)(double * input);
	fptr f_fun_ptr = reinterpret_cast<fptr>(f_ptr);

    // custom evaluator creation:
    My_Evaluator ev   ( p , f_fun_ptr, n, m);


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

end
