@testset "Constrained linear example 1: HS48" begin

    # blackbox
    function bb(x)
        f = (x[1]- 1)^2 * (x[2] - x[3])^2 + (x[4] - x[5])^2
        bb_outputs = [f]
        success = true
        count_eval = true
        return (success, count_eval, bb_outputs)
    end

    # linear constraints
    A = [1.0 1.0 1.0 1.0 1.0;
         0.0 0.0 1.0 -2.0 -2.0]
    b = [5.0; -3.0]

    p = NomadProblem(5, 1, ["OBJ"], bb,
                     lower_bound = -10.0 * ones(5),
                     upper_bound = 10.0 * ones(5),
                     A = A, b = b)

    p.options.max_bb_eval = 500

    x0 = [0.57186958424864897665429452899843;
          4.9971472653643420613889247761108;
          -1.3793445664086618762667058035731;
          1.0403394252630473459930726676248;
          -0.2300117084673765077695861691609]

    result = solve(p, x0)

    # solve problem
    @test length(result.x_sol) == 5
    @test result.bbo_sol !== nothing
    @test result.feasible == true
    @test result.status == 1
    @test A * result.x_sol ≈ b
    @test all(-10.0 .<= result.x_sol .<= 10.0)

end
