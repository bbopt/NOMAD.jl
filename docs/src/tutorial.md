# Tutorial

## Moustache problem

```math
\begin{array}{rl}
  (BB) \ \ \ 
  \displaystyle \max_{x,y} & x\\
  s.t. & y \in I(x)\\
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
p.options.max_bb_eval = 1000

# Solution
result = solve(p, [0.0;2.0])
println("Solution: ", result.x_best_feas)
```
