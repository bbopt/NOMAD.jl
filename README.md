# NOMAD.jl

This package provides a Julia interface for NOMAD, which is a C++ implementation of the Mesh Adaptive Direct Search algorithm (MADS), designed for difficult blackbox optimization problems. These problems occur when the functions defining the objective and constraints are the result of costly computer simulations.

## Installation

    pkg> add NOMAD

Then, NOMAD needs to be extracted and compiled for its libraries to be accessible from NOMAD.jl. Just type :

    pkg> build NOMAD
    pkg> test NOMAD


## Quick start

Let's say you want to minimize some objective function :

    function f(x)
        return x[1]^2+x[2]^2
    end

while keeping some constraint inferior to 0 :

    function c(x)
        return 1-x[1]
    end

You first need to declare a function `eval(x::Vector{Float64})` that returns a *Vector{Float64}* that contains the objective function and the constraint evaluated for `x`, along with a boolean.

    function eval(x)
        bb_outputs = [f(x),c(x)]
        count_eval=true
        return (count_eval,bb_outputs)
    end

The boolean `count_eval` defines if the evaluation needs to be taken into account by NOMAD. Here, it is always equal to true so every evaluation will be considered.

Then create an object of type *parameters* that will contain options for the optimization. You need to define at least the dimension of the problem, the initial point *x0* and the types of the outputs contained in `bb_outputs`.

    param = parameters()
    param.dimension = 2
    param.output_types = ["OBJ","EB"]
    param.x0 = [3,3]

Here, the first element of bb_outputs is the objective function (`f(x)`), second is a constraint treated with the Extreme Barrier method (`c(x)`).

Now call the function `runopt` with these arguments to launch a NOMAD optimization process.

    result = runopt(eval,param)

The object of type *results* returned by `runopt` contains information about the run.
