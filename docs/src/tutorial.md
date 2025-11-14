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
println("Optimization status: ", result.status)
println("Solution: ", result.x_sol)
println("is feasible: ", result.feasible)
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
println("status: ", result.status)
println("Solution: ", result.x_sol)
println("Satisfy Ax = b: ", A * result.x_sol ≈ b)
println("And inside bound constraints: ", all(-10.0 .<= result.x_sol .<= 10.0))
```

The reader can take a look at the [`test`](https://github.com/bbopt/NOMAD.jl/tree/master/test) folder for more complex examples.

## Trade-offs for computational time performance

The default parameters of `NOMAD.jl` closely follow the default parameters of the `NOMAD` software. More importantly, `NOMAD` tries
to find the best solution according to the maximum budget of evaluations provided by the user.

However, it happens that the user has a cheap blackbox in terms of computational time and needs a solution in a "short" amount of time.
In this case, the user can remove the default quadratic model options. Generally, the computation of a given solution will be faster,
(i.e. `NOMAD` will evaluate more points in a given amount of time) at a potential detriment of the solution quality.

Let illustrate it on the following problem.

```@example performance_test
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

## Multiobjective optimization

`NOMAD.jl` can solve multiobjective optimization problems of the form:
```math
\begin{array}{rl}
  (MBB) \ \ \
  \displaystyle \min_{x \in \mathbb{R}^n} & f(x) = \left(f_1(x), f_2(x), \ldots, f_m(x)\right)^\top\\
  s.t.
  & c(x) \leq 0 \\
  & lb \leq x \leq ub \\
\end{array}
```
where $m \geq 2$ is the number of objectives.

Unlike single-objective optimization, the set of solutions to such a problem is generally not a singleton.
It is composed of several solutions whose objective values represent the best trade-offs that the
algorithm may achieve at the end of the optimization.

`NOMAD.jl` switches to multiobjective mode when a `NomadProblem` is given more than one objective `OBJ` as
parameter. However, `NOMAD.jl` only supports up to `5` objectives. Keep in mind that the larger the number of
objectives, the more difficult the problem is to solve.

Finally, the multiobjective mode of `NOMAD.jl` does not support certain options available in
single-objective optimization. Specifically, in multiobjective optimization, `NOMAD.jl` deactivates
all search strategies except the speculative search, the `NM` search and the `Quadratic model`
search. The default `eval_sort_type` and `direction_type` options are switched to `"DIR_LAST_SUCCESS"`
and `"ORTHO N+1 QUAD"`, respectively.

We consider the following example, the optimal design of a welded beam.

```math
\begin{array}{rl}
  (WB) \ \ \
  \displaystyle \min_{x = (h, l, t, b) \in \mathbb{R}^4} & \left(1.10471 h^2 l + 0.04811 t b (14.0 + l), \dfrac{2.1952}{t^3 b}\right)^\top \\
  s.t.
  & c_1(x) = \tau(x) - 13600 \leq 0  \\
  & c_2(x) = \sigma(x) - 30000 \leq 0\\
  & c_3(x) = h - b \leq 0\\
  & c_4(x) = 6000 - P_c(x) \leq 0\\
  & h, b \in [0.125, 5], l, t \in [0.1, 10]\\
\end{array}
```
where $h, l, t, b$ are the four design parameters to optimize.

The following equations describe the physics constraints of the system (stress and buckling terms):

```math
\begin{array}{rl}
  \tau(x) & = \sqrt{(\tau')^2 + (\tau'')^2 + \dfrac{l \tau' \tau''}{\sqrt{0.25 (l^2 + (h + t)^2))}}}, \\ 
  \tau' & = \dfrac{6000}{\sqrt{2} h l},  \\
  \tau'' & = \dfrac{6000 (14 + 0.5 l) \sqrt{0.25 (l^2 + (h + t)^2))}}{2 \left(0.707 h l (l^2/12 + 0.25 (h + t)^2)\right)},\\
  \sigma(x) & = \dfrac{504000}{t^2 b},\\
  P_c(x) & = 64746.022 (1 - 0.0282346 t) t b^3.
\end{array}
```

$f_1$ corresponds to the construction costs and $f_2$ the end deflection (which corresponds to rigidity) of the beam. Both must be minimized.

```@example welded_beam_design
using NOMAD

# blackbox
function welded_beam(x)
    # Variables
    h = x[1]
    l = x[2]
    t = x[3]
    b = x[4]

    # Objectives
    f1 = 1.10471 * h^2 * l + 0.04811 * t * b * (14.0 + l)
    f2 = 2.1952 / (t^3 * b)

    # Physics equations
    tau_p = 6000.0 / (sqrt(2) * h * l)
    tau_pp = 6000 * (14 + 0.5 * l) * sqrt(0.25 * (l^2 + (h + t)^2))
    tau_pp /= (2 * (0.707 * h * l * (l^2 / 12.0 + 0.25 * (h + t)^2)))
    tau = sqrt(tau_p^2 + tau_pp^2 + l * tau_p * tau_pp / sqrt(0.25 * (l^2 + (h + t)^2)))
    sigma = 504000 / (t^2 * b)
    Pc = 64746.022 * (1 - 0.0282346 * t) * t * b^3

    # Constraints
    c1 = tau - 13600
    c2 = sigma - 30000
    c3 = h - b
    c4 = 6000 - Pc

    bb_outputs = [f1, f2, c1, c2, c3, c4]
    success = true
    count_eval = true
    return (success, count_eval, bb_outputs)
end

# Define the problem
lb = [0.125, 0.1, 0.1, 0.125]
ub = [5.0, 10.0, 10.0, 5.0]
pb = NomadProblem(4, 6, ["OBJ", "OBJ", "PB", "PB", "PB", "PB"],
                  welded_beam,
                  lower_bound=[0.125, 0.1, 0.1, 0.125],
                  upper_bound=[5.0, 10.0, 10.0, 5.0])

# Set some options
pb.options.display_degree = 2
pb.options.max_bb_eval = 1500

# As for the single-objective case, you could deactivate this
# option to go faster, but the performance may be worse
# pb.options.quad_model_search = false

# Start from a middle box point
result = solve(pb, (lb + ub) / 2)

# The solution set is returned as a matrix of dimensions n x nb_solutions,
# where n is the dimension of the problem.
println("Optimization status: ", result.status)
println("The algorithm has found ", size(result.x_sol, 2), " solutions:")
for (ind, (x, bbo)) in enumerate(zip(eachcol(result.x_sol), eachcol(result.bbo_sol)))
  println("Solution ", ind, ": ", x,
          "; f(x) = ", bbo[1:2],
          "; c(x) = ", bbo[3:end])
end
println("They are ", result.feasible ? "feasible" : "infeasible")

# In multiobjective optimization, it can be interesting to see the
# set of trade-offs in the objective space
using Plots
fig = scatter(result.bbo_sol[1, :], result.bbo_sol[2, :],
              xlabel="Cost", ylabel="Deflection",
              title="Pareto front approximation")
fig
```

For more information about the multiobjective algorithm (DMulti-MADS), please refer to the following articles:

[J. Bigeon, S. Le Digabel, & L. Salomon, DMulti-MADS: Mesh adaptive direct multisearch for bound-constrained
 blackbox multiobjective optimization, *Computational Optimization and Applications*, 79(2), 301-338, 2021.](https://doi.org/10.1007/s10589-021-00272-9)

[J. Bigeon, S. Le Digabel, & L. Salomon, Handling of constraints in multiobjective blackbox optimization,
 *Computational Optimization and Applications*, 89(1), 69-113, 2024.](https://doi.org/10.1007/s10589-024-00588-2)

[S. Le Digabel, A. Lesage-Landry, L. Salomon, & C. Tribes (2025),
 Efficient search strategies for constrained multiobjective blackbox optimization,
 arXiv preprint arXiv:2504.02986., 2025.](https://doi.org/10.48550/arXiv.2504.02986)

The problem is taken from:

[K. Deb, Evolutionary algorithms for multi-criterion optimization in engineering design,
 *Evolutionary algorithms in engineering and computer science*, 2, 135-161, (1999)]()
