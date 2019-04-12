"""

    parameters

mutable struct containing the options of the optimization
process.

Best is to construct one with p=parameters() and then
modify its attributes one after another. For deeper
information concerning these attributes, please refer
to the NOMAD documentation. the names of these
options are the same in NOMADjl as in NOMAD.

#Attributes :

    - dimension::Int64 : Dimension of the problem and
    size of the argument given to eval.
    2 by default.

    - output_types::Vector{String} : A vector containing
    String objects that define the types of outputs returned
    by eval (the order is important) :
        > "OBJ" : objective value to be minimized
        > "EB" : extreme barrier constraint
        > "PB" : progressive barrier constraint
        > "F" : filter approach constraint
        > "PEB" : hybrid constraint EB/PB
        > ... (see NOMAD documentation)
    ["OBJ","EB"] by default.

    - display_all_eval::Bool : if false, only evaluations
    that allow to improve the current state are displayed.
    false by default.

    - display_stats::String : String defining the way outputs
    are displayed (it should not contain any quotes). Here are
    examples of keywords that can be used :
        > bbe : black box evaluations
        > obj : objective function value
        > sol : solution
        > bbo : black box outputs
        > mesh_index : mesh mesh_index
        > mesh_size : mesh size parameter
        > ... (see NOMAD documentation)
    "bbe ( sol ) obj" by default.

    - x0::Vector{Float} : Initialization point for
    NOMAD. Its size needs to be equal to dimension.
    [0,0] by default.

    - lower_bound::Vector{Number} : Lower bound for
    each coordinate of the state.
    [-100,-100] by default.

    - upper_bound::Vector{Number} : Upper bound for
    each coordinate of the state.
    [100, 100] by default.

    - max_bb_eval::Int : Maximum of calls to eval
    allowed.
    100 by default.

    - display_degree::Int : Integer between 0 and 3
    that sets the level of display.
    2 by default.

    - solution_file::String : Name of the generated
    output file containing the returned minimum.
    "sol.txt" by default.


"""
mutable struct parameters

    dimension::Int64
    output_types::Vector{String}
    display_all_eval::Bool
    display_stats::String
    x0::Vector{Float64} 
    lower_bound::Vector{Float64}
    upper_bound::Vector{Float64}
    max_bb_eval::Int64
    display_degree::Int64
    solution_file::String

    function parameters()
        dimension=2
        output_types=["OBJ","EB"]
        display_all_eval=false
        display_stats="bbe ( sol ) obj"
        x0=[0,0]
        lower_bound=[-100,-100]
        upper_bound=[100,100]
        max_bb_eval=100
        display_degree=2
        solution_file="sol.txt"
        new(dimension,output_types,display_all_eval,display_stats,x0,
        lower_bound,upper_bound,max_bb_eval,display_degree,solution_file)
    end
end
