"""

	init(".../nomad3.9.1")

load NOMAD libraries and create C++ class and function
needed to handle NOMAD optimization process.

This function has to be called once before using runopt.
Moreover, it should not be called more than once (the C++
class and function cannot be overwritten).

The only argument is a String containing the path to
NOMAD3.9.1 folder.

"""
function init(path_to_nomad::String)
	nomad_libs_call(path_to_nomad)
	create_Evaluator_class()
	create_Cresult_class()
	create_cxx_runner()
end

"""

	nomad_libs_call(".../nomad3.9.1")

load sgtelib and nomad libraries needed to run NOMAD.
Also include all headers to access them via Cxx commands.

"""
function nomad_libs_call(path_to_nomad)
	try
		addHeaderDir(path_to_nomad * "/lib", kind=C_System)
		Libdl.dlopen(path_to_nomad * "/lib/libnomad.so", Libdl.RTLD_GLOBAL)
		Libdl.dlopen(path_to_nomad * "/lib/libsgtelib.so", Libdl.RTLD_GLOBAL)
	catch
		error("NOMADjl error : initialization failed, cannot access NOMAD libraries, wrong path to NOMAD")
	end

	try
		cxxinclude(path_to_nomad * "/hpp/nomad.hpp")
	catch
		error("NOMADjl error : initialization failed, headers folder cannot be found in NOMAD files")
	end
end

"""

	create_Evaluator_class()

Create a Cxx-class "Wrap_Evaluator" that inherits from
NOMAD::Evaluator.

The method eval_x is called by NOMAD to evaluate the
values of objective functions and constraints for a
given state. The first attribute evalwrap of the class
is a pointer to the julia function that wraps the evaluator
provided by the user and makes it interpretable by C++.
This wrapper is called by the method eval_x. This way,
each instance of the class Wrap_Evaluator is related
to a given julia evaluator.

the attribute n is the dimension of the problem and m
is the number of outputs (objective functions and
constraints).

"""
function create_Evaluator_class()
    cxx"""
		#include <string>

		class Wrap_Evaluator : public NOMAD::Evaluator {
		public:

			double * (*evalwrap)(double * input);
			int n;
			int m;

		  Wrap_Evaluator  ( const NOMAD::Parameters & p, double * (*f)(double * input), int input_dim, int output_dim) :

		    NOMAD::Evaluator ( p ) {evalwrap=f; n=input_dim; m=output_dim;}

		  ~Wrap_Evaluator ( void ) {evalwrap=nullptr;}

		  bool eval_x ( NOMAD::Eval_Point   & x  ,
				const NOMAD::Double & h_max      ,
				bool                & count_eval   ) const
			{


			double c_x[n];
			for (int i = 0; i < n; ++i) {
				c_x[i]=x[i].value();
			} //first converting our NOMAD::Eval_Point to a double[]


			double * c_bb_outputs = evalwrap(c_x);

			for (int i = 0; i < m; ++i) {
				NOMAD::Double nomad_bb_output = c_bb_outputs[i];
		    	x.set_bb_output  ( i , nomad_bb_output  );
			} //converting C-double returned by evalwrap in NOMAD::Double that
			//are inserted in x as black box outputs

			count_eval = false;
			if (c_bb_outputs[m]==1.0) {
				count_eval=true;
			}
			//count_eval returned by evalwrap is actually a double and needs
			//to be converted to a boolean

			delete[] c_bb_outputs;

		    return true;
			//the call to eval_x has succeded
		}

		};
	"""
end

"""

	create_cxx_runner()

Create a C++ function cpp_main that launches NOMAD
optimization process.

This C++ function takes as arguments the settings of the
optimization (dimension, output types, display options,
bounds, etc.) along with a void pointer to the julia
function that wraps the evaluator provided by the user.
cpp_main first create an instance of the C++ class
Paramaters and feed it with the optimization settings.
Then a Wrap_Evaluator is constructed from this Parameters
instance and from the pointer to the evaluator wrapper.
Mads is then run, taking as arguments the Wrap_Evaluator
and Parameters instances.

"""
function create_cxx_runner()
    cxx"""
		#include <iostream>
		#include <string>

		Cresult cpp_runner(int n,
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

		  Cresult res;

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

		    p.check();
			// parameters validation

			//conversion from void pointer to appropriate pointer
			typedef double * (*fptr)(double * input);
			fptr f_fun_ptr = reinterpret_cast<fptr>(f_ptr);

		    // custom evaluator creation
		    Wrap_Evaluator ev   ( p , f_fun_ptr, n, m);


		    // algorithm creation and execution
			NOMAD::Mads mads ( p , &ev );

			mads.run();

			//saving results
			res.best_feasible = mads.get_best_feasible();
			res.best_infeasible = mads.get_best_infeasible();
			res.stats = mads.get_stats();

			mads.reset();

		  }
		  catch ( exception & e ) {
		    cerr << "\nNOMAD has been interrupted (" << e.what() << ")\n\n";
		  }

		  NOMAD::Slave::stop_slaves ( out );
		  NOMAD::end();

		  return res;
		}
    """
end

"""

	create_Cresult_class()

Create C++ class that store results from simulation.

"""
function create_Cresult_class()
    cxx"""
		class Cresult {
		public:

			const NOMAD::Eval_Point* best_feasible;
			const NOMAD::Eval_Point* best_infeasible;
			NOMAD::Stats stats;

		};
	"""
end
