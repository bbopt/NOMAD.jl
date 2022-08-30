# Tutorial

## Moustache problem

```math
\begin{array}{rl}
  (BB) \ \ \ 
  \displaystyle \max_{x,y} & x\\
  s.t.
  & y \in I(x)\\
\end{array}
```

The objective is to maximise $f(x, y) = x$ with $f$ not defined outside of a tight ribbon. At a given $x$, the interval of the admissible $y$ values is denoted $I(x) = [g(x) - \varepsilon(x)$, $g(x) + \varepsilon(x)]$, with

```math
g(x) = -(|\cos(x)| + 0.1) \sin(x) + 2 ~~\text{and}~~ \varepsilon(x) = 0.05 + 0.05 \Bigg(1 + \dfrac{1}{1 + |x - 11|}\Bigg)
```

![](https://user-images.githubusercontent.com/35051714/75482594-21b76680-5973-11ea-94c8-f163c94b27de.png)

We can rewrite the problem such that it can be solved with NOMAD. We choose as starting point $(0, 2)$ and restrict the domain such that $x \in [0,20]$ and
$y \in [0, 4]$.

```math
\begin{array}{rrcll}
  (BB) \ \ \ 
  \displaystyle - \min_{x \in \mathbb{R}^2} && -x_1\\
  s.t.
  &               & g(x_1) - \varepsilon(x_1) - x_2 & \leq 0     & \\
  &               & x_2 - g(x_1) + \varepsilon(x_1) & \leq 0     & \\
  &        0 \leq & x_1                             & \leq 20    & \\
  &        0 \leq & x_2                             & \leq 4     & \\
\end{array}
```

```@example moustache
using NOMAD

# Objective
function f(x)
  return -x[1]
end

# Constraints
function c(x)
  g = -(abs(cos(x[1])) + 0.1) * sin(x[1]) + 2
  ε = 0.05 + 0.05 * (1 - 1 / (1 + abs(x[1] - 11)))
  constraints = [g - ε - x[2]; x[2] - g - ε]
  return constraints
end

# Evaluator
function bb(x)
  bb_outputs = [f(x); c(x)]
  success = true
  count_eval = true
  return (success, count_eval, bb_outputs)
end

# Define Nomad Problem
p = NomadProblem(2, 3, ["OBJ"; "EB"; "EB"], bb,
                lower_bound=[0.0;0.0],
                upper_bound=[20.0;4.0])

# Fix some options
p.options.max_bb_eval = 1000 # total number of evaluations
p.options.display_stats = ["BBE", "EVAL", "SOL", "OBJ", "CONS_H"] # some display options

# Solution
result = solve(p, [0.0;2.0])
println("Solution: ", result.x_best_feas)
```

## Linear equality constraints

It is also possible to define linear equality constraints in a NomadProblem structure.
NOMAD handles differently these constraints and solves the original problem on a reduced subspace.
For more details we refer the reader to:

[C. Audet, S. Le Digabel and M. Peyrega, Linear equalities in blackbox optimization.
*Computational Optimization and Applications*, 61(1), 1-23, May 2015.](https://doi.org/10.1007/s10589-014-9708-2)

We consider the following example:

```math
\begin{array}{rl}
  (BB) \ \ \ 
  \displaystyle \min_{x \in \mathbb{R}^5} & (x_1 -1)^2 + (x_2 - x_3)^2 + (x_4 - x_5)^2\\
  s.t.
  & x_1 + x_2 + x_3 + x_4 + x_5 = 5 \\
  & x_3 -2 x_4 - 2 x_5 = -3\\
  & -10 \leq x_1, x_2, x_3, x_4, x_5 \leq 10\\
\end{array}
```

This problem can be solved by Nomad the following way:
```@example HS48
using NOMAD

# blackbox
function bb(x)
  f = (x[1]- 1)^2 * (x[2] - x[3])^2 + (x[4] - x[5])^2
  bb_outputs = [f]
  success = true
  count_eval = true
  return (success, count_eval, bb_outputs)
end

# linear equality constraints
A = [1.0 1.0 1.0 1.0 1.0;
     0.0 0.0 1.0 -2.0 -2.0]
b = [5.0; -3.0]

# Define blackbox
p = NomadProblem(5, 1, ["OBJ"], # the equality constraints are not counted in the outputs of the blackbox
                 bb,
                 lower_bound = -10.0 * ones(5),
                 upper_bound = 10.0 * ones(5),
                 A = A, b = b)

# Fix some options
p.options.max_bb_eval = 500

# Define starting points. It must satisfy A x = b.
x0 = [0.57186958424864897665429452899843;
      4.9971472653643420613889247761108;
      -1.3793445664086618762667058035731;
      1.0403394252630473459930726676248;
      -0.2300117084673765077695861691609]

# Solution
result = solve(p, x0)
println("Solution: ", result.x_best_feas)
println("Satisfy Ax = b: ", A * result.x_best_feas ≈ b)
println("And inside bound constraints: ", all(-10.0 .<= result.x_best_feas .<= 10.0))
```

The reader can take a look at the [`test`](https://github.com/bbopt/NOMAD.jl/tree/master/test) folder for more complex examples.

## Trade-offs for computational time performance

The default parameters of `NOMAD.jl` closely follow the default parameters of the `NOMAD` software. More importantly, `NOMAD` tries
to find the best solution possible according to the maximum budget of evaluations provided by the user.

However, it can happen the user has a cheap blackbox in terms of computational time and needs a solution in a "short" amount of time.
In this case, the user can remove the default quadratic model options. Generally, the computation of a given solution will be faster,
(i.e. `NOMAD` will evaluate more points in a given amount of time) at a potential detriment of the solution quality.

Let illustrate it on the following problem.

```@example Performance test
using NOMAD

# Objective
function f(x)
    return sqrt((x[1]-20)^2 + (x[2]-1)^2)
end

# Constraints
function c(x)
    constraints = [sin(x[1]) - 1/10 - x[2], x[2] - sin(x[1])]
    return constraints
end

# Evaluator
function bb(x)
    bb_outputs = [f(x); c(x)]
    success = true
    count_eval = true
    return (success, count_eval, bb_outputs)
end

p = NomadProblem(2, 3, ["OBJ"; "PB"; "PB"], bb,
                 lower_bound=[0.0;0.0],
                 upper_bound=[20.0;4.0])

# Set some options
p.options.display_degree = 2
p.options.max_bb_eval = 1500

# Default
println("This is the default")
@time result_default = solve(p, [0.0;0.0])

# Deactivate quadratic models
p.options.quad_model_search = false # for the search step ..
p.options.direction_type = "ORTHO N+1 NEG" # .. and the computation of the n+1 direction.

# One can also deactivate the sorting of poll directions by quadratic models but it is not
# mandatory as it plays a minimal role in the computational performance.
p.options.eval_queue_sort = "DIR_LAST_SUCCESS" 

println("Now with no quadratic models")
@time result_with_no_quad_models = solve(p, [0.0;0.0])
```
Note that the deactivation of quadratic models allows the solver to return a solution in a shorter time.

A good rule of thumb is to keep quadratic models if the blackbox possesses smoothness properties
even if the derivatives are not available.

For more details about the parameters used in this section, we refer the reader to:

[C. Audet, A. Ianni, S. Le Digabel and C. Tribes, Reducing the number of function evaluations in mesh
adaptive direct search algorithms, *SIAM Journal on Optimization*, 24(2), 621-642, 2014.](https://doi.org/10.1137/120895056)
