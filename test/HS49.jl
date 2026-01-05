@testset "Constrained linear example 2: HS49" begin

    # blackbox
    function bb(x)
        f = (x[1]- x[2])^2 * (x[3] - 1)^2 + (x[4] - 1)^4 + (x[5] - 1)^5
        bb_outputs = [f]
        success = true
        count_eval = true
        return (success, count_eval, bb_outputs)
    end

    # linear constraints
    A = [1.0 1.0 1.0 4.0 0.0;
         0.0 0.0 1.0 0.0 5.0]
    b = [7.0; 6.0]

    p = NomadProblem(5,  1,  ["OBJ"],  bb,
                     lower_bound = -10.0 * ones(5),
                     upper_bound = 10.0 * ones(5),
                     A = A,  b = b)

    p.options.max_bb_eval = 500
    p.options.linear_converter = "QR"

    x0 = [-9.4062827285902130824979394674301;
          -8.3159368136382827429997632862069;
          7.2648993701161748148820151982363;
          4.3643300430280804746985268138815;
          -0.25297987402323496297640303964727]

    result = solve(p, x0)

    # solve problem
    @test length(result.x_sol) == 5
    @test result.bbo_sol !== nothing
    @test result.feasible == true
    @test result.status == 1
    @test A * result.x_sol ≈ b
    @test all(-10.0 .<= result.x_sol .<= 10.0)

end
