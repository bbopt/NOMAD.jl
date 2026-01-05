@testset "Kursawe" begin

    function kursawe(x)
        n = 3

        # functions
        f1 = sum(-10 * exp.(-0.2 * sqrt.(x[1:n-1].^2 + x[2:n].^2)));
        f2 = sum(abs.(x[1:n]).^0.8 + 5 * sin.(x[1:n]).^3);

        return (true, true, [f1;f2])
    end

    p = NomadProblem(3, 2, ["OBJ"; "OBJ"], kursawe,
                     lower_bound = -5.0 * ones(3),
                     upper_bound = 5.0 * ones(3))

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
    result1 = solve(p, 2.0 * ones(Float64, 3))

    # rerun the problem by changing display options
    p.options.display_all_eval = false
    # This option must be changed
    p.options.direction_type = "ORTHO N+1 QUAD"
    # These options are ignored
    p.options.sgtelib_model_search = true
    p.options.simple_line_search = true
    p.options.vns_mads_search = true
    p.options.vnsmart_mads_search = true
    result2 = solve(p, 2.0 * ones(Float64, 3))

    @test result1 == result2

    println("Number of solutions: ", size(result2.x_sol, 2))
end

@testset "Car Side impact" begin

    function car_side_impact(x)
        x1 = x[1]
        x2 = x[2]
        x3 = x[3]
        x4 = x[4]
        x5 = x[5]
        x6 = x[6]
        x7 = x[7]

        Pfp = 4.72 - 0.5 * x4 - 0.19 * x2 * x3
        Vmbp = 10.58 - 0.674 * x1 * x2 - 0.67275 * x2
        Vfd = 16.45 - 0.489 * x3 * x7 - 0.843 * x5 * x6

        # Objectives
        f1 = 1.98 + 4.9 * x1 + 6.67 * x2 + 6.98 * x3 + 4.01 * x4 + 1.78 * x5 + 0.00001 * x6 + 2.73 * x7
        f2 = Pfp
        f3 = 0.5 * (Vfd + Vmbp)

        # Constraints
        g1 = 1.16 - 0.3717x2 * x4 - 0.0092928 * x3 # <= 1
        g2 = 0.261 - 0.0159 * x1 * x2 - 0.06486 * x1 - 0.019 * x2 * x7 + 0.0144 * x3 * x5 + 0.0154464 * x6 # <= 0.32
        g3 = 0.214 + 0.00817 * x5 - 0.045195 * x1 - 0.0135168 * x1 + 0.03099 * x2 * x6 - 0.018 * x2 * x7 + 0.007176 * x3 +
             0.023232 * x3 - 0.00364 * x5 * x6 - 0.018 * x2 * x2 # <= 0.32
        g4 = 0.74 - 0.61 * x2 - 0.031296 * x3 - 0.031872 * x7 + 0.227 * x2 * x2 # <= 0.32
        g5 = 28.98 + 3.818 * x3 - 4.2 * x1 * x2 + 1.27296 * x6 - 2.68065 * x7 # <= 32
        g6 = 33.86 + 2.95 * x3 - 5.057 * x1 * x2 - 3.795 * x2 - 3.4431 * x7 + 1.45728 # <= 32
        g7 = 46.36 - 9.9 * x2 - 4.4505 * x1 # <= 32
        g8 = 4 - f2  # >= 0
        g9 = 9.9 - Vmbp  # >= 0
        g10 = 15.7 - Vfd  # >= 0

        return (true, true, [f1,f2,f3,g1-1,g2-0.32,g3-0.32,g4-0.32,g5-32,g6-32,g7-32,-g8,-g9,-g10])
    end

    lb = [0.5, 0.45, 0.5, 0.5, 0.875, 0.4, 0.4]
    ub = [1.5, 1.35, 1.5, 1.5, 2.625, 1.2, 1.2]
    p = NomadProblem(7, 13, vcat(repeat(["OBJ"], 3), repeat(["PB"], 10)),
                     car_side_impact,
                     lower_bound = lb,
                     upper_bound = ub)

    @test p.options.display_degree == 2
    @test p.options.display_all_eval == false
    @test p.options.display_unsuccessful == false
    @test p.options.max_bb_eval == 20000
    @test p.options.eval_opportunistic == true
    @test p.options.eval_use_cache == true
    @test p.options.lh_search == (0,0)
    @test p.options.speculative_search == true
    @test p.options.nm_search == true

    p.options.max_bb_eval = 1500
    p.options.display_all_eval = true
    p.options.display_unsuccessful = false
    p.options.cache_size_max = 10000

    # run the problem and get solutions
    result1 = solve(p, (lb + ub) / 2.)
    @test result1.feasible == true
    @test result1.status == 0
    @test size(result1.x_sol, 2) == size(result1.bbo_sol, 2)
    @test size(result1.x_sol, 2) >= 1
    @test size(result1.x_sol, 1) == 7
    @test size(result1.bbo_sol, 1) == 13

    # rerun the problem and deactivate some options
    p.options.display_all_eval = false
    p.options.quad_model_search = false
    p.options.nm_search = false
    p.options.direction_type = "ORTHO 2N"
    # This option will be changed
    p.options.direction_type_secondary_poll = "ORTHO N+1 QUAD"

    result2 = solve(p, (lb + ub) / 2.)

    @test result1 != result2
    @test result2.feasible == true
    @test result2.status == 0
    @test size(result2.x_sol, 2) == size(result2.bbo_sol, 2)
    @test size(result2.x_sol, 2) >= 1
    @test size(result2.x_sol, 1) == 7
    @test size(result2.bbo_sol, 1) == 13

    println("Number of solutions: ", size(result2.x_sol, 2))
end
