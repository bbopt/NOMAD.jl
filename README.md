# NOMAD.jl

| **Documentation** | **Travis** | **Coverage** | **DOI** |
|:-----------------:|:----------:|:------------:|:-------:|
| [![](https://img.shields.io/badge/docs-dev-blue.svg)](https://bbopt.github.io/NOMAD.jl/dev) | ![](https://github.com/bbopt/NOMAD.jl/workflows/CI/badge.svg)](https://github.com/bbopt/NOMAD.jl/actions) | [![Coverage Status](https://coveralls.io/repos/github/bbopt/NOMAD.jl/badge.svg?branch=master)](https://coveralls.io/github/bbopt/NOMAD.jl?branch=master) | [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3700167.svg)](https://doi.org/10.5281/zenodo.3700167) |

This package provides a Julia interface for NOMAD, which is a C++ implementation of the Mesh Adaptive Direct Search algorithm (MADS), designed for difficult blackbox optimization problems. These problems occur when the functions defining the objective and constraints are the result of costly computer simulations.

## How to Cite

If you use NOMAD.jl in your work, please cite using the format given in [`CITATION.bib`](https://github.com/bbopt/NOMAD.jl/blob/master/CITATION.bib).

## Installation

NOMAD can be installed and tested through the Julia package manager:

```julia
julia> ]
pkg> add NOMAD
pkg> test NOMAD
```

## Quick start

Let's say you want to minimize some objective function :

```julia
function f(x)
  return x[1]^2 + x[2]^2
end
```

while keeping some constraint inferior to 0 :

```julia
function c(x)
  return 1 - x[1]
end
```

You first need to declare a function `eval_fct(x::Vector{Float64})` that returns a *Vector{Float64}* containing the objective function and the constraint evaluated for `x`, along with two booleans.

```julia
function eval_fct(x)
  bb_outputs = [f(x), c(x)]
  success = true
  count_eval = true
  return (success, count_eval, bb_outputs)
end
```

`success` is a boolean set to false if the evaluation should not be taken into account by NOMAD. Here, every evaluation will be considered as a success. `count_eval` is also a boolean, it decides weather the evaluation's counter will be incremented. Here, it is always equal to true so every evaluation will be counted.

Then, create an object of type *NomadProblem* that will contain settings for the optimization.

#The classic constructor takes as arguments the initial point *x0* and the types of the outputs contained in `bb_outputs` (as a *Vector{String}*).

```julia
pb = NomadProblem(2, # number of inputs of the blackbox
                  2, # number of outputs of the blackbox
                  ["OBJ", "EB"], # type of outputs of the blackbox
                  eval_fct;
                  lower_bound=[-5.0, -5.0],
                  upper_bound=[5.0, 5.0])
```

Here, first element of bb_outputs is the objective function (`f(x)`), second is a constraint treated with the Extreme Barrier method (`c(x)`). In this example, lower and upper bounds have been added but it is not compulsory.

Now call the function `solve(p::NomadProblem, x0::Vector{Float64})` where *x0* is the initial starting point to launch a NOMAD optimization process.

```julia
result = solve(pb, [3.0, 3.0])
```

The object returned by `solve()` contains information about the run.
