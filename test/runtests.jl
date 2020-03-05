using NOMAD, Test

@testset "C API : creation of a Nomad Problem" begin

    function simpletest(x, outputs)
        for i in length(x)
            outputs[i] = x[i]
        end
        return true
    end

    n = 0
    m = 1
    outputs_types = ["OBJ"]
    max_bb_eval = 1
    @test_throws(AssertionError, createNomadProblem(n, m, simpletest, outputs_types, max_bb_eval))

    n = 1
    m = 0
    outputs_types = String[]
    max_bb_eval = 1
    @test_throws(AssertionError, createNomadProblem(n, m, simpletest, outputs_types, max_bb_eval))

    n = 1
    m = 1
    outputs_types = ["OBJ", "PB"]
    max_bb_eval = 1
    @test_throws(AssertionError, createNomadProblem(n, m, simpletest, outputs_types, max_bb_eval))

    n = 1
    m = 1
    outputs_types = ["WRONG"]
    max_bb_eval = 1
    @test_throws(AssertionError, createNomadProblem(n, m, simpletest, outputs_types, max_bb_eval))


    n = 1
    m = 1
    outputs_types = ["OBJ"]
    max_bb_eval = 0
    @test_throws(AssertionError, createNomadProblem(n, m, simpletest, outputs_types, max_bb_eval))

    n = 1
    m = 1
    outputs_types = ["OBJ"]
    max_bb_eval = 1
    @test_throws(AssertionError, createNomadProblem(n, m, simpletest, outputs_types, max_bb_eval,
                                                    x_lb=[3.0;4.0]))

    n = 1
    m = 1
    outputs_types = ["OBJ"]
    max_bb_eval = 1
    @test_throws(AssertionError, createNomadProblem(n, m, simpletest, outputs_types, max_bb_eval,
                                                    x_ub=[3.0;4.0]))

     n = 1
     m = 1
     outputs_types = ["OBJ"]
     max_bb_eval = 1
     createNomadProblem(n, m, simpletest, outputs_types, max_bb_eval, x_ub=[1.0])
     @test true == true

end

@testset "C API: Simple problem" begin

    function bbtest(x, outputs)
        n = length(x)
        f = sum(x.^2)
        outputs[1] = f
        return true
    end

    # creation of the problem
    test_prob = createNomadProblem(4, 1, bbtest, ["OBJ"], 100,
                                   x_lb = -5.0 * ones(4),
                                   x_ub = 5.0 * ones(4))

    # choose starting point
    test_prob.x0 = [0.71; 0.43; -0.31; 4.2]

    # run the problem and get solutions
    result = solveProblem(test_prob)
    println(result)

    @test true == true

end

@testset "C API : More sophisticated example" begin

    function bbexpert(x, outputs)
        n = length(x)
        sum1 = sum(cos.(x).^4)
        sum2 = sum(x)
        sum3 = (1:n) .* x
        prod1 = prod(cos.(x).^2)
        prod2 = prod(x)
        g1 = -prod2 + 0.75
        g2 = sum2 - 7.5 * n
        f = 10 * g1 + 10 * g2
        if (sum3 ≠ 0.0)
            f -= abs((sum1 - 2 * prod1) / sqrt(3))
        end

        # scaling
        f *= 10^(-5)
        c2000 = -f -2000
        outputs[1] = g1
        outputs[2] = g2
        outputs[3] = f
        outputs[4] = c2000

        return false

    end

    # creation of the problem
    test_prob = createNomadProblem(10, 4, bbexpert, ["PB"; "PB"; "OBJ"; "EB"], 4000)

    # choose starting point
    test_prob.x0 = 7.0 * ones(10)

    # run the problem and get solutions
    result = solveProblem(test_prob)
    println(result)

    @test true == true
end
