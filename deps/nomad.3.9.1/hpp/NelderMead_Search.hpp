/*---------------------------------------------------------------------------------*/
/*  NOMAD - Nonlinear Optimization by Mesh Adaptive Direct search -                */
/*                                                                                 */
/*  NOMAD - version 3.9.1 has been created by                                      */
/*                 Charles Audet               - Ecole Polytechnique de Montreal   */
/*                 Sebastien Le Digabel        - Ecole Polytechnique de Montreal   */
/*                 Viviane Rochon Montplaisir - Ecole Polytechnique de Montreal   */
/*                 Christophe Tribes           - Ecole Polytechnique de Montreal   */
/*                                                                                 */
/*  The copyright of NOMAD - version 3.9.1 is owned by                             */
/*                 Sebastien Le Digabel        - Ecole Polytechnique de Montreal   */
/*                 Viviane Rochon Montplaisir - Ecole Polytechnique de Montreal   */
/*                 Christophe Tribes           - Ecole Polytechnique de Montreal   */
/*                                                                                 */
/*  NOMAD v3 has been funded by AFOSR and Exxon Mobil.                             */
/*                                                                                 */
/*  NOMAD v3 is a new version of NOMAD v1 and v2. NOMAD v1 and v2 were created     */
/*  and developed by Mark Abramson, Charles Audet, Gilles Couture, and John E.     */
/*  Dennis Jr., and were funded by AFOSR and Exxon Mobil.                          */
/*                                                                                 */
/*  Contact information:                                                           */
/*    Ecole Polytechnique de Montreal - GERAD                                      */
/*    C.P. 6079, Succ. Centre-ville, Montreal (Quebec) H3C 3A7 Canada              */
/*    e-mail: nomad@gerad.ca                                                       */
/*    phone : 1-514-340-6053 #6928                                                 */
/*    fax   : 1-514-340-5665                                                       */
/*                                                                                 */
/*  This program is free software: you can redistribute it and/or modify it        */
/*  under the terms of the GNU Lesser General Public License as published by       */
/*  the Free Software Foundation, either version 3 of the License, or (at your     */
/*  option) any later version.                                                     */
/*                                                                                 */
/*  This program is distributed in the hope that it will be useful, but WITHOUT    */
/*  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or          */
/*  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License    */
/*  for more details.                                                              */
/*                                                                                 */
/*  You should have received a copy of the GNU Lesser General Public License       */
/*  along with this program. If not, see <http://www.gnu.org/licenses/>.           */
/*                                                                                 */
/*  You can find information on the NOMAD software at www.gerad.ca/nomad           */
/*---------------------------------------------------------------------------------*/

/**
 \file   NelderMead_Search.hpp
 \brief  Nelder Mead search (headers)
 \author Christophe Tribes
 \date   2017-03-31
 \see    NelderMead_Search.cpp
 */
#ifndef __NELDERMEAD_SEARCH__
#define __NELDERMEAD_SEARCH__

#include "Mads.hpp"
#include "NelderMead_Simplex_Eval_Point.hpp"

namespace NOMAD {
    
    /// Model search.
    class NelderMead_Search : public NOMAD::Search , private NOMAD::Uncopyable {
        
    private:
        
        /// Set of points in NM simplex (strict ordering -> no tied points).
        std::set<NOMAD::NelderMead_Simplex_Eval_Point> _nm_Y;
        
        double _simplex_von;
        double _simplex_vol;
        double _simplex_diam;
        
        const NOMAD::NelderMead_Simplex_Eval_Point * _simplex_diam_pt1;
        const NOMAD::NelderMead_Simplex_Eval_Point * _simplex_diam_pt2;
        
        // fixed variables:
        const NOMAD::Point & _fixed_variables;
        
        // Number of free variables
        int _n_free;
        
        // Number of variables
        int _n;
        
        
        /// Lists of points extracted from NM simplex (loose ordering-->tied points can exist)
        std::list<const NOMAD::Eval_Point *> _nm_Y0; ///< Undominated points
        std::list<const NOMAD::Eval_Point *> _nm_Yn; ///< Dominated points
        
        /// List of new NM points
        std::list<NOMAD::Eval_Point *> _nm_submitted_points;
        std::list<const NOMAD::Eval_Point *> _nm_evaluated_points;
        
        const NOMAD::Display    & _out;
        NOMAD::dd_type _display_degree ;
        
        
        NOMAD::Stats _search_stats;   ///< Stats for one search.
        
        /// Display degree type.
        enum NM_step_type
        {
            INITIAL             ,
            REFLECT             ,
            EXPAND              ,
            OUTSIDE_CONTRACTION ,
            INSIDE_CONTRACTION  ,
            SHRINK              ,
            COMPLETE
        };
        
        NM_step_type _step;  //
        
        
        /// Display degree type.
        enum NM_stop_type
        {
            TOO_SMALL_SIMPLEX           ,
            SIMPLEX_RANK_INSUFFICIENT   ,
            INITIAL_FAILED              ,
            ORDER_FAILED                ,
            SHRINK_REQUEST              ,
            REFLECT_FAILED              ,
            EXPANSION_FAILED            ,
            OUTSIDE_CONTRACTION_FAILED  ,
            INSIDE_CONTRACTION_FAILED   ,
            SHRINK_FAILED               ,
            MAX_SEARCH_POINTS_REACHED   ,
            MIN_SIMPLEX_VOL_REACHED     ,
            UNDEFINED_STEP              ,
            INSERTION_FAILED            ,
            STEP_FAILED                 ,
            COMPLETED                   ,
            OPPORTUNISTIC_STOP
        };
        
        NOMAD::Double _gamma; // Shrink parameter
        NOMAD::Double _delta_ic; // Inside contraction parameter
        NOMAD::Double _delta_oc; // Outside contraction parameter
        NOMAD::Double _delta_e; // Expansion parameter
        bool _perform_shrink; // Perform shrink
        
        bool _proj_to_mesh;
        
        NOMAD::Point _old_Delta; // Keeps the old poll size when strong nm search is performed
        NOMAD::Point _old_delta; // Keeps the old mesh size when strong nm search is performed
        NOMAD::Double _old_model_search_max_trial_pts;
        
        
        /// Project to mesh and create a trial point.
        /**
         \param ev_control      The NOMAD::Evaluator_Control object -- \b IN.
         \param x               The point coordinates               -- \b IN.
         \param center          The center point                    -- \b IN.
         */
        bool create_trial_point ( NOMAD::Evaluator_Control &  ev_control ,
                                 NOMAD::Eval_Point        *&  x          ,
                                 const NOMAD::Eval_Point  &  center     );
        /*------------------------------------------------------------------*/
        
        
        
        /// Create the initial set of points or propose a point from a Nelder-Mead step.
        /**
         \param cache          Cache of evaluated points         -- \b IN.
         \param ev             Evaluator                         -- \b IN.
         \param xk             Current best incumbent            -- \b IN.
         \param stop           Stop flag                         -- \b OUT.
         \param stop_reason    Stop reason                       -- \b OUT.
         */
        bool NM_step (const NOMAD::Cache                       & cache         ,
                      const NOMAD::Evaluator                   & ev            ,
                      const NOMAD::Eval_Point                  * xk            ,
                      bool                                     & stop          ,
                      NM_stop_type                             & stop_reason    );
        /*----------------------------------------------------------------------*/
        
        
        /// Create initial sets of points.
        /**
         \param cache          Cache of evaluated points         -- \b IN.
         \param ev             Evaluator                         -- \b IN.
         \param xk             Current best incumbent            -- \b IN.
         \param stop           Stop flag                         -- \b OUT.
         \param stop_reason    Stop reason                       -- \b OUT.
         */
        void create_initial_sets_from_cache (const NOMAD::Cache                       & cache      ,
                                             const NOMAD::Evaluator                   & ev         ,
                                             const NOMAD::Eval_Point                  * xk         ,
                                             bool                                     & stop       ,
                                             NM_stop_type                             & stop_reason );
        
        /// Create list of undominated points Y0.
        /**
         \param stop           Stop flag                         -- \b OUT.
         \param stop_reason    Stop reason                       -- \b OUT.
         */
        void make_list_Y0 (bool              & stop       ,
                           NM_stop_type      & stop_reason);
        
        
        /// Create list of dominated points Yn.
        /**
         \param stop           Stop flag                         -- \b OUT.
         \param stop_reason    Stop reason                       -- \b OUT.
         */
        void make_list_Yn (bool              & stop       ,
                           NM_stop_type      & stop_reason);
        
        /// Create initial sets of points.
        /**
         \param cache          Cache of evaluated points         -- \b IN.
         \param stop           Stop flag                         -- \b OUT.
         \param stop_reason    Stop reason                       -- \b OUT.
         */
        void create_initial_sets_from_new_points (const NOMAD::Cache & cache      ,
                                                  bool               & stop       ,
                                                  NM_stop_type       & stop_reason );
        
        
        /// Create reflect point from simplex Y.
        /**
         \param stop           Stop flag                         -- \b OUT.
         \param stop_reason    Stop reason                       -- \b OUT.
         \param delta          Parameter for reflection          -- \b IN.
         */
        void create_reflect_point ( bool                & stop        ,
                                   NM_stop_type         & stop_reason ,
                                   const NOMAD::Double  & delta       );
        
        /// Create trial point from simplex shrink points.
        /**
         \param stop           Stop flag                         -- \b OUT.
         \param stop_reason    Stop reason                       -- \b OUT.
         */
        void create_trial_shrink_points ( bool        & stop        ,
                                         NM_stop_type & stop_reason );
        
        
        /// Test if point dominates all points in Y0
        /**
         \param xt     Point to test            -- \b IN.
         */
        bool point_dominates_Y0 ( const NOMAD::Eval_Point & xt );
        
        /// Test all points in Yn for dominance wrt a given point
        /**
         \param xt     Point to test            -- \b IN.
         */
        bool Yn_dominates_point ( const NOMAD::Eval_Point & xt );
        
        
        /// Test if point xt dominates at least nb_points points in Y
        /**
         \param xt     Point to test            -- \b IN.
         \param nb_points_to_dominate Number of points that have to be dominated          -- \b IN.
         */
        bool point_dominates_pts_in_Y ( const NOMAD::Eval_Point & xt , size_t nb_points_to_dominate );
        
        
        /// Insert in Y the best of x1 and x2
        /**
         \param x1     Point 1 for insertion      -- \b IN.
         \param x2     Point 2 for insertion      -- \b IN.
         */
        bool insert_in_Y_best( const NOMAD::Eval_Point & x1 , const NOMAD::Eval_Point & x2 );
        
        
        /// Insert x in Y
        /**
         \param xi     Point to insert in Y      -- \b IN.
         */
        bool insert_in_Y( const NOMAD::Eval_Point & xi );
        
        /// Update the simplex Y volumes and diameter
        /**
         */
        void update_Y_characteristics() ;
        
        /// Update the simplex Y diameter
        /**
         */
        void update_Y_diameter() ;
        
        /// Display simplex Y information
        /**
         */
        void display_Y_info() const;
        
        
        /// Get the rank of the matrix DZ = [(z1-z0) (z2-z0) ... (zk-z0)]]
        /**
         */
        int get_rank_DZ( void ) const;
        
        // Check evaluation point outputs before the integration into NM set
        /**
         \param bbo       Blackbox outputs         -- \b IN.
         \param m         Number of outputs        -- \b IN.
         */
        bool check_outputs ( const NOMAD::Point & bbo , int m ) const;
        
    public:
        
        /// Constructor.
        /**
         \param p Parameters -- \b IN.
         */
        NelderMead_Search ( NOMAD::Parameters & p )
        : NOMAD::Search ( p , NOMAD::NM_SEARCH ),
        _fixed_variables ( p.get_signature()->get_fixed_variables() ),
        _out(p.out())
        {
            
            _gamma = p.get_NM_gamma();        // Shrink parameter (only if _perform_shrink == true. This is not the default).
            _delta_ic = p.get_NM_delta_ic() ; // Inside contraction parameter
            _delta_oc = p.get_NM_delta_oc(); // Outside contraction parameter
            _delta_e = p.get_NM_delta_e() ; // Expansion parameter
            
            _n = p.get_dimension() ;
            _n_free = p.get_nb_free_variables();
            
            if ( p.get_NM_search_intensive() )
            {
                _perform_shrink = true;
                _proj_to_mesh = false ;
            }
            else
            {
                _perform_shrink = false; // No need to perform shrink when NM is in combination with Mads (this is the default).
                _proj_to_mesh = true ;
            }
            _display_degree = _out.get_search_dd();
            
        }
        
        /// Destructor.
        virtual ~NelderMead_Search ( void ) {}
        
        /// The NelderMead search.
        virtual void search (NOMAD::Mads              & mads           ,
                             int                      & nb_search_pts  ,
                             bool                     & stop           ,
                             NOMAD::stop_type         & stop_reason    ,
                             NOMAD::success_type      & success        ,
                             bool                     & count_search   ,
                             const NOMAD::Eval_Point *& new_feas_inc   ,
                             const NOMAD::Eval_Point *& new_infeas_inc   );
        
        
        //// Display stats.
        /**
         \param out The NOMAD::Display object -- \b IN.
         */
        virtual void display ( const NOMAD::Display & out ) const
        {
            out << _search_stats;
        }
    };
}

#endif
