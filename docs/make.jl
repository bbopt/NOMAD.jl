using Documenter, NOMAD

makedocs(
linkcheck = true,
sitename = "NOMAD.jl",
format = Documenter.HTML(
             prettyurls = get(ENV, "CI", nothing) == "true"
),
pages = ["Home" => "index.md",
           "Parameters" => "parameters.md",
           "Run Optimization" => "runopt.md",
           "Results" => "results.md"
          ]
)

deploydocs(
    repo = "github.com/ppascal97/NOMAD.jl.git",
    target = "build",
)
