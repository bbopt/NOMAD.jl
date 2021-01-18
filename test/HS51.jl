@testset "Constrained linear example 3: HS51" begin

    # blackbox
    function bb(x)
        f = (x[1] - x[2])^2 + (x[2] + x[3] - 2)^2 + (x[1] - 1)^2 + (x[5] - 1)^2
        bb_outputs = [f]
        success = true
        count_eval = true
        return (success, count_eval, bb_outputs)
    end

    # linear constraints
    A = [1.0 3.0 0.0 0.0 0.0;
         0.0 0.0 1.0 1.0 -2.0;
         0.0 1.0 0.0 0.0 -1.0]
    b = [4.0; 0.0; 0.0]

    p = NomadProblem(5, 1, ["OBJ"], bb,
                     lower_bound = -10.0 * ones(5),
                     upper_bound = 10.0 * ones(5),
                     A = A, b = b)

    p.options.max_bb_eval = 500

    x0 = [-4.9922003366305780502898414852098;
          2.9974001122101929794894203951117;
          5.9948002244203859589788407902233;
          0;
          2.9974001122101929794894203951117]

    result = solve(p, x0)

    # solve problem
    @test length(result.x_best_feas) == 5
    @test result.x_best_inf == nothing
    @test A * result.x_best_feas ≈ b
    @test all(-10.0 .<= result.x_best_feas .<= 10.0)

end
