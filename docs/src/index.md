# [NOMAD.jl documentation] (@id Home)

This package provides a Julia interface for NOMAD, which is a C++ implementation of the Mesh Adaptive Direct Search algorithm (MADS), designed for difficult blackbox optimization problems. These problems occur when the functions defining the objective and constraints are the result of costly computer simulations.

## Type of problems treated

NOMAD allows to deal with optimization problems of the form :

```math
\begin{align*}
\min \quad & f(x) \\
& c_i(x) \leq 0, \quad i \in I, \\
& \ell \leq x \leq u,
\end{align*}
```

where ``f:\mathbb{R}^n\rightarrow\mathbb{R}``,
``c:\mathbb{R}^n\rightarrow\mathbb{R}^m``,
``I = \{1,2,\dots,m\}``,
and
``\ell_j, u_j \in \mathbb{R}\cup\{\pm\infty\}``
for ``i = 1,\dots,m``.

The functions ``f`` and ``c_i`` are typically blackbox functions whose evaluations require computer simulation.

## Quick start

You first need to declare a function `eval(x::Vector{Float64})` that returns a boolean and a *Vector{Float64}* that contains the objective function and constraints evaluated for `x`.

    function eval(x)
        f=x[1]^2+x[2]^2
        c=1-x[1]
        count_eval=true
        bb_outputs = [f,c]
        return (count_eval,bb_outputs)
    end

The boolean `count_eval` defines whether the evaluation needs to be taken into account by NOMAD. Here, it is always equal to true so every evaluation will be considered.

Then create an object of type *parameters* that will contain options for the optimization. You need to define at least the dimension of the problem, the initial point `x0` and the types of the outputs contained in `bb_outputs`.

    param = parameters()
    param.dimension = 2
    param.output_types = ["OBJ","EB"]
    param.x0 = [3,3]

Here, first element of bb_outputs is the objective function (`f`), second is a constraint treated with the Extreme Barrier method (`c`).

Now call the function `runopt` with these arguments to launch a NOMAD optimization process.

    result = runopt(eval,param)

The object of type *results* returned by `runopt` contains information about the run.
