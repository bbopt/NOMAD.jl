mutable struct parameters
    dimension::Int64
    output_types::Vector{String}
    display_all_eval::Bool
    display_stats::String
    x0::Vector{Float64} #can't feed with a Float64 !!!
    lower_bound::Vector{Float64}
    upper_bound::Vector{Float64}
    max_bb_eval::Int64
    display_degree::Int64
    solution_file::String
    function parameters()
        dimension=2
        output_types=["OBJ"]
        display_all_eval=false
        display_stats="bbe ( sol ) obj"
        x0=[0,0]
        lower_bound=[-100,-100]
        upper_bound=[100,100]
        max_bb_eval=100
        display_degree=2
        solution_file="sol.txt"
        new(dimension,output_types,display_all_eval,display_stats,x0,lower_bound,upper_bound,max_bb_eval,display_degree,solution_file)
    end
end
