using Documenter, NOMAD

makedocs(
linkcheck = true,
sitename = "NOMAD.jl",
format = Documenter.HTML(
             prettyurls = get(ENV, "CI", nothing) == "true"
),
pages = ["Home" => "index.md",
           "Parameters" => "nomadParameters.md",
           "Run Optimization" => "run_nomad.md",
           "Results" => "nomadResults.md",
           "Surrogates" => "surrogates.md"
          ]
)

deploydocs(
    repo = "github.com/ppascal97/NOMAD.jl.git",
    target = "build",
)
