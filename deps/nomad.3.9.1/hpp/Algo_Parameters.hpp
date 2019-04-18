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

#ifndef __ALGO_PARAMETERS__
#define __ALGO_PARAMETERS__

#include <string>
#include <iostream>
#include <sstream>
#include <cstdlib>

#include "defines.hpp"

class DLL_API Algo_Parameters {
    
protected:
    // Base info
    std::string           _algo_params_file_name;
    std::ostringstream    _streamed_params;
    bool                  _exclude_pb_params;
    bool                  _exclude_disp_params;
    bool                  _is_nomad;
    
    // check compatibility with other Algo_Parameters object:
    friend bool compare_type_id (const Algo_Parameters & a,const Algo_Parameters &b )  ;
    
private:
    int                   _index;
    std::string           _description;
    
    // reset base info
    void reset_base_info ( void );
    
    
public:
    

    // destructor:
    virtual ~Algo_Parameters ( void ) {}
    
    // GET methods:
    int                  get_index          ( void ) const { return _index;       }
    virtual std::string  get_algo_name    ( void ) const =0 ;
    virtual std::string  get_algo_version ( void ) const =0 ;
    const std::string  & get_algo_param_file_name( void ) const { return _algo_params_file_name ; }
    virtual std::string get_algo_name_version ( void ) const;
    virtual int get_max_bb_eval ( void ) const =0 ;
    std::string get_params_as_string ( void ) const
    {
        if ( _streamed_params.str().empty() )
            return std::string("cannot get params to display");
        else if ( _streamed_params.str().compare(" ") == 0)
            return std::string("all params set to default");
        else return _streamed_params.str();
    }
    
    // SET methods
    void set_description ( const std::string & s ) { _description = s; }
    void set_index          ( int i ) { _index = i; }
    void set_exclude_pb_params ( bool e ) { _exclude_pb_params = e;}
    void set_exclude_disp_params ( bool e ) { _exclude_disp_params = e;}
    
    virtual bool set_DISPLAY_DEGREE ( int dd ) =0 ;
    
    // read and checks
    virtual void read ( const std::string & param_file_name ) =0 ;
    virtual void check( bool b1=true, bool b2=true ,bool b3 =true ) =0;
    bool is_nomad ( void ) const;
    virtual bool is_algo_compatible ( const Algo_Parameters & ap ) const =0;
    
    
};

#endif
