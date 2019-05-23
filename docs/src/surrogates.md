# Surrogates

The current version of NOMAD can use static surrogates which are not updated
during the algorithm and which are provided by the user. A surrogate provides
approximations of the black box outputs and is typically less time-consuming to
evaluate. Hence, their use allows to speed up the optimization process.

Such surrogates can be provided to NOMAD.jl as simple *Function* objects of the
following form :

    (count_eval,sgte_outputs) = surrogate(x::Vector{Number})

The surrogate needs to return the same number of outputs as the function
eval(x), with the same types and in the same order. Just like for eval(x),
count_eval is a *Bool* determining if the evaluation has to be taken into account,
and success is a *Bool* equal to false if the evaluation failed.

You can directly provide it to the function `nomad` as a third argument. The
corresponding method is :

    nomad(eval::Function,param::nomadParameters,surrogate::Function)

which returns an object of type *nomadResults*.

The cost of the surrogate can be set via the attribute `sgte_cost` of the
nomadParameters provided to nomad(). More precisely, `sgte_cost` is the number
of surrogate evaluations costing as much as one black box evaluation.
If set to 0, a surrogate evaluation is considered as free.
It is set to 0 by default.
