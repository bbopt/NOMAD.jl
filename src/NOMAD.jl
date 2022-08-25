module NOMAD

using Libdl

if haskey(ENV, "JULIA_NOMAD_LIBRARY_PATH")
    const libnomadCInterface = joinpath(ENV["JULIA_NOMAD_LIBRARY_PATH"], "libnomadCInterface.$dlext")
    const NOMAD_INSTALLATION = "CUSTOM"
else
    using NOMAD_jll
    const NOMAD_INSTALLATION = "YGGDRASIL"
end

include("converters.jl")
# TODO : add other options : require to work on the C Nomad interface
include("c_wrappers.jl")
include("core.jl")

end # module
