# NOMAD.jl

Documentation :
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://ppascal97.github.io/NOMAD.jl/dev)

Linux and macOS: [![Build Status](https://travis-ci.org/ppascal97/NOMAD.jl.svg?branch=master)](https://travis-ci.org/ppascal97/NOMAD.jl)

This package provides a Julia interface for NOMAD, which is a C++ implementation of the Mesh Adaptive Direct Search algorithm (MADS), designed for difficult blackbox optimization problems. These problems occur when the functions defining the objective and constraints are the result of costly computer simulations.

## Installation

```julia
    pkg> add https://github.com/ppascal97/NOMAD.jl.git
```

Then, NOMAD needs to be extracted and compiled for its libraries to be accessible from NOMAD.jl. Just type :

```julia
    pkg> build -v NOMAD
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

You first need to declare a function `eval(x::Vector{Float64})` that returns a *Vector{Float64}* containing the objective function and the constraint evaluated for `x`, along with a boolean.

```julia
    function eval(x)
        bb_outputs = [f(x),c(x)]
        success = true
        count_eval = true
        return (success, count_eval, bb_outputs)
    end
```

`success` is a boolean set to false if the evaluation failed. Here, every evaluation is a success. `count_eval` is also a boolean defining if the evaluation needs to be taken into account by NOMAD. Here, it is always equal to true so every evaluation will be considered.

Then create an object of type *nomadParameters* that will contain options for the optimization. The classic constructor takes as arguments the initial point *x0* and the types of the outputs contained in `bb_outputs` (as a *Vector{String}*).

```julia
    param = nomadParameters([3,3],["OBJ","EB"])
    param.lower_bound = [-5,-5]
    param.upper_bound = [5,5]
```

Here, first element of bb_outputs is the objective function (`f(x)`), second is a constraint treated with the Extreme Barrier method (`c(x)`).

Now call the function `runopt` with these arguments to launch a NOMAD optimization process.

```julia
    result = runopt(eval, param)
```

The object of type *nomadResults* returned by `runopt` contains information about the run.
