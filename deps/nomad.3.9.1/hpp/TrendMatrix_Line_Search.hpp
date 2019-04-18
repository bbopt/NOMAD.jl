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
 \file   TrendMatrix_Line_Search.hpp
 \brief  Trend Matrix basic line search (headers)
 \author Christophe Tribes
 \date   2017-05-3
 \see    TrendMatrix_Line_Search.cpp
 */
#ifndef __TRENDMATRIX_LINE_SEARCH__
#define __TRENDMATRIX_LINE_SEARCH__

#include "Mads.hpp"

namespace NOMAD {
    
    /// Model search.
    class TrendMatrix_Line_Search : public NOMAD::Search , private NOMAD::Uncopyable {
        
    private:
        
        // fixed variables:
        const NOMAD::Point & _fixed_variables;
        
        // Number of free variables
        int _n_free;
        
        // Number of variables
        int _n;
        
        NOMAD::Stats _search_stats;   ///< Stats for one search.        
        
        const NOMAD::Display    & _out;
        NOMAD::dd_type _display_degree ;
        
        /// Project to mesh and create a trial point.
        /**
         \param ev_control     The NOMAD::Evaluator_Control object -- \b IN.
         \param x              The point coordinates               -- \b IN.
         \param poll_center    The poll center                     -- \b IN.
         \param signature      Signature                           -- \b IN.
         \param mesh_indices   Mesh indices                        -- \b IN.
         \param delta          Mesh size parameter                 -- \b IN.
         \param display_degree Display degree                      -- \b IN.
         \param out            The NOMAD::Display object           -- \b IN.
         */
        void create_trial_point ( NOMAD::Evaluator_Control & ev_control ,
                                 NOMAD::Point                x ,
                                 const NOMAD::Eval_Point   & poll_center ,
                                 NOMAD::Signature          & signature ,
                                 const NOMAD::Point        & mesh_indices,
                                 const NOMAD::Point        & delta ,
                                 NOMAD::dd_type              display_degree ,
                                 const NOMAD::Display      & out              );
        
        /*----------------------------------------------------------------------*/
        
    public:
        
        /// Constructor.
        /**
         \param p Parameters -- \b IN.
         */
        TrendMatrix_Line_Search ( NOMAD::Parameters & p )
        : NOMAD::Search ( p , NOMAD::TRENDMATRIX_LINE_SEARCH ),
        _fixed_variables ( p.get_signature()->get_fixed_variables() ),
        _out(p.out())
        {
            _n = p.get_dimension() ;
            _n_free = p.get_nb_free_variables();
            _display_degree = _out.get_search_dd();
        }
        
        /// Destructor.
        virtual ~TrendMatrix_Line_Search ( void ) {}
        
        
        /// The trend matrix basic line search.
        /**
         \param mads           NOMAD::Mads object invoking this search -- \b IN/OUT.
         \param nb_search_pts  Number of generated search points       -- \b OUT.
         \param stop           Stop flag                               -- \b IN/OUT.
         \param stop_reason    Stop reason                             -- \b OUT.
         \param success        Type of success                         -- \b OUT.
         \param count_search   Count or not the search                 -- \b OUT.
         \param new_feas_inc   New feasible incumbent                  -- \b IN/OUT.
         \param new_infeas_inc New infeasible incumbent                -- \b IN/OUT.
         */
        virtual void search ( NOMAD::Mads              & mads           ,
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
