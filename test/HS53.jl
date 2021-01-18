@testset "Constrained linear example 4: HS53" begin

    # blackbox
    function bb(x)
        f = (x[1] - x[2])^2 + (x[2] + x[3] - 2)^2 + (x[4] - 1)^2 + (x[5] - 1)^2
        bb_outputs = [f]
        success = true
        count_eval = true
        return (success, count_eval, bb_outputs)
    end

    # linear constraints
    A = [1.0 3.0 0.0 0.0 0.0;
         0.0 0.0 1.0 1.0 -2.0;
         0.0 1.0 0.0 0.0 -1.0]
    b = [0.0; 0.0; 0.0]

    p = NomadProblem(5, 1, ["OBJ"], bb,
                     lower_bound = -10.0 * ones(5),
                     upper_bound = 10.0 * ones(5),
                     A = A, b = b)

    p.options.max_bb_eval = 500
    p.options.linear_converter = "QR"
    p.options.linear_constraints_atol=1e-10

    x0 = [-0.33448399215588553445854813617188;
          0.11149466405196184481951604539063;
          5.8168201231494105485353429685347;
          -5.5938307950454859707178911776282;
          0.11149466405196228890872589545324]

    result = solve(p, x0)

    # solve problem
    @test length(result.x_best_feas) == 5
    @test result.x_best_inf == nothing
    @test isapprox(A * result.x_best_feas, b, atol=1e-13)
    @test all(-10.0 .<= result.x_best_feas .<= 10.0)

end
