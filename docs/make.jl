using Documenter, NOMAD

makedocs(
linkcheck = true,
sitename = "NOMAD.jl",
format = Documenter.HTML(
           # Use clean URLs, unless built as a "local" build
           prettyurls = !("local" in ARGS),
           canonical = "https://juliadocs.github.io/Documenter.jl/stable/",
           analytics = "UA-89508993-1",
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
