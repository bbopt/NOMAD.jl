function test_results_consistency(res::results,param::parameters,eval::Function)

	@test length(res.best_feasible)==param.dimension
	@test length(res.bbo_best_feasible)==length(param.output_types)
	(count_eval,bbo_bf) = eval(res.best_feasible)
	@test bbo_bf ≈ res.bbo_best_feasible



	if res.infeasible
		@test length(res.best_infeasible)==param.dimension
		@test length(res.bbo_best_infeasible)==length(param.output_types)
		(count_eval,bbo_bi) = eval(res.best_infeasible)
		@test bbo_bi ≈ res.bbo_best_infeasible
	end

	@test result1.bb_eval <= param1.max_bb_eval

end
