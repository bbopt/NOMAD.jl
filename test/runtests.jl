using NOMAD, Test

@info("NOMAD_INSTALLATION: $(NOMAD.NOMAD_INSTALLATION)")

include("assertions.jl")
include("basic_problems.jl")

# Multiobjective problems
include("mo_problems.jl")

# VNS search function
include("CamelVariant.jl")

# HS linear constrained benchmark problems
include("HS48.jl")
include("HS49.jl")
include("HS51.jl")
include("HS53.jl")
include("HS112.jl")
include("HS119.jl")

# Industrial linear constrained benchmark problems
include("Dallas.jl")
include("Avion2.jl")
include("Loadbal.jl")
include("ProadPL10.jl")
