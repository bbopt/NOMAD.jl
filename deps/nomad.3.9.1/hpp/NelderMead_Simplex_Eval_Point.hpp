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
 \file   NelderMead_Simplex_Eval_Point.hpp
 \brief  Evaluation point with a NelderMead order priority (headers)
 \author Christophe Tribes
 \date   2017-04-18
 \see    NelderMead_Simplex_Eval_Point.cpp
 */
#ifndef __NELDERMEAD_SIMPLEX_EVAL_POINT__
#define __NELDERMEAD_SIMPLEX_EVAL_POINT__

#include "Set_Element.hpp"
#include "Eval_Point.hpp"

namespace NOMAD {
    
    /// Evaluation point with a priority.
    class NelderMead_Simplex_Eval_Point : public NOMAD::Set_Element<NOMAD::Eval_Point> {
        
    private:
        
        static NOMAD::Double _h_min;         ///< \c h_min value for comparison operator.
        
        static bool _better_use_ep_tag;      ///< \c better_use_ep_tag flag for is_better_than function.
        
        /// Affectation operator.
        /**
         \param x The right-hand side object -- \b IN.
         */
        NelderMead_Simplex_Eval_Point & operator = ( const NelderMead_Simplex_Eval_Point & x );
        
    public:
        
        /// Constructor.
        /**
         \param x                 A pointer to the evaluation point              -- \b IN.
         \param better_use_tag    Flag to use tag for indentify better points    -- \b IN.
         */
        explicit NelderMead_Simplex_Eval_Point ( const NOMAD::Eval_Point * x  , bool better_use_tag =false )
        : NOMAD::Set_Element<NOMAD::Eval_Point> ( x ) {}
        
        
        /// Copy constructor.
        /**
         \param pep The copied object -- \b IN.
         */
        explicit NelderMead_Simplex_Eval_Point ( const NelderMead_Simplex_Eval_Point & pep )
        : NOMAD::Set_Element<NOMAD::Eval_Point> ( pep.get_element()) {}
        
        /// Destructor.
        virtual ~NelderMead_Simplex_Eval_Point ( void ) {}
        
        /// Comparison operator for the set ordering.
        /**
         This virtual function directly call \c is_better_than().
         \param x The right-hand side object -- \b IN.
         \return A boolean equal to \c true if \c *this \c < \c x.
         */
        virtual bool operator < ( const NOMAD::Set_Element<NOMAD::Eval_Point> & x ) const
        { return is_better_than ( x ); }
        
        /// Comparison operator.
        /**
         \param x The right-hand side object -- \b IN.
         \return A boolean equal to \c true if \c *this = best(*this,x).
         */
        bool is_better_than ( const NOMAD::Set_Element<NOMAD::Eval_Point> & x ) const;
        
        /// Access to the evaluation point.
        /**
         \return A pointer to the evaluation point.
         */
        const NOMAD::Eval_Point * get_point ( void ) const { return get_element(); }
        
        /// Comparison operator.
        /**
         \param x1 First eval points to compare       -- \b IN.
         \param x2 Second eval points to compare      -- \b IN.
         \return A boolean equal to \c true if \c x1 dominates x2.
         */
        static bool dominates ( const NOMAD::Eval_Point & x1, const NOMAD::Eval_Point & x2  ) ;
        
        static void set_h_min( NOMAD::Double h ) { _h_min = h ;}
        
        
    };
}

#endif
