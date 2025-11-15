@testset "Example 1" begin

    function bb1(x)
        sum1 = sum(cos.(x).^4)
        sum2 = sum(x)
        sum3 = (1:length(x)) .* x
        prod1 = prod(cos.(x).^2)
        prod2 = prod(x)
        g1 = -prod2 + 0.75
        g2 = sum2 - 7.5 * length(x)
        f = 10 * g1 + 10 * g2
        if (sum3 ≠ 0.0)
            f -= abs((sum1 - 2 * prod1) / sqrt(3))
        end

        # scaling
        f *= 10^(-5)
        c2000 = -f -2000
        return (true, true, [g1; g2; f; c2000])
    end

    p = NomadProblem(10, 4, ["PB"; "PB"; "OBJ"; "EB"], bb1,
                     granularity=0.0000001 * ones(Float64, 10))

    @test p.options.display_degree == 2
    @test p.options.display_all_eval == false
    @test p.options.display_unsuccessful == false
    @test p.options.max_bb_eval == 20000
    @test p.options.eval_opportunistic == true
    @test p.options.eval_use_cache == true
    @test p.options.lh_search == (0,0)
    @test p.options.speculative_search == true
    @test p.options.nm_search == true

    p.options.max_bb_eval = 1000
    p.options.display_all_eval = true
    p.options.display_unsuccessful = false
    p.options.cache_size_max = 10000
    p.options.display_stats = ["BBE", "EVAL", "SOL", "OBJ", "CONS_H"]

    # run the problem and get solutions
    result1 = solve(p, 7.0 * ones(Float64, 10))

    # rerun the problem by changing display options
    p.options.display_all_eval = false
    result2 = solve(p, 7.0 * ones(Float64, 10))

    @test result1 == result2

    println(result2)

end

@testset "Example 2 : mustache problem" begin

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

    p = NomadProblem(2, 3, ["OBJ"; "EB"; "EB"], bb,
                     lower_bound=[0.0;0.0],
                     upper_bound=[20.0;4.0],
                     min_mesh_size=[1e-9, 1e-9])

    # fix some options
    p.options.max_bb_eval = 1000
    p.options.quad_model_search = false # deactivate quadratic model subproblem resolution
    p.options.direction_type = "ORTHO N+1 NEG"
    p.options.eval_queue_sort = "DIR_LAST_SUCCESS" # deactivate use of quadratic ordering
    p.options.speculative_search_max = 2
    p.options.max_time = 200 # fix maximum execution time

    # Only find a feasible solution
    p.options.stop_if_feasible = true
    init_result = solve(p, [0.0;2.0])
    @test init_result.feasible == true
    @test init_result.x_sol !== nothing
    @test init_result.bbo_sol !== nothing
    @test init_result.status == -6

    p.options.stop_if_feasible = false
    result1 = solve(p, [0.0;2.0])

    # result1 should be better than init_result
    @test init_result.bbo_sol[1] > result1.bbo_sol[1]
    @test result1.status == 0

    # Check reproducibility
    result2 = solve(p, [0.0;2.0])

    @test result1 == result2

    p = NomadProblem(2, 3, ["OBJ"; "EB"; "EB"], bb,
                     lower_bound=[0.0;0.0],
                     upper_bound=[20.0;4.0],
                     initial_mesh_size=1e-1*ones(2))

    # fix some options
    p.options.max_bb_eval = 1000
    p.options.quad_model_search = false # deactivate quadratic model search
    p.options.eval_queue_sort = "LEXICOGRAPHICAL" # deactivate use of quadratic ordering
    p.options.direction_type_secondary_poll = "ORTHO N+1 NEG"
    p.options.speculative_search_max = 2
    p.options.cache_size_max = 10000

    result3 = solve(p, [0.0;2.0])

    @test result3 != result2

end
