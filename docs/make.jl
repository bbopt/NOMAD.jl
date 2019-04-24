using Documenter, NOMAD

makedocs(
linkcheck = true,
pages = ["Home" => "index.md",
           "Parameters" => "parameters.md",
           "Run Optimization" => "runopt.md",
           "Results" => "results.md"
          ]
)

deploydocs(
    repo = "github.com/ppascal97/NOMAD.jl.git",
)
