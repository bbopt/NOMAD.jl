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

The functions ``f`` and ``c_i`` are typically blackbox functions of which evaluations require computer simulation.

## Quick start

It is first needed to declare a function `eval(x::Vector{Float64})` that returns two booleans and a *Vector{Float64}* that contains the objective function and constraints evaluated for `x`.

    function eval(x)
        f=x[1]^2+x[2]^2
        c=1-x[1]
	success=true
        count_eval=true
        bb_outputs = [f,c]
        return (success,count_eval,bb_outputs)
    end

`success` is a *Bool* that should be set to `false` if the evaluation failed. `count_eval` is a *Bool* that should be equal to `true` if the black box evaluation counting has to be incremented.

Then an object of type *nomadParameters* has to be created, it will contain options for the optimization. The arguments of its constructor are the initial point `x0` and the types of the outputs contained in `bb_outputs`.

    param = nomadParameters([3,3],["OBJ","EB"])
    param.lower_bound = [-5,-5]
    param.upper_bound = [5,5]

Here, first element of bb_outputs is the objective function (`f`), second is a constraint treated with the Extreme Barrier method (`c`). In this example, lower and upper bounds have been added but it is not compulsory.

Now the function `nomad()` can be called with these arguments to launch a NOMAD optimization process.

    result = nomad(eval,param)

The object of type *nomadResults* returned by `nomad` contains information about the run. Use the function `disp(result::nomadResults` to display this info.
