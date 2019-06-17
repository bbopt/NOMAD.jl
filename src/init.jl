"""

	init(".../nomad.3.9.1")

load NOMAD libraries and create C++ class and function
needed to handle NOMAD optimization process.

This function has to be called once before using runopt.
It is automatically called when importing NOMAD.jl.

The only argument is a String containing the path to
nomad.3.9.1 folder.

"""
function init(path_to_nomad::String)
	@info "loading NOMAD libraries"
	nomad_libs_call(path_to_nomad)
	create_Evaluator_class()
	create_Cresult_class()
	create_cxx_runner()
end

"""

	nomad_libs_call(".../nomad.3.9.1")

load sgtelib and nomad libraries needed to run NOMAD.
Also include all headers to access them via Cxx commands.

"""
function nomad_libs_call(path_to_nomad)

	try
		Libdl.dlopen(path_to_nomad * "/lib/libnomad.so", Libdl.RTLD_GLOBAL)
	catch e
		@warn "NOMAD.jl error : initialization failed, cannot access NOMAD libraries, first need to build them"
		throw(e)
	end


	try
		addHeaderDir(joinpath(path_to_nomad,"src"))
		addHeaderDir(joinpath(path_to_nomad,"ext/sgtelib/src"))
		cxxinclude("nomad.hpp")
	catch e
		@warn "NOMAD.jl error : initialization failed, headers folder cannot be found in NOMAD files"
		throw(e)
	end
end

"""

	create_Evaluator_class()

Create a Cxx-class "Wrap_Evaluator" that inherits from
NOMAD::Evaluator.

"""
function create_Evaluator_class()

	#=
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
	=#

    cxx"""
		#include <string>
		#include <limits>
		#include <vector>

		class Wrap_Evaluator : public NOMAD::Evaluator {
		public:

			double * (*evalwrap)(double * input);
			bool sgte;
			int n;
			int m;

		  Wrap_Evaluator  ( const NOMAD::Parameters & p, double * (*f)(double * input), int input_dim, int output_dim, bool has_sgte) :

		    NOMAD::Evaluator ( p ) {evalwrap=f; n=input_dim; m=output_dim; sgte=has_sgte;}

		  ~Wrap_Evaluator ( void ) {evalwrap=nullptr;}

		  bool eval_x ( NOMAD::Eval_Point   & x  ,
				const NOMAD::Double & h_max      ,
				bool                & count_eval   ) const
			{

			double c_x[n+1];
			for (int i = 0; i < n; ++i) {
				c_x[i]=x[i].value();
			} //first converting our NOMAD::Eval_Point to a double[]

			if (sgte) {
				c_x[n] = (x.get_eval_type()==NOMAD::SGTE)?1.0:0.0;
			}

			double * c_bb_outputs = evalwrap(c_x);

			for (int i = 0; i < m; ++i) {
				NOMAD::Double nomad_bb_output = c_bb_outputs[i];
		    	x.set_bb_output  ( i , nomad_bb_output  );
			} //converting C-double returned by evalwrap in NOMAD::Double that
			//are inserted in x as black box outputs

			bool success = false;
			if (c_bb_outputs[m]==1.0) {
				success=true;
			}

			count_eval = false;
			if (c_bb_outputs[m+1]==1.0) {
				count_eval=true;
			}
			//count_eval returned by evalwrap is actually a double and needs
			//to be converted to a boolean

			delete[] c_bb_outputs;

		    return success;
			//the call to eval_x has succeded
		}

		};
	"""
end

"""

	create_cxx_runner()

Create a C++ function cpp_main that launches NOMAD
optimization process.

"""
function create_cxx_runner()

	#=
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
	=#

    cxx"""
		#include <iostream>
		#include <string>
		#include <list>

		Cresult cpp_runner(int n,
					int m,
					void* f_ptr,
					std::vector<std::string> input_types_,
					std::vector<std::string> output_types_,
					bool display_all_eval_,
					std::string display_stats_,
					std::vector<NOMAD::Point> x0_list,
					NOMAD::Point lower_bound_,
					NOMAD::Point upper_bound_,
					int max_bb_eval_,
					int max_time_,
					int display_degree_,
					int LH_init_,
					int LH_iter_,
					int sgte_cost_,
					NOMAD::Point granularity_,
					bool stop_if_feasible_,
					bool VNS_search_,
					double stat_sum_target_,
					int seed_,
					bool has_stat_avg_,
					bool has_stat_sum_,
					bool has_sgte_) { //le C-main prend en entrée les attributs de l'instance julia parameters


			//Attention l'utilisation des std::string peut entrainer une erreur selon la version du compilateur qui a été utilisé pour générer les librairies NOMAD

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

		    p.set_DIMENSION (n);

			vector<NOMAD::bb_input_type> bbit (n);
			for (int i = 0; i < n; ++i) {
				if (input_types_[i]=="B")
					{bbit[i]=NOMAD::BINARY;}
				else if (input_types_[i]=="I")
					{bbit[i]=NOMAD::INTEGER;}
				else
					{bbit[i]=NOMAD::CONTINUOUS;}
			}
		    p.set_BB_INPUT_TYPE ( bbit );

		    vector<NOMAD::bb_output_type> bbot (m);
			for (int i = 0; i < m; ++i) {
				if (output_types_[i]=="OBJ")
					{bbot[i]=NOMAD::OBJ;}
				else if (output_types_[i]=="EB")
					{bbot[i]=NOMAD::EB;}
				else if ((output_types_[i]=="PB") || (output_types_[i]=="CSTR"))
					{bbot[i]=NOMAD::PB;}
				else if ((output_types_[i]=="PEB") || (output_types_[i]=="PEB_P"))
					{bbot[i]=NOMAD::PEB_P;}
				else if (output_types_[i]=="PEB_E")
					{bbot[i]=NOMAD::PEB_E;}
				else if ((output_types_[i]=="F") || (output_types_[i]=="FILTER"))
					{bbot[i]=NOMAD::FILTER;}
				else if (output_types_[i]=="CNT_EVAL")
					{bbot[i]=NOMAD::CNT_EVAL;}
				else if (output_types_[i]=="STAT_AVG")
					{bbot[i]=NOMAD::STAT_AVG;}
				else if (output_types_[i]=="STAT_SUM")
					{bbot[i]=NOMAD::STAT_SUM;}
				else
					{bbot[i]=NOMAD::UNDEFINED_BBO;}
			}
		    p.set_BB_OUTPUT_TYPE ( bbot );

			p.set_DISPLAY_ALL_EVAL(display_all_eval_);
		    p.set_DISPLAY_STATS(display_stats_);
			for (int i = 0; i < x0_list.size(); ++i) {p.set_X0( x0_list[i] );}  // starting points
			if (lower_bound_.size()>0) {p.set_LOWER_BOUND( lower_bound_ );}
			if (upper_bound_.size()>0) {p.set_UPPER_BOUND( upper_bound_ );}
			if (max_bb_eval_>0) {p.set_MAX_BB_EVAL(max_bb_eval_);}
			if (max_time_>0) {p.set_MAX_TIME(max_time_);}
		    p.set_DISPLAY_DEGREE(display_degree_);
			p.set_HAS_SGTE(has_sgte_);
			if (has_sgte_) {p.set_SGTE_COST(sgte_cost_);}
			std::list<std::string> disp {"bbe","sol","bbo"};
			p.set_STATS_FILE("temp.txt",disp);
			p.set_LH_SEARCH(LH_init_,LH_iter_);
			p.set_GRANULARITY(granularity_);
			p.set_STOP_IF_FEASIBLE(stop_if_feasible_);
			p.set_VNS_SEARCH(VNS_search_);
			if (stat_sum_target_>0) {p.set_STAT_SUM_TARGET(stat_sum_target_);}
			p.set_SEED(seed_);

		    p.check();
			// parameters validation

			//conversion from void pointer to appropriate pointer
			typedef double * (*fptr)(double * input);
			fptr f_fun_ptr = reinterpret_cast<fptr>(f_ptr);

		    // custom evaluator creation
		    Wrap_Evaluator ev   ( p , f_fun_ptr, n, m, has_sgte_);


		    // algorithm creation and execution
			NOMAD::Mads mads ( p , &ev );

			mads.run();

			//saving results
			const NOMAD::Eval_Point* bf_ptr = mads.get_best_feasible();
			const NOMAD::Eval_Point* bi_ptr = mads.get_best_infeasible();
			res.set_eval_points(bf_ptr,bi_ptr,n,m);
			NOMAD::Stats stats;
			stats = mads.get_stats();
			res.bb_eval = stats.get_bb_eval();
			if (has_stat_avg_) {res.stat_avg = (stats.get_stat_avg()).value();}
			if (has_stat_sum_) {res.stat_sum = (stats.get_stat_sum()).value();}
			res.seed = p.get_seed();

			mads.reset();

			res.success = true;

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

			//No const NOMAD::Eval_point pointer in Cresult because GC sometimes erase their content

			std::vector<double> bf;
			std::vector<double> bbo_bf;
			std::vector<double> bi;
			std::vector<double> bbo_bi;
			int bb_eval;
			double stat_avg;
			double stat_sum;
			bool success;
			bool has_feasible;
			bool has_infeasible;
			int seed;

			Cresult(){success=false;}

			void set_eval_points(const NOMAD::Eval_Point* bf_ptr,const NOMAD::Eval_Point* bi_ptr,int n,int m){

				has_feasible = (bf_ptr != NULL);

				if (has_feasible) {
					for (int i = 0; i < n; ++i) {
						bf.push_back(bf_ptr->value(i));
					}
					for (int i = 0; i < m; ++i) {
						bbo_bf.push_back((bf_ptr->get_bb_outputs())[i].value());
					}
				}

				has_infeasible = (bi_ptr != NULL);

				if (has_infeasible) {
					for (int i = 0; i < n; ++i) {
						bi.push_back(bi_ptr->value(i));
					}
					for (int i = 0; i < m; ++i) {
						bbo_bi.push_back((bi_ptr->get_bb_outputs())[i].value());
					}
				}

			}


		};
	"""
end
