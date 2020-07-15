# [NOMAD.jl documentation] (@id Home)

This package provides a Julia interface for NOMAD, which is a C++ implementation of the Mesh Adaptive Direct Search algorithm (MADS), designed for difficult blackbox optimization problems. These problems occur when the functions defining the objective and constraints are the result of costly computer simulations.

## Type of problems treated

NOMAD allows to deal with optimization problems of the form :

```math
\begin{array}{rrcll}
  (BB) \ \ \ 
  \displaystyle \min_{x} && f(x)\\
  s.t.
  &               & c_i(x) & \leq 0     & \forall i = 1, ..., m\\
  & \ell_{j} \leq & x_{j}  & \leq u_{j} & \forall j = 1, ..., n\\
\end{array}
```

where ``f:\mathbb{R}^n\rightarrow\mathbb{R}``, ``~c:\mathbb{R}^n\rightarrow\mathbb{R}^m``,
and ``\ell_j, u_j \in \mathbb{R}\cup\{\pm\infty\}`` for ``j = 1,\dots,n``.

The functions ``f`` and ``c_i`` are typically blackbox functions of which evaluations require computer simulation.

## Quick start

First, one needs to declare a blackbox `bb(x :: Vector{Float64})` that returns two booleans and a *Vector{Float64}* that contains the objective function and constraints evaluated for `x`.

```julia
function bb(x)
  f = x[1]^2 + x[2]^2
  c = 1 - x[1]
  success = true
  count_eval = true
  bb_outputs = [f; c]
  return (success, count_eval, bb_outputs)
end
```

`success` is a *Bool* that should be set to `false` if the evaluation failed. `count_eval` is a *Bool* that should be equal to `true` if the black box evaluation counting has to be incremented.

To optimize this blackbox, an object of type *NomadProblem* has to be created. It takes as arguments the number of inputs, the number of outputs and the type of the outputs of the blackbox, and the blackbox. Other options can be passed to a *NomadProblem* object.

```julia
p = NomadProblem(2, 2, ["OBJ"; "EB"], bb,
                lower_bound=[-5.0;-5.0],
                upper_bound=[5.0;5.0])
```

Here, first element of bb_outputs is the objective function (`f`), second is a constraint treated with the Extreme Barrier method (`c`). In this example, lower and upper bounds have been added but it is not compulsory.

Now the function `solve()` can be called with these arguments to launch a NOMAD optimization run.

```julia
result = solve(p, [3.0;3.0])
```

What is returned by the `solve` function is a *NamedTuple* containing solutions and corresponding blackbox values found by the *Nomad* solver.
