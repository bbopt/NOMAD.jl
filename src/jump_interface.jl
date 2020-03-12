using JuMP, MathOptInterface
const MOI = MathOptInterface

export createNomadProblem_jump

function createNomadProblem_jump(jmodel :: JuMP.Model)

  eval = NLPEvaluator(jmodel)
  MOI.initialize(eval, [:Grad])
  nvar = num_variables(jmodel)
  vars = all_variables(jmodel)
  lvar = map(var -> has_lower_bound(var) ? lower_bound(var) : -Inf, vars)
  uvar = map(var -> has_upper_bound(var) ? upper_bound(var) :  Inf, vars)

  x0 = zeros(nvar)
  for (i, val) ∈ enumerate(start_value.(vars))
    if val !== nothing
      x0[i] = val
    end
  end

  ncon = num_nl_constraints(jmodel)
  cons = jmodel.nlp_data.nlconstr
  lcon = map(con -> con.lb, cons)
  ucon = map(con -> con.ub, cons)

  eq = Int[]
  for i = 1:ncon
    if lcon[i] == ucon[i]
      push!(eq, i)
    end
  end
  neq = length(eq)

  function nlp(x, outputs)
    val_obj = MOI.eval_objective(eval, x)
    val_cons = zeros(ncon)
    MOI.eval_constraint(eval, val_cons, x)
    outputs[1] = objective_sense(jmodel) == MOI.MIN_SENSE ? val_obj : -val_obj
    j = 1
    for i = 1:ncon
      if i ∈ eq
        outputs[j]   = lcon[i] - val_cons[i]
        outputs[j+1] = val_cons[i] - ucon[i]
        j = j+2
      elseif lcon[i] != -Inf
        outputs[j] = lcon[i] - val_cons[i]
        j = j + 1
      else
        outputs[j] = val_cons[i] - ucon[i]
        j = j + 1
      end
    end
    return false
  end

  type_obj = ["OBJ"]
  type_con = ["EB" for i = 1:ncon+neq]
  type_outputs = [type_obj; type_con]

  return createNomadProblem(nvar, ncon+neq+1, nlp, type_outputs, 1000, x0=x0, x_lb=lvar, x_ub=uvar)
end