# NOMAD.jl

Documentation:
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://ppascal97.github.io/NOMAD.jl/dev)

Linux and macOS: [![Build Status](https://travis-ci.org/ppascal97/NOMAD.jl.svg?branch=master)](https://travis-ci.org/ppascal97/NOMAD.jl)

Code coverage: [![Coverage Status](https://coveralls.io/repos/github/ppascal97/NOMAD.jl/badge.svg?branch=master)](https://coveralls.io/github/ppascal97/NOMAD.jl?branch=master)

This package provides a Julia interface for NOMAD, which is a C++ implementation of the Mesh Adaptive Direct Search algorithm (MADS), designed for difficult blackbox optimization problems. These problems occur when the functions defining the objective and constraints are the result of costly computer simulations.

## Installation

```julia
    pkg> add https://github.com/ppascal97/NOMAD.jl.git
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

You first need to declare a function `eval(x::Vector{Float64})` that returns a *Vector{Float64}* containing the objective function and the constraint evaluated for `x`, along with two booleans.

```julia
    function eval(x)
        bb_outputs = [f(x),c(x)]
        success = true
        count_eval = true
        return (success, count_eval, bb_outputs)
    end
```

`success` is a boolean set to false if the evaluation should not be taken into account by NOMAD. Here, every evaluation will be considered as a success. `count_eval` is also a boolean, it decides weather the evaluation's counter will be incremented. Here, it is always equal to true so every evaluation will be counted.

Then, create an object of type *nomadParameters* that will contain options for the optimization. The classic constructor takes as arguments the initial point *x0* and the types of the outputs contained in `bb_outputs` (as a *Vector{String}*).

```julia
    param = nomadParameters([3,3],["OBJ","EB"])
    param.lower_bound = [-5,-5]
    param.upper_bound = [5,5]
```

Here, first element of bb_outputs is the objective function (`f(x)`), second is a constraint treated with the Extreme Barrier method (`c(x)`). In this example, lower and upper bounds have been added but it is not compulsory.

Now call the function `nomad()` with these arguments to launch a NOMAD optimization process.

```julia
    result = nomad(eval, param)
```

The object of type *nomadResults* returned by `nomad()` contains information about the run.
