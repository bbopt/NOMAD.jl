@testset "Constrained linear example 5: HS112" begin

    # blackbox
    function bb(x)
        constraints = [-6.089; -17.164; -34.054; -5.914; -24.721; -14.986; -24.1; -10.708; -26.662; -22.179]
        f = sum(x .* (constraints + log.(x / sum(x))))
        bb_outputs = [f]
        success = true
        count_eval = true
        return (success, count_eval, bb_outputs)
    end

    A = [1.0 2.0 2.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0;
         0.0 0.0 0.0 1.0 2.0 1.0 1.0 0.0 0.0 0.0;
         0.0 0.0 1.0 0.0 0.0 0.0 1.0 1.0 2.0 1.0]

    # linear constraints
    b = [2.0; 1.0; 1.0]

    p = NomadProblem(10, 1, ["OBJ"], bb,
                     lower_bound = 0.000001 * ones(10),
                     upper_bound = 5.0 * ones(10),
                     A = A, b = b)

    p.options.max_bb_eval = 500
    #p.options.linear_converter = "QR"

    x0 = [0.21996482747095053023045352347253;
          0.49260438004158713098945554520469;
          0.10987650586951810960378850268171;
          0.17033560675785591742581459584471;
          0.24400207944340807086902600531175;
          0.27609597490537468589266723029141;
          0.06556425944995335208798081794157;
          0.37113518334450695812520848448912;
          0.077223312767278576296270387047116;
          0.29897742580146435820154238172108]

    result = solve(p, x0)

    # solve problem
    @test length(result.x_best_feas) == 10
    @test bb(result.x_best_feas)[3] ≈ result.bbo_best_feas
    @test result.x_best_inf === nothing
    @test isapprox(A * result.x_best_feas, b, atol=1e-13)
    @test all(0.000001 .<= result.x_best_feas .<= 5.0)

end
