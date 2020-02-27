using Documenter, NOMAD

makedocs(
  sitename = "NOMAD.jl",
  modules = [NOMAD],
  doctest = true,
  linkcheck = true,
  # strict = true,
  format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
  pages = ["Home" => "index.md",
           "Parameters" => "nomadParameters.md",
           "Run Optimization" => "run_nomad.md",
           "Results" => "nomadResults.md",
           "Surrogates" => "surrogates.md",
           "Tutorial" => "tutorial.md"
          ]
)

deploydocs(repo = "github.com/amontoison/NOMAD.jl.git")
