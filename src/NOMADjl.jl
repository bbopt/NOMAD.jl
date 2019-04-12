__precompile__(false) #precompiling is modifying some Cxx internal variables before the first run and causes errors.

module NOMADjl

using Libdl
using Cxx

export init, runopt, parameters, results, disp

include("init.jl")
include("parameters.jl")
include("runopt.jl")
include("check.jl")
include("results.jl")

end # module
