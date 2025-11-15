@testset "VNS testing : a Camel variant function with many local optima" begin
    # blackbox
    function bb(x)
        a = x[1]
        b = x[2]
        f = exp(sin(50 * a)) + sin(60 * exp(b)) + sin(70 * sin(a)) + sin(sin(80*b)) - sin(10 * (a+b)) + 0.25 * (a^2 + b^2)
        bb_outputs = [f]
        success = true
        count_eval = true
        return (success, count_eval, bb_outputs)
    end

    @test_throws(ErrorException, begin
                     p = NomadProblem(2, 1, ["OBJ"], bb,
                                      lower_bound = -5.0 * ones(2),
                                      upper_bound = 5.0 * ones(2);
                                      initial_mesh_size = [0.5, 0.5])
                     p.options.vns_mads_search_max_trial_pts_nfactor = -4
                     solve(p, [3.0, 3.0])
                 end)

    p = NomadProblem(2, 1, ["OBJ"], bb,
                     lower_bound = -5.0 * ones(2),
                     upper_bound = 5.0 * ones(2);
                     initial_mesh_size = [0.5, 0.5])

    p.options.max_bb_eval = 10000
    p.options.speculative_search = false
    p.options.nm_search = false
    p.options.quad_model_search = false
    p.options.eval_queue_sort = "DIR_LAST_SUCCESS"
    p.options.vns_mads_search = true
    p.options.display_degree = 2

    # First resolution
    x0 = [3.0, 3.0]
    result_vns = solve(p, x0)
    @test result_vns.status == 1
    @test result_vns.x_sol !== nothing
    @test result_vns.bbo_sol !== nothing
    @test result_vns.feasible == true

    # Second resolution
    p.options.vns_mads_search = false
    result_wo_vns = solve(p, x0)
    @test result_wo_vns.status == 1
    @test result_wo_vns.x_sol !== nothing
    @test result_wo_vns.bbo_sol !== nothing
    @test result_wo_vns.feasible == true

    # This result does not mean than the vns strategy is more efficient on this problem.
    # Removing sgtelib search to get a simple mads results in a big improvement.
    @test result_vns.bbo_sol[1] < result_wo_vns.bbo_sol[1]

    # Third resolution with vnssmart_mads_search and line search
    p.options.vnsmart_mads_search = true
    p.options.simple_line_search = true
    p.options.speculative_search = false
    result_vnsmart = solve(p, x0)
    @test result_vnsmart.status == 1
    @test result_vnsmart.x_sol !== nothing
    @test result_vnsmart.bbo_sol !== nothing
    @test result_vnsmart.feasible == true
    @test result_vnsmart.bbo_sol[1] < result_wo_vns.bbo_sol[1]
end
