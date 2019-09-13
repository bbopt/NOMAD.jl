__precompile__(false) #precompiling is modifying some Cxx internal variables before the first run and causes errors.

module NOMAD

using Libdl
using Cxx

export nomad, nomadParameters, disp, nomadResults

include("init.jl")
include("nomadParameters.jl")
include("run_nomad.jl")
include("check.jl")
include("nomadResults.jl")

path_to_nomad = joinpath(@__DIR__,"../deps/nomad.3.9.1")
init(path_to_nomad)

end # module
