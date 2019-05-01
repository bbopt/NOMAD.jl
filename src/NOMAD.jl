__precompile__(false) #precompiling is modifying some Cxx internal variables before the first run and causes errors.

module NOMAD

using Libdl
using Cxx

export nomad, nomadParameters, disp, nomadResults

include("typedef.jl")
include("init.jl")
include("nomadParameters.jl")
include("run_nomad.jl")
include("check.jl")
include("nomadResults.jl")

path_to_module = @__DIR__
path_to_NOMADjl = path_to_module[1:length(path_to_module)-4]
init(path_to_NOMADjl * "/deps/nomad.3.9.1")

end # module
